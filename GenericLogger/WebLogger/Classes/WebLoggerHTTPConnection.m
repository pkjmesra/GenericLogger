/*
 Copyright (c) 2011, Praveen K Jha..
 All rights reserved.
 Part of "Open Source" initiative from Praveen K Jha..

 Redistribution and use in source or in binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 Redistributions in source or binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 Neither the name of the Praveen K Jha. nor the names of its contributors may be
 used to endorse or promote products derived from this software without specific
 prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 OF THE POSSIBILITY OF SUCH DAMAGE."
 */
#import "WebLoggerHTTPConnection.h"
#import "WebSocketLogger.h"

#import <UIKit/UIKit.h>

@implementation WebLoggerHTTPConnection

@synthesize logFileManager;
@synthesize fileLogger;
@synthesize connection=_connection;
@synthesize response=_response;

-(id <DDLogFileManager>) getLoggerManager
{
    if (self.logFileManager == nil)
    {
		// Check if the UIApplicationDelegate has a fileLogger
		if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(fileLogger)])
		{
            DDFileLogger *logger = [[[UIApplication sharedApplication] delegate] performSelector:@selector(fileLogger)];
			return [logger logFileManager];
		}
		else
		{
			// Direct log messages to the console.
			// The log messages will look exactly like a normal NSLog statement.
			// 
			// This is something we may not want to do in a shipping version of the application.
			
			//	[DDLog addLogger:[DDASLLogger sharedInstance]];
			[DDLog addLogger:[DDTTYLogger sharedInstance]];
			
			// We also want to direct our log messages to a file.
			// So we're going to setup file logging.
			// 
			// We start by creating a file logger.
			
			fileLogger = [[DDFileLogger alloc] init];
			
			// Configure some sensible defaults for an iPhone application.
			// 
			// Roll the file when it gets to be 512 KB or 24 Hours old (whichever comes first).
			// 
			// Also, only keep up to 4 archived log files around at any given time.
			// We don't want to take up too much disk space.
			
			fileLogger.maximumFileSize = 1024 * 512;    // 512 KB
			fileLogger.rollingFrequency = 60 * 60 * 24; //  24 Hours
			
			fileLogger.logFileManager.maximumNumberOfLogFiles = 20;
			
			// Add our file logger to the logging system.
			
			[DDLog addLogger:fileLogger];
			return fileLogger.logFileManager;
		}
    }
    else
    {
        return self.logFileManager;
    }
}

- (NSData *)generateIndexData
{
	NSArray *sortedLogFileInfos = [[self getLoggerManager] sortedLogFileInfos];
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setFormatterBehavior:NSDateFormatterBehavior10_4];
	[df setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
	
	NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
	[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[nf setNumberStyle:NSNumberFormatterDecimalStyle];
	[nf setMinimumFractionDigits:2];
	[nf setMaximumFractionDigits:2];
	
	NSMutableString *response = [NSMutableString stringWithCapacity:1000];
	
	[response appendString:@"<html><head>"];
	[response appendString:@"<style type='text/css'>@import url('styles.css');</style>"];
	[response appendString:@"</head><body>"];
	
	[response appendString:@"<h1>Device Log Files</h1>"];
	
	[response appendString:@"<table cellspacing='2'>"];
	
	for (DDLogFileInfo *logFileInfo in sortedLogFileInfos)
	{
		NSString *fileName = logFileInfo.fileName;
		NSString *fileDate = [df stringFromDate:[logFileInfo creationDate]];
		NSString *fileSize;
		
		unsigned long long sizeInBytes = logFileInfo.fileSize;
		
		double GBs = (double)(sizeInBytes) / (double)(1024 * 1024 * 1024);
		double MBs = (double)(sizeInBytes) / (double)(1024 * 1024);
		double KBs = (double)(sizeInBytes) / (double)(1024);
		
		if(GBs >= 1.0)
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:GBs]];
			fileSize = [NSString stringWithFormat:@"%@ GB", temp];
		}
		else if(MBs >= 1.0)
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:MBs]];
			fileSize = [NSString stringWithFormat:@"%@ MB", temp];
		}
		else
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:KBs]];
			fileSize = [NSString stringWithFormat:@"%@ KB", temp];
		}
		
		NSString *fileLink = [NSString stringWithFormat:@"<a href='/%@'>%@</a>", fileName, fileName];
		
		[response appendFormat:@"<tr><td>%@</td><td>%@</td><td align='right'>%@</td>", fileLink, fileDate, fileSize];
	}
	
	[response appendString:@"</table></body></html>"];
	
	return [response dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)filePathForURI:(NSString *)path
{
	if ([path hasPrefix:@"/logs/"])
	{
		NSString *logsDir = [[self getLoggerManager] logsDirectory];
		return [logsDir stringByAppendingPathComponent:[path lastPathComponent]];
	}
	
	return [super filePathForURI:path];
}

