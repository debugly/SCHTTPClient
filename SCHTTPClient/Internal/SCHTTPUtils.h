//
// Copyright 2013 BiasedBit
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

//
//  Created by Bruno de Carvalho - @biasedbit / http://biasedbit.com
//  Copyright (c) 2013 BiasedBit. All rights reserved.
//

#pragma mark - Constants

#define SCHTTPVersion @"0.9.9"



#pragma mark - Error codes

#define SCHTTPErrorCodeCancelled                     1000
#define SCHTTPErrorCodeUploadFileStreamError         1001
#define SCHTTPErrorCodeUploadDataStreamError         1002
#define SCHTTPErrorCodeDownloadCannotWriteToHandler  1003
#define SCHTTPErrorCodeUnnacceptableContentType      1004
#define SCHTTPErrorCodeImageDecodingFailed           1005



#pragma mark - Logging

#define SCHTTPLogLevelOff   0
#define SCHTTPLogLevelError 1
#define SCHTTPLogLevelWarn  2
#define SCHTTPLogLevelInfo  3
#define SCHTTPLogLevelDebug 4
#define SCHTTPLogLevelTrace 5

extern NSUInteger SCHTTPLogLevel;

extern void SCHTTPLog(NSUInteger level, NSString* prefix, NSString* (^statement)(void));

#define SCHTTPLogError(fmt, ...)  SCHTTPLog(1, @"ERROR", ^{ return [NSString stringWithFormat:fmt, ##__VA_ARGS__]; });
#define SCHTTPLogWarn(fmt, ...)   SCHTTPLog(2, @" WARN", ^{ return [NSString stringWithFormat:fmt, ##__VA_ARGS__]; });
#define SCHTTPLogInfo(fmt, ...)   SCHTTPLog(3, @" INFO", ^{ return [NSString stringWithFormat:fmt, ##__VA_ARGS__]; });
#define SCHTTPLogDebug(fmt, ...)  SCHTTPLog(4, @"DEBUG", ^{ return [NSString stringWithFormat:fmt, ##__VA_ARGS__]; });
#define SCHTTPLogTrace(fmt, ...)  SCHTTPLog(5, @"TRACE", ^{ return [NSString stringWithFormat:fmt, ##__VA_ARGS__]; });
#define SCHTTPCurlDebug(fmt, ...) SCHTTPLog(1, @" CURL", ^{ return [NSString stringWithFormat:fmt, ##__VA_ARGS__]; });



#pragma mark - DRY macros

#define SCHTTPErrorWithFormat(c, fmt, ...) \
    [NSError errorWithDomain:@"com.biasedbit.http" code:c \
                    userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:fmt, ##__VA_ARGS__]}]

// We need this variant because passing a non-statically initialized NSString* instance as fmt raises a warning
#define SCHTTPError(c, description) \
    [NSError errorWithDomain:@"com.biasedbit.http" code:c \
                    userInfo:@{NSLocalizedDescriptionKey: description}]

#define SCHTTPErrorWithReason(c, description, reason) \
    [NSError errorWithDomain:@"com.biasedbit.http" code:c \
                    userInfo:@{NSLocalizedDescriptionKey: description, NSLocalizedFailureReasonErrorKey: reason}]

#define SCHTTPEnsureNotNil(value) NSAssert((value) != nil, @"%s cannot be nil", #value)

#define SCHTTPEnsureSuccessOrReturn0(condition) do { if (!(condition)) return 0; } while(0)

#define SCHTTPSingleton(class, name, value) \
    static class* name = nil; \
    if (name == nil) { \
        static dispatch_once_t name ## _token; \
        dispatch_once(&name##_token, ^{ name = value; }); \
    }

#define SCHTTPSingletonString(name, fmt, ...) \
    static NSString* name = nil; \
    if (name == nil) { \
        static dispatch_once_t name ## _token; \
        dispatch_once(&name##_token, ^{ name = [NSString stringWithFormat:fmt, ##__VA_ARGS__]; }); \
    }

#define SCHTTPSingletonBlock(class, name, block) \
    static class* name = nil; \
    if (name == nil) { \
        static dispatch_once_t name ## _token; \
        dispatch_once(&name##_token, block); \
    }

#define SCHTTPDefineHeaderName(name, override) static NSString* const SCHTTPHeaderName_##name = (override);
#define SCHTTPDefineHeaderValue(value, override) static NSString* const SCHTTPHeaderValue_##value = (override);
#define H(name) SCHTTPHeaderName_##name
#define HV(value) SCHTTPHeaderValue_##value



#pragma mark - Headers names

SCHTTPDefineHeaderName(Host,              @"Host") // Will create SCHTTPHeaderName_Host
SCHTTPDefineHeaderName(UserAgent,         @"User-Agent")
SCHTTPDefineHeaderName(ContentType,       @"Content-Type")
SCHTTPDefineHeaderName(ContentLength,     @"Content-Length")
SCHTTPDefineHeaderName(Accept,            @"Accept")
SCHTTPDefineHeaderName(AcceptLanguage,    @"Accept-Language")
SCHTTPDefineHeaderName(Expect,            @"Expect")
SCHTTPDefineHeaderName(TransferEncoding,  @"Transfer-Encoding")
SCHTTPDefineHeaderName(Date,              @"Date")
SCHTTPDefineHeaderName(Authorization,     @"Authorization")



#pragma mark - Header values

SCHTTPDefineHeaderValue(100Continue,   @"100-Continue") // Will create SCHTTPHeaderValue_100Continue
SCHTTPDefineHeaderValue(Chunked,       @"chunked")



#pragma mark - Utility functions

extern NSString* SCHTTPMimeType(NSString* file);
extern long long SCHTTPCurrentTimeMillis(void);
extern NSString* SCHTTPURLEncode(NSString* string, NSStringEncoding encoding);
