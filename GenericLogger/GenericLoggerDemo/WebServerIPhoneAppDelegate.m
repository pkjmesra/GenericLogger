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
#import "WebServerIPhoneAppDelegate.h"
#import "WebServerIPhoneViewController.h"

#import <GenericLoggerFramework/GenericLoggerFramework.h>
#import <CocoaHTTPServer/CocoaHTTPServer.h>
#import <CocoaLumberjack/CocoaLumberjack.h>


// Log levels: off, error, warn, info, verbose
//static const int ddLogLevel = LOG_LEVEL_VERBOSE | LOG_FLAG_ALL_COMPONENTS;
int ddLogLevel;

@interface WebServerIPhoneAppDelegate (Private)
/**
 Resets the ddloglevel to the desired value as received in notification
 */
-(void)reSetDDLogLevel:(NSNotification *)notification;
-(void)setupLogger;
/**
 *This is required if you want to set up live logging via an http server
 */
- (void)setupWebServer;
-(void)commonInit;
@end

@implementation WebServerIPhoneAppDelegate

@synthesize fileLogger;

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{	
	// Set it globally
	ddLogLevel = LOG_LEVEL_VERBOSE | LOG_FLAG_ALL_COMPONENTS;
	// Now setup our web server:Optional
	// 
	// This will allow us to connect to the device from our web browser.
	// We can then view log files, or view logging in real time as the application runs.
	
	    [self commonInit];
	/*
    */
    
	// This application, by itself, doesn't actually do anthing.
	// It is just a proof of concept or demonstration.
	// But we want to be able to see the application logging something.
	// So we setup a timer to spit out a silly log message.
	
	[NSTimer scheduledTimerWithTimeInterval:1.0
	                                 target:self
	                               selector:@selector(writeLogMessages:)
	                               userInfo:nil
	                                repeats:YES];
	
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    if ([httpServer isRunning])
    {
        [httpServer stop];
    }
    DDLogInfo(@"####################################################################################################\n\n\n");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    DDLogInfo(@"####################################################################################################\n\n\n");
    // Start the server (and check for problems)
	
	NSError *error = nil;
    if (httpServer)
    {
        if (![httpServer start:&error])
        {
            DDLogError(@"Error starting HTTP Server: %@", error);
        }
    }
}

#pragma mark -
#pragma mark Common initialization part
-(void)commonInit
{
    
    // Start the generic logger
	[self setupLogger];
    
	// Now setup our web server:Optional
	// 
	// This will allow us to connect to the device from our web browser.
	// We can then view log files, or view logging in real time as the application runs.
	
	[self setupWebServer];
}


/**
 *This is required if you want to set up live logging via an http server
 */
- (void)setupWebServer
{
	// Create server using our custom MyHTTPServer class
	httpServer = [[HTTPServer alloc] init];
	
	// Configure it to use our connection class
	[httpServer setConnectionClass:[WebLoggerHTTPConnection class]];
	// Set the bonjour type of the http server.
	// This allows the server to broadcast itself via bonjour.
	// You can automatically discover the service in Safari's bonjour bookmarks section.
	[httpServer setType:@"_http._tcp."];
	
	// Normally there is no need to run our server on any specific port.
	// Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
	// However, for testing purposes, it may be much easier if the port doesn't change on every build-and-go.
	[httpServer setPort:12345];
    DDLogInfo(@"Web server for logger is setup on port:%d", [httpServer port]);
	// Copy the file from main bundle to the documents directory
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory,
														 NSUserDomainMask, YES);
	NSString *cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"logs"];

    [fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	NSString *indexFile = [[[[self class] frameworkBundle] resourcePath]
						   stringByAppendingPathComponent:@"indexlog.html"];
	NSString *jsFile = [[[[self class] frameworkBundle] resourcePath]
						stringByAppendingPathComponent:@"jquery-1.4.2.min.js"];
	NSString *socketFile = [[[[self class] frameworkBundle] resourcePath]
							stringByAppendingPathComponent:@"socket.html"];
	NSString *cssFile = [[[[self class] frameworkBundle] resourcePath]
						 stringByAppendingPathComponent:@"styles.css"];
	[fileManager copyItemAtPath:indexFile toPath:[cacheDirectory stringByAppendingPathComponent:@"indexlog.html"] error:&error];
	[fileManager copyItemAtPath:jsFile toPath:[cacheDirectory stringByAppendingPathComponent:@"jquery-1.4.2.min.js"] error:&error];
	[fileManager copyItemAtPath:socketFile toPath:[cacheDirectory stringByAppendingPathComponent:@"socket.html"] error:&error];
	[fileManager copyItemAtPath:cssFile toPath:[cacheDirectory stringByAppendingPathComponent:@"styles.css"] error:&error];
	// Serve files from our embedded Web folder

	[httpServer setDocumentRoot:cacheDirectory];
	
	// Start the server (and check for problems)
	
	error = nil;
	if (![httpServer start:&error])
	{
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
}

-(void)setupLogger
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(reSetDDLogLevel:) 
												 name:@"ddloglevel"
											   object:nil];
	id savedValue = [[NSUserDefaults standardUserDefaults] valueForKey:@"ddloglevel"];
	
	if (savedValue !=nil)
	{
		// Reset with the previously saved value
		ddLogLevel = [savedValue intValue];
	}
	else
	{
		// Set it globally to informational level
		ddLogLevel = LOG_LEVEL_INFO;
	}
    DDLogInfo(@"Log level set to:%d", ddLogLevel);
    // Now setup custom formatting of messaging : Optional
    CustomLogFormatter *formatter = [[CustomLogFormatter alloc] init];
	
	[[DDASLLogger sharedInstance] setLogFormatter:formatter];
	[[DDTTYLogger sharedInstance] setLogFormatter:formatter];
	[formatter release];
    
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    // You could also use a file logger with a 
    // default filelogger
    /*
     // We also want to direct our log messages to a file.
     // So we're going to setup file logging.
     // 
     // We start by creating a file logger.
     */
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
	DDLogVerbose(@"Successfully started the logger with ddloglevel :%d, maximumFileSize:%d, rollingFrequency :%l, maximumNumberOfLogFiles:%d",ddLogLevel, fileLogger.maximumFileSize,fileLogger.rollingFrequency,fileLogger.logFileManager.maximumNumberOfLogFiles);
    
    // DEVNOTE: Notify in log if user/QA is using the debug build. Debug build is
    // supposed to be used only by developers
