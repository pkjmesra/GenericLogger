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
/**
 * DDRange is the functional equivalent of a 64 bit NSRange.
 * The HTTP Server is designed to support very large files.
 * On 32 bit architectures (ppc, i386) NSRange uses unsigned 32 bit integers.
 * This only supports a range of up to 4 gigabytes.
 * By defining our own variant, we can support a range up to 16 exabytes.
 * 
 * All effort is given such that DDRange functions EXACTLY the same as NSRange.
**/

#import <Foundation/NSValue.h>
#import <Foundation/NSObjCRuntime.h>

@class NSString;

typedef struct _DDRange {
    UInt64 location;
    UInt64 length;
} DDRange;

typedef DDRange *DDRangePointer;

NS_INLINE DDRange DDMakeRange(UInt64 loc, UInt64 len) {
    DDRange r;
    r.location = loc;
    r.length = len;
    return r;
}

NS_INLINE UInt64 DDMaxRange(DDRange range) {
    return (range.location + range.length);
}

NS_INLINE BOOL DDLocationInRange(UInt64 loc, DDRange range) {
    return (loc - range.location < range.length);
}

NS_INLINE BOOL DDEqualRanges(DDRange range1, DDRange range2) {
    return ((range1.location == range2.location) && (range1.length == range2.length));
}

FOUNDATION_EXPORT DDRange DDUnionRange(DDRange range1, DDRange range2);
FOUNDATION_EXPORT DDRange DDIntersectionRange(DDRange range1, DDRange range2);
FOUNDATION_EXPORT NSString *DDStringFromRange(DDRange range);
FOUNDATION_EXPORT DDRange DDRangeFromString(NSString *aString);

NSInteger DDRangeCompare(DDRangePointer pDDRange1, DDRangePointer pDDRange2);

@interface NSValue (NSValueDDRangeExtensions)

+ (NSValue *)valueWithDDRange:(DDRange)range;
- (DDRange)ddrangeValue;

- (NSInteger)ddrangeCompare:(NSValue *)ddrangeValue;

@end
