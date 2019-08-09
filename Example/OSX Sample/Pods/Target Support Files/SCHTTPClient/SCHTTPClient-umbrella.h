#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SCHTTPAccumulator.h"
#import "SCHTTPContentHandler.h"
#import "SCHTTPFileWriter.h"
#import "SCHTTPImageDecoder.h"
#import "SCHTTPSelectiveDiscarder.h"
#import "SCHTTPStreamWriter.h"
#import "SCHTTPToStringConverter.h"
#import "SCJSONParser.h"
#import "SCHTTP.h"
#import "SCHTTPExecutor.h"
#import "SCHTTPRequest+Convenience.h"
#import "SCHTTPRequest.h"
#import "SCHTTPResponse.h"
#import "curl.h"
#import "curlver.h"
#import "easy.h"
#import "mprintf.h"
#import "multi.h"
#import "stdcheaders.h"
#import "system.h"

FOUNDATION_EXPORT double SCHTTPClientVersionNumber;
FOUNDATION_EXPORT const unsigned char SCHTTPClientVersionString[];

