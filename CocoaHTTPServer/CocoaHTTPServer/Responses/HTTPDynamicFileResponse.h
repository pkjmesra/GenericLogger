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
#import <Foundation/Foundation.h>
#import "HTTPResponse.h"
#import "HTTPAsyncFileResponse.h"

/**
 * This class is designed to assist with dynamic content.
 * Imagine you have a file that you want to make dynamic:
 * 
 * <html>
 * <body>
 *   <h1>ComputerName Control Panel</h1>
 *   ...
 *   <li>System Time: SysTime</li>
 * </body>
 * </html>
 * 
 * Now you could generate the entire file in Objective-C,
 * but this would be a horribly tedious process.
 * Beside, you want to design the file with professional tools to make it look pretty.
 * 
 * So all you have to do is escape your dynamic content like this:
 * 
 * ...
 *   <h1>%%ComputerName%% Control Panel</h1>
 * ...
 *   <li>System Time: %%SysTime%%</li>
 * 
 * And then you create an instance of this class with:
 * 
 * - separator = @"%%"
 * - replacementDictionary = { "ComputerName"="Black MacBook", "SysTime"="2010-04-30 03:18:24" }
 * 
 * This class will then perform the replacements for you, on the fly, as it reads the file data.
 * This class is also asynchronous, so it will perform the file IO using its own GCD queue.
 * 
 * All keys for the replacementDictionary must be NSString's.
 * Values for the replacementDictionary may be NSString's, or any object that
 * returns what you want when its description method is invoked.
**/

@interface HTTPDynamicFileResponse : HTTPAsyncFileResponse
{
	NSData *separator;
	NSDictionary *replacementDict;
}

- (id)initWithFilePath:(NSString *)filePath
         forConnection:(HTTPConnection *)connection
             separator:(NSString *)separatorStr
 replacementDictionary:(NSDictionary *)dictionary;

@end
