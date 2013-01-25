/*
 Copyright (c) 2011, Research2Development Inc..
 All rights reserved.
 Part of "Open Source" initiative from Research2Development Inc..
 
 Redistribution and use in source or in binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 Redistributions in source or binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 Neither the name of the Research2Development. nor the names of its contributors may be
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
#import "HTTPMessage.h"


@implementation HTTPMessage

- (id)initEmptyRequest
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateEmpty(NULL, YES);
	}
	return self;
}

- (id)initRequestWithMethod:(NSString *)method URL:(NSURL *)url version:(NSString *)version
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateRequest(NULL, (CFStringRef)method, (CFURLRef)url, (CFStringRef)version);
	}
	return self;
}

- (id)initResponseWithStatusCode:(NSInteger)code description:(NSString *)description version:(NSString *)version
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateResponse(NULL, (CFIndex)code, (CFStringRef)description, (CFStringRef)version);
	}
	return self;
}

- (void)dealloc
{
	if (message)
	{
		CFRelease(message);
	}
	[super dealloc];
}

- (BOOL)appendData:(NSData *)data
{
	return CFHTTPMessageAppendBytes(message, [data bytes], [data length]);
}

- (BOOL)isHeaderComplete
{
	return CFHTTPMessageIsHeaderComplete(message);
}

- (NSString *)version
{
	return [NSMakeCollectable(CFHTTPMessageCopyVersion(message)) autorelease];
}

- (NSString *)method
{
	return [NSMakeCollectable(CFHTTPMessageCopyRequestMethod(message)) autorelease];
}

- (NSURL *)url
{
	return [NSMakeCollectable(CFHTTPMessageCopyRequestURL(message)) autorelease];
}

- (NSInteger)statusCode
{
	return (NSInteger)CFHTTPMessageGetResponseStatusCode(message);
}

- (NSDictionary *)allHeaderFields
{
	return [NSMakeCollectable(CFHTTPMessageCopyAllHeaderFields(message)) autorelease];
}

- (NSString *)headerField:(NSString *)headerField
{
	return [NSMakeCollectable(CFHTTPMessageCopyHeaderFieldValue(message, (CFStringRef)headerField)) autorelease];
}

- (void)setHeaderField:(NSString *)headerField value:(NSString *)headerFieldValue
{
	CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef)headerField, (CFStringRef)headerFieldValue);
}

- (NSData *)messageData
{
	return [NSMakeCollectable(CFHTTPMessageCopySerializedMessage(message)) autorelease];
}

- (NSData *)body
{
	return [NSMakeCollectable(CFHTTPMessageCopyBody(message)) autorelease];
}

- (void)setBody:(NSData *)body
{
	CFHTTPMessageSetBody(message, (CFDataRef)body);
}

@end
