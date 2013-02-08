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
#import "HTTPDataResponse.h"
#import "HTTPLogging.h"

// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_OFF; // | HTTP_LOG_FLAG_TRACE;


@implementation HTTPDataResponse

- (id)initWithData:(NSData *)dataParam
{
	if((self = [super init]))
	{
		HTTPLogTrace();
		
		offset = 0;
		data = [dataParam retain];
	}
	return self;
}

- (void)dealloc
{
	HTTPLogTrace();
	
	[data release];
	[super dealloc];
}

- (UInt64)contentLength
{
	UInt64 result = (UInt64)[data length];
	
	HTTPLogTrace2(@"%@[%p]: contentLength - %llu", THIS_FILE, self, result);
	
	return result;
}

- (UInt64)offset
{
	HTTPLogTrace();
	
	return offset;
}

- (void)setOffset:(UInt64)offsetParam
{
	HTTPLogTrace2(@"%@[%p]: setOffset:%llu", THIS_FILE, self, offset);
	
	offset = (NSUInteger)offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter
{
	HTTPLogTrace2(@"%@[%p]: readDataOfLength:%lu", THIS_FILE, self, (unsigned long)lengthParameter);
	
	NSUInteger remaining = [data length] - offset;
	NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;
	
	void *bytes = (void *)([data bytes] + offset);
	
	offset += length;
	
	return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone
{
	BOOL result = (offset == [data length]);
	
	HTTPLogTrace2(@"%@[%p]: isDone - %@", THIS_FILE, self, (result ? @"YES" : @"NO"));
	
	return result;
}

@end
