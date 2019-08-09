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

#import "SCHTTPRequest+Convenience.h"

#import "SCHTTPAccumulator.h"
#import "SCHTTPToStringConverter.h"
#import "SCJSONParser.h"
#import "SCHTTPImageDecoder.h"
#import "SCHTTPFileWriter.h"
#import "SCHTTPStreamWriter.h"
#import "SCHTTPExecutor.h"



#pragma mark -

@implementation SCHTTPRequest (Convenience)


#pragma mark      Create (POST)

+ (instancetype)createResource:(NSString*)resourceUrl withData:(NSData*)data contentType:(NSString*)contentType
{
    return [self postToURL:[NSURL URLWithString:resourceUrl] data:data contentType:contentType];
}

+ (instancetype)postToURL:(NSURL*)url data:(NSData*)data contentType:(NSString*)contentType
{
    SCHTTPRequest* request = [[self alloc] initWithURL:url andVerb:@"POST"];
    [request setUploadData:data withContentType:contentType];

    return request;
}

+ (instancetype)createResource:(NSString*)resourceUrl withContentsOfFile:(NSString*)pathToFile
{
    return [self postToURL:[NSURL URLWithString:resourceUrl] withContentsOfFile:pathToFile];
}

+ (instancetype)postToURL:(NSURL*)url withContentsOfFile:(NSString*)pathToFile
{
    SCHTTPRequest* request = [[SCHTTPRequest alloc] initWithURL:url andVerb:@"POST"];
    if (![request setUploadFile:pathToFile error:nil]) return nil;

    return request;
}

#pragma mark      Read (GET)

+ (instancetype)readResource:(NSString*)resourceUrl
{
    return [self getFromURL:[NSURL URLWithString:resourceUrl]];
}

+ (instancetype)getFromURL:(NSURL*)url
{
    return [[self alloc] initWithURL:url andVerb:@"GET"];
}

#pragma mark      Update (PUT)

+ (instancetype)updateResource:(NSString*)resourceUrl withData:(NSData*)data contentType:(NSString*)contentType
{
    return [self putToURL:[NSURL URLWithString:resourceUrl] data:data contentType:contentType];
}

+ (instancetype)putToURL:(NSURL*)url data:(NSData*)data contentType:(NSString*)contentType
{
    SCHTTPRequest* request = [[self alloc] initWithURL:url andVerb:@"PUT"];
    [request setUploadData:data withContentType:contentType];

    return request;
}

+ (instancetype)updateResource:(NSString*)resourceUrl withContentsOfFile:(NSString*)pathToFile
{
    return [self putToURL:[NSURL URLWithString:resourceUrl] withContentsOfFile:pathToFile];
}

+ (instancetype)putToURL:(NSURL*)url withContentsOfFile:(NSString*)pathToFile
{
    SCHTTPRequest* request = [[SCHTTPRequest alloc] initWithURL:url andVerb:@"PUT"];
    if (![request setUploadFile:pathToFile error:nil]) return nil;

    return request;
}

#pragma mark      Delete (DELETE)

+ (instancetype)deleteResource:(NSString*)resourceUrl
{
    return [self deleteAtURL:[NSURL URLWithString:resourceUrl]];
}

+ (instancetype)deleteAtURL:(NSURL*)url
{
    return [[self alloc] initWithURL:url andVerb:@"DELETE"];
}


#pragma mark Configuring response content handling

- (void)downloadContentAsData
{
    self.responseContentHandler = [[SCHTTPAccumulator alloc] init];
}

- (void)downloadContentAsString
{
    self.responseContentHandler = [[SCHTTPToStringConverter alloc] init];
}

- (void)downloadContentAsStringWithEncoding:(NSStringEncoding)encoding
{
    self.responseContentHandler = [[SCHTTPToStringConverter alloc] initWithEncoding:encoding];
}

- (void)downloadContentAsJSON
{
    self.responseContentHandler = [[SCJSONParser alloc] init];
}

- (void)downloadContentAsImage
{
    self.responseContentHandler = [[SCHTTPImageDecoder alloc] init];
}

- (void)downloadToFile:(NSString*)pathToFile
{
    self.responseContentHandler = [[SCHTTPFileWriter alloc] initWithTargetFile:pathToFile];
}

- (void)downloadToStream:(NSOutputStream*)stream
{
    self.responseContentHandler = [[SCHTTPStreamWriter alloc] initWithOutputStream:stream];
}

- (void)discardResponseContent
{
    self.responseContentHandler = [SCHTTPSelectiveDiscarder sharedDiscarder];
}

- (instancetype)asData
{
    [self downloadContentAsData];

    return self;
}

- (instancetype)asString
{
    [self downloadContentAsString];

    return self;
}

- (instancetype)asStringWithEncoding:(NSStringEncoding)encoding
{
    [self downloadContentAsStringWithEncoding:encoding];

    return self;
}

- (instancetype)asJSON
{
    [self downloadContentAsJSON];

    return self;
}

- (instancetype)asImage
{
    [self downloadContentAsImage];

    return self;
}


#pragma mark Executing the request

- (BOOL)execute:(void (^)(SCHTTPRequest* request))finish
{
    self.finishBlock = finish;

    return [[SCHTTPExecutor sharedExecutor] executeRequest:self];
}

- (BOOL)execute:(void (^)(SCHTTPResponse* response))completed error:(void (^)(NSError* error))error
{
    return [self execute:completed error:error cancelled:nil finally:nil];
}

- (BOOL)execute:(void (^)(SCHTTPResponse* response))completed error:(void (^)(NSError* error))error
        finally:(void (^)(void))finally
{
    return [self execute:completed error:error cancelled:nil finally:finally];
}

- (BOOL)execute:(void (^)(SCHTTPResponse* response))completed error:(void (^)(NSError* error))error
      cancelled:(void (^)(void))cancelled finally:(void (^)(void))finally
{
    // If nothing was specified, load body to memory -- perhaps an instance of SCHTTPDiscard would be better here?
    if (self.responseContentHandler == nil) [self downloadContentAsData];

    self.finishBlock = ^(SCHTTPRequest* request) {
        if (request.error != nil) {
            if (error != nil) error(request.error);
        } else if ([request wasCancelled]) {
            if (cancelled != nil) cancelled();
        } else {
            if (completed != nil) completed(request.response);
        }

        if (finally != nil) finally();
    };

    return [[SCHTTPExecutor sharedExecutor] executeRequest:self];
}

- (BOOL)setup:(void (^)(SCHTTPRequest* request))setup execute:(void (^)(SCHTTPResponse* response))completed
        error:(void (^)(NSError* error))error
{
    if (setup != nil) setup(self);

    return [self execute:completed error:error cancelled:nil finally:nil];
}

- (BOOL)setup:(void (^)(SCHTTPRequest* request))setup execute:(void (^)(SCHTTPResponse* response))completed
        error:(void (^)(NSError* error))error finally:(void (^)(void))finally
{
    if (setup != nil) setup(self);

    return [self execute:completed error:error cancelled:nil finally:finally];
}

- (BOOL)setup:(void (^)(SCHTTPRequest* request))setup execute:(void (^)(SCHTTPResponse* response))completed
        error:(void (^)(NSError* error))error cancelled:(void (^)(void))cancelled finally:(void (^)(void))finally
{
    if (setup != nil) setup(self);

    return [self execute:completed error:error cancelled:cancelled finally:finally];
}

@end
