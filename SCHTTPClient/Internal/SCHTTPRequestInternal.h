//
//  SCHTTPRequestInternal.h
//  Pods
//
//  Created by Matt Reach on 2019/8/9.
//

#ifndef SCHTTPRequestInternal_h
#define SCHTTPRequestInternal_h

#import "SCHTTPRequest.h"

@interface SCHTTPRequest ()

@property(strong, readwrite) NSError* error;
@property(assign) long long startTimestamp;
@property(assign) long long  endTimestamp;
@property(assign) NSUInteger sentBytes;
@property(assign) NSUInteger receivedBytes;
@property(strong) SCHTTPResponse* response;
@property(assign) NSUInteger uploadSize; // Cached upload size, when available
@property(strong, readwrite) NSMutableDictionary* headers; // Header storage; auto generated synthesizer for headers property will use this ivar

@end

#endif /* SCHTTPRequestInternal_h */