#if DEBUG
    DDLogInfo(@"#################################################################");
    DDLogInfo(@"# THIS IS A DEBUG BUILD! PLEASE TAKE THE LATEST RELEASE BUILD!  #");
    DDLogInfo(@"#################################################################");
#endif
    DDLogInfo(@"\nApplication Bundle version:%@\nApplication short bundle version:%@\nApplication build date:%@\n",
              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"BuildDate"]);
}

/**
 Resets the ddloglevel to the desired value as received in notification
 */
-(void)reSetDDLogLevel:(NSNotification *)notification
{
	NSDictionary *userInfo = (NSDictionary *)[notification userInfo];
	int value = [[userInfo objectForKey: @"ddloglevel"] intValue];
	switch (value) {
		case LOG_LEVEL_OFF:
			ddLogLevel = LOG_LEVEL_OFF;
			break;
		case LOG_LEVEL_ERROR:
			ddLogLevel = LOG_LEVEL_ERROR;
			break;
		case LOG_LEVEL_WARN:
			ddLogLevel = LOG_LEVEL_WARN;
			break;
		case LOG_LEVEL_INFO:
			ddLogLevel = LOG_LEVEL_INFO;
			break;
		case LOG_LEVEL_VERBOSE:
			ddLogLevel = LOG_LEVEL_VERBOSE;
			break;
		default:
			ddLogLevel = ddLogLevel | value;
			break;
	}
	NSNumber *logLevel = [NSNumber numberWithInt:ddLogLevel];
	[[NSUserDefaults standardUserDefaults] setObject:logLevel forKey:@"ddloglevel"];
    
    DDLogInfo(@"Log level reset to:%d", ddLogLevel);
}

- (void)writeLogMessages:(NSTimer *)aTimer
{
	// Log a message in verbose mode.
	// 
	// Want to disable this log message?
	// Try setting the log level (at the top of this file) to LOG_LEVEL_WARN.
	// After doing this you can leave the log statement below.
	// It will automatically be compiled out (when compiling in release mode where compiler optimizations are enabled).
	
	DDLogVerbose(@"Your objc verbose log messages go here");
    DDLogError(@"Your objc error log messages go here");
    DDLogWarn(@"Your objc warning log messages go here");
    DDLogInfo(@"Your objc info log messages go here");
    
    DDLogCError(@"Your C error log messages go here");
    DDLogCWarn(@"Your C warning log messages go here");
    DDLogCInfo(@"Your C info log messages go here");
    DDLogCVerbose(@"Your C verbose log messages go here");
    
    DDLogAudio(@"Low audio volume");
    DDLogVideo(@"Switching to Video scale 0.3");
}

// Load the framework bundle.
+ (NSBundle *)frameworkBundle
{
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"GenericLoggerFramework.bundle"];
        frameworkBundle = [[NSBundle bundleWithPath:frameworkBundlePath] retain];
        [frameworkBundle load]; // you should call this if this is the first time you are doing this
    });
    return frameworkBundle;
}

@end
