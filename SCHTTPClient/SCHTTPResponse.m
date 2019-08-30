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

#import "SCHTTPResponse.h"



#pragma mark - Utility functions

NSString* NSStringFromBBHTTPProtocolVersion(SCHTTPProtocolVersion version)
{
    switch (version) {
        case SCHTTPProtocolVersion_None:
        {
            assert(false);
            return @"";
        }
        case SCHTTPProtocolVersion_1_0:
            return @"HTTP/1.0";
        case SCHTTPProtocolVersion_1_1:
            return @"HTTP/1.1";
        case SCHTTPProtocolVersion_2_0:
            return @"HTTP/2";
    }
}

SCHTTPProtocolVersion SCHTTPProtocolVersionFromNSString(NSString* string)
{
    if ([string isEqualToString:@"HTTP/2"]) {
        return SCHTTPProtocolVersion_2_0;
    } else if ([string isEqualToString:@"HTTP/1.1"]) {
        return SCHTTPProtocolVersion_1_1;
    } else {
        return SCHTTPProtocolVersion_1_0;
    }
}


#pragma mark -

@implementation SCHTTPResponse
{
    NSMutableDictionary* _headers;
    BOOL _successful;
}


#pragma mark Creation

- (instancetype)initWithVersion:(SCHTTPProtocolVersion)version
                           code:(NSUInteger)code
                     andMessage:(NSString*)message
{
    self = [super init];
    if (self != nil) {
        _version = version;
        _code = code;
        _message = message;
        _headers = [NSMutableDictionary dictionary];
    }

    return self;
}


#pragma mark Public static methods

+ (SCHTTPResponse*)responseWithStatusLine:(NSString*)statusLine
{
    NSArray <NSString *>* components = [statusLine componentsSeparatedByString:@" "];
    if ([components count] > 3){
        NSMutableArray *temp = [components mutableCopy];
        [temp removeObjectAtIndex:0];
        [temp removeObjectAtIndex:0];
        NSString *lastComponent = [temp componentsJoinedByString:@" "];
        NSMutableArray *temp2 = [NSMutableArray arrayWithCapacity:3];
        [temp2 addObject:components[0]];
        [temp2 addObject:components[1]];
        [temp2 addObject:lastComponent];
        components = [temp2 copy];
    }
    
    NSString *versionString = [components firstObject];
    NSString* statusCodeString = [components objectAtIndex:1];

    SCHTTPProtocolVersion version = SCHTTPProtocolVersionFromNSString(versionString);
    NSUInteger statusCode = (NSUInteger)[statusCodeString integerValue];

    NSString* message = [components count] > 1 ? [components objectAtIndex:2] : nil;

    SCHTTPResponse* response = [[self alloc] initWithVersion:version code:statusCode andMessage:message];

    return response;
}


#pragma mark Interface

- (void)finishWithContent:(id)content size:(NSUInteger)size successful:(BOOL)successful
{
    _content = content;
    _contentSize = size;
    _successful = successful;
}

- (NSString*)headerWithName:(NSString*)header
{
    return _headers[header];
}

- (NSString*)objectForKeyedSubscript:(NSString*)header
{
    return _headers[header];
}

- (void)setValue:(NSString*)value forHeader:(NSString*)header
{
    _headers[header] = value;
}

- (void)setObject:(NSString*)value forKeyedSubscript:(NSString*)header
{
    [self setValue:value forHeader:header];
}

- (BOOL)isSuccessful
{
    return _successful;
}


#pragma mark Debug

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@{%lu, %@, %lu bytes of data}",
            NSStringFromClass([self class]), (unsigned long)_code, _message, (unsigned long)[self contentSize]];
}


@end
