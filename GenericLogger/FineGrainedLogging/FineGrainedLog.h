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

#import <CocoaLumberjack/CocoaLumberjack.h>

// The first 4 bits are being used by the standard levels (0 - 3) 
// All other bits are fair game for us to use.

#define LOG_FLAG_METRICS  (1 << 4)  // 0...0010000
#define LOG_FLAG_AUDIO    (1 << 5)  // 0...0100000
#define LOG_FLAG_VIDEO    (1 << 6)  // 0...1000000

// AND SO ON SO FORTH
#define LOG_AUDIO  (ddLogLevel & LOG_FLAG_AUDIO)
#define LOG_VIDEO (ddLogLevel & LOG_FLAG_VIDEO)
#define LOG_METRICS  (ddLogLevel & LOG_FLAG_METRICS)

#define DDLogAudio(frmt, ...)   ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_AUDIO,  0, frmt, ##__VA_ARGS__)
#define DDLogVideo(frmt, ...)  ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_VIDEO, 0, frmt, ##__VA_ARGS__)
#define DDLogMetrics(frmt, ...)   ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_METRICS,  0, frmt, ##__VA_ARGS__)

// Now we decide which flags we want to enable in our application

#define LOG_FLAG_ALL_COMPONENTS (LOG_FLAG_AUDIO | LOG_FLAG_VIDEO | LOG_FLAG_METRICS)
