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
#import "WebSocketLogger.h"


@implementation WebSocketLogger

- (id)initWithWebSocket:(WebSocket *)ws
{
	if ((self = [super init]))
	{
		websocket = [ws retain];
		websocket.delegate = self;
		
		formatter = [[WebSocketFormatter alloc] init];
		
		// Add our logger
		// 
		// We do this here (as opposed to in webSocketDidOpen:) so the logging framework will retain us.
		// This is important as nothing else is retaining us.
		// It may be a bit hackish, but it's also the simplest solution.
		[DDLog addLogger:self];
	}
	return self;
}

- (void)dealloc
{
	[websocket setDelegate:nil];
	[websocket release];
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark WebSocket delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)webSocketDidOpen:(WebSocket *)ws
{
	// This method is invoked on the websocketQueue
	
	isWebSocketOpen = YES;
}

- (void)webSocketDidClose:(WebSocket *)ws
{
	// This method is invoked on the websocketQueue
	
	isWebSocketOpen = NO;
	
	// Remove our logger
	[DDLog removeLogger:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogger Protocol
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)logMessage:(DDLogMessage *)logMessage
{
	if (logMessage->logContext == HTTP_LOG_CONTEXT)
	{
		// Don't relay HTTP log messages.
		// Doing so could essentially cause an endless loop of log messages.
		
		return;
	}
	
	NSString *logMsg = logMessage->logMsg;
	
	if (formatter)
    {
        logMsg = [formatter formatLogMessage:logMessage];
    }
    
	if (logMsg)
	{
		dispatch_async(websocket.websocketQueue, ^{
			
			if (isWebSocketOpen)
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[websocket sendMessage:logMsg];
				
				[pool release];
			}
		});
	}
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation WebSocketFormatter

- (id)init
{
	if((self = [super init]))
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
	}
	return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
	NSString *dateAndTime = [dateFormatter stringFromDate:(logMessage->timestamp)];
	
	NSMutableString *webMsg = [[logMessage->logMsg mutableCopy] autorelease];
	
	[webMsg replaceOccurrencesOfString:@"<"  withString:@"&lt;"  options:0 range:NSMakeRange(0, [webMsg length])];
	[webMsg replaceOccurrencesOfString:@">"  withString:@"&gt;"  options:0 range:NSMakeRange(0, [webMsg length])];
	[webMsg replaceOccurrencesOfString:@"\n" withString:@"<br/>" options:0 range:NSMakeRange(0, [webMsg length])];
	
	return [NSString stringWithFormat:@"%@ &nbsp;%@", dateAndTime, webMsg];
}

- (void)dealloc
{
	[dateFormatter release];
	[super dealloc];
}

@end