- (NSString *)wsLocation
{
	NSString *port = [NSString stringWithFormat:@"%hu", [asyncSocket localPort]];
	
	NSString *wsLocation;
	NSString *wsHost = [request headerField:@"Host"];
	
	if (wsHost == nil)
	{
		wsLocation = [NSString stringWithFormat:@"ws://localhost:%@/livelog", port];
	}
	else
	{
		wsLocation = [NSString stringWithFormat:@"ws://%@/livelog", wsHost];
	}
	
	return wsLocation;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	if ([path isEqualToString:@"/logs.html"])
	{
		NSData *indexData = [self generateIndexData];
		return [[[HTTPDataResponse alloc] initWithData:indexData] autorelease];
	}
    else if ([path rangeOfString:@".m3u8"].location != NSNotFound ||
             [path rangeOfString:@".ts"].location != NSNotFound)
    {
        NSLog(@"path for request:%@",path);
        
        // trying to download the .m3u8 file or .ts file
        NSURL *multiUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://multi.verizon.com%@", path]];
        NSLog(@"multiUrl:%@",[multiUrl absoluteString]);
        
        NSURLRequest * modRequest =[NSURLRequest requestWithURL:multiUrl
                                                 cachePolicy:NSURLRequestReloadIgnoringCacheData
                                             timeoutInterval:30];
        [[NSThread currentThread] setThreadPriority:1.0];
        NSURLConnection* con = [[NSURLConnection alloc] initWithRequest:modRequest delegate:self startImmediately:NO]; // ivar
        self.connection =con;
        [con release];
        // Here is the trick
        _port = [NSPort port];
        _rl = [NSRunLoop currentRunLoop]; // Get the runloop
        [_rl addPort:_port forMode:NSRunLoopCommonModes];
        [self.connection scheduleInRunLoop:_rl forMode:NSRunLoopCommonModes];
        [self.connection start];
        [_rl run];
        
//        NSData *response = [NSURLConnection sendSynchronousRequest:modRequest returningResponse:&returnResponse error:&error];
//        [[NSThread currentThread] setThreadPriority:0.4];
        if (self.response)
        {
            if ([path hasSuffix:@".ts"])
            {
                return [[[HTTPDataResponse alloc] initWithData:self.response] autorelease];
            }
            else
            {
                // It's an m3u8 file
                NSString * m3u8Content =[[[NSString alloc] initWithData:self.response encoding:NSUTF8StringEncoding] autorelease];
                m3u8Content =[m3u8Content stringByReplacingOccurrencesOfString:@"https" withString:@"vzhttps"];
                NSLog(@"m3u8Content:%@",m3u8Content);
                return [[[HTTPDataResponse alloc] initWithData:[m3u8Content dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
            }
        }
        else
            return nil;

    }
	else if ([path isEqualToString:@"/socket.html"])
	{
		// The socket.html file contains a URL template that needs to be completed:
		// 
		// ws = new WebSocket("%%WEBSOCKET_URL%%");
		// 
		// We need to replace "%%WEBSOCKET_URL%%" with whatever URL the server is running on.
		// We can accomplish this easily with the HTTPDynamicFileResponse class,
		// which takes a dictionary of replacement key-value pairs,
		// and performs replacements on the fly as it uploads the file.
		
		NSString *loc = [self wsLocation];
		NSDictionary *replacementDict = [NSDictionary dictionaryWithObject:loc forKey:@"WEBSOCKET_URL"];
		
		return [[[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
		                                            forConnection:self
		                                                separator:@"%%"
		                                    replacementDictionary:replacementDict] autorelease];
	}
    else if ([path hasPrefix:@"/OneTranOneFeature"])
	{
        NSMutableString *response = [NSMutableString stringWithCapacity:1000];
		NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
		int value = [[path stringByTrimmingCharactersInSet:nonDigits] intValue];
		NSString *tranLevel =nil;
		if (value <0)
		{
			value= 0;
		}
        switch (value) {
            case 0:
                tranLevel = @"0";
                break;
                
            default:
                tranLevel = @"1";
                break;
        }
        NSString *definitions = @"<br /><a href='/OneTranOneFeature=0'>Step by step transaction :0 (Recommended) </a><br /><a href='/OneTranOneFeature=1'> One transaction per feature:1 </a><br />";
		[response appendString:@"<html><head>"];
		[response appendString:@"<style type='text/css'>@import url('styles.css');</style>"];
		[response appendString:@"</head><body><div>"];
		[response appendString: [NSString stringWithFormat:@"The transaction level has been reset to :%@. <br />Following are the definitions:%@",tranLevel,definitions]];
		[response appendString:@"</div></body></html>"];
		NSData *data =[response dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt: value], @"oneTransactionPerFeatureTurnedOn",
								  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"oneTransactionPerFeatureTurnedOn"
															object:nil userInfo:userinfo];
		return [[[HTTPDataResponse alloc] initWithData:data] autorelease];
    }
	else if ([path hasPrefix:@"/loglevel"])
	{
		NSMutableString *response = [NSMutableString stringWithCapacity:1000];
		NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
		int value = [[path stringByTrimmingCharactersInSet:nonDigits] intValue];
		NSString *logLevel =nil;
		if (value <0)
		{
			value= LOG_LEVEL_OFF;
		}
		switch (value) {
			case LOG_LEVEL_OFF:
				logLevel = @"turned off";
				break;
			case LOG_LEVEL_ERROR:
				logLevel = @"Error only";
				break;
			case LOG_LEVEL_WARN:
				logLevel = @"Errors and warnings";
				break;
			case LOG_LEVEL_INFO:
				logLevel = @"Errors, warnings and information";
				break;
			case LOG_LEVEL_VERBOSE:
				logLevel = @"Errors, warnings, information and verbose";
				break;
			default:
				logLevel = @"Custom value with a 'Logical OR' of current log level and that of supplied one";
				break;
		}
		NSString *definitions = @"<br />LOG_LEVEL_OFF :0<br />LOG_LEVEL_ERROR:1 (0...0001)<br />LOG_LEVEL_WARN:3 (0...0011)<br />LOG_LEVEL_INFO:7 (0...0111)<br />LOG_LEVEL_VERBOSE:15 (0...1111)<br />";
		[response appendString:@"<html><head>"];
		[response appendString:@"<style type='text/css'>@import url('styles.css');</style>"];
		[response appendString:@"</head><body><div>"];
		[response appendString: [NSString stringWithFormat:@"The Log level has been reset to :%@. <br />Following are the definitions:%@",logLevel,definitions]];
		[response appendString:@"</div></body></html>"];
		NSData *data =[response dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt: value], @"ddloglevel",
								  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ddloglevel"
															object:nil userInfo:userinfo];
		return [[[HTTPDataResponse alloc] initWithData:data] autorelease];
	}
	else
	{
		return [super httpResponseForMethod:method URI:path];
	}
}

- (WebSocket *)webSocketForURI:(NSString *)path
{
	if ([path isEqualToString:@"/livelog"])
	{
		// Create the WebSocket
		WebSocket *ws = [[WebSocket alloc] initWithRequest:request socket:asyncSocket];
		
		// Create the WebSocketLogger
		WebSocketLogger *wsLogger = [[WebSocketLogger alloc] initWithWebSocket:ws];
		
		// Memory management:
		// The WebSocket will be retained by the HTTPServer and the WebSocketLogger.
		// The WebSocketLogger will be retained by the logging framework,
		// as it adds itself to the list of active loggers from within its init method.
		
		[wsLogger release];
		return [ws autorelease];
	}
	
	return [super webSocketForURI:path];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

    
    if([(NSHTTPURLResponse *)response statusCode] != 200)
    {
        [_rl removePort:_port forMode:NSRunLoopCommonModes];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    if (!self.response)
    {
        NSMutableData* r = [[NSMutableData alloc] init];
        self.response =r;
        [r release];
    }
    [self.response appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Error:%@",[error localizedDescription]);
     [_rl removePort:_port forMode:NSDefaultRunLoopMode];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [_rl removePort:_port forMode:NSRunLoopCommonModes];
}
@end