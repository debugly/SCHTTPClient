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

#import "SCHTTPRequestContext.h"

#import "SCHTTPRequest+PrivateInterface.h"
#import "SCHTTPUtils.h"



#pragma mark -

@implementation SCHTTPRequestContext
{
    NSMutableArray* _receivedResponses;
    NSInputStream* _uploadStream;
    BOOL _discardBodyForCurrentResponse;
    BOOL _uploadAccepted;
    BOOL _uploadPaused;
    BOOL _uploadAborted;
}


#pragma mark Creating a request context

- (instancetype)init
{
    NSAssert(NO, @"please use initWithRequest:andHandle: instead");
    return nil;
}

- (instancetype)initWithRequest:(SCHTTPRequest*)request andCurlHandle:(CURL*)handle
{
    self = [super init];
    if (self != nil) {
        _request = request;
        _handle = handle;

        _uploadAborted = NO;
        _uploadAccepted = YES;
        _uploadPaused = NO;
        _receivedResponses = [NSMutableArray array];
    }

    return self;
}


#pragma mark Managing state transitions

- (BOOL)finishCurrentResponse
{
    if (_currentResponse == nil) return NO;

    id parsedContent = nil;

    SCHTTPResponseState nextState = SCHTTPResponseStateFinished; // Mark request as finished...

    if ([self isCurrentResponse100Continue]) {
        nextState = SCHTTPResponseStateReadingStatusLine; // ... unless it's a 100-Continue; if so, go back to the start
        // TODO I'm assuming 100-Continue's never have data...
        _uploadAccepted = YES;
    } else if (!_discardBodyForCurrentResponse) {
        NSError* error = nil;
        parsedContent = [_request.responseContentHandler parseContent:&error];

        if (error != nil) _error = error;
    }

    [self switchToState:nextState];

    [_currentResponse finishWithContent:parsedContent size:_downloadedBytes successful:(_error == nil)];
    SCHTTPResponse* response = _currentResponse;
    _currentResponse = nil;
    [_receivedResponses addObject:response];

    if (_error != nil) {
        SCHTTPLogDebug(@"%@ | Response with status '%lu' (%@) finished with error parsing content: %@.",
                       self, (unsigned long)response.code, response.message, [self.error localizedDescription]);
        return NO;
    } else {
        SCHTTPLogDebug(@"%@ | Response with status '%lu' (%@) finished.",
                       self, (unsigned long)response.code, response.message);
        return YES;
    }
}

- (BOOL)prepareToReceiveData
{
    if (_request.responseContentHandler == nil) {
        _discardBodyForCurrentResponse = YES;
        SCHTTPLogDebug(@"%@ | Response %lu %@ accepted but content will be discarded (no content handler).",
                       self, (unsigned long)self.currentResponse.code, self.currentResponse.message);
    } else {
        NSError* error = nil;
        BOOL parserAcceptsResponse = [_request.responseContentHandler
                                      prepareForResponse:_currentResponse.code message:_currentResponse.message
                                      headers:_currentResponse.headers error:&error];

        if (!parserAcceptsResponse) {
            _discardBodyForCurrentResponse = YES;
            if (error != nil) _error = error;
        }

        if (_error != nil) {
            SCHTTPLogError(@"%@ | Request handler rejected %lu %@ response with error: %@",
                           self, (unsigned long)self.currentResponse.code, self.currentResponse.message,
                           [self.error localizedDescription]);

            return NO;
        }

        SCHTTPLogDebug(@"%@ | Request handler accepted %lu %@ response.",
                       self, (unsigned long)self.currentResponse.code, self.currentResponse.message);
    }

    [self switchToState:SCHTTPResponseStateReadingData];
    return YES;
}

- (void)requestFinished
{
    [self finishCurrentResponse];
    [self cleanup];

    [_request executionFailedWithFinalResponse:[self lastResponse] error:_error];
}

- (void)requestFinishedWithError:(NSError*)error
{
    if (_error == nil) _error = error;

    [self requestFinished];
}

- (void)cleanup
{
    if (_uploadStream != nil) [_uploadStream close];

    if ((_request.responseContentHandler != nil) &&
        [_request.responseContentHandler respondsToSelector:@selector(cleanup)]) {
        [_request.responseContentHandler cleanup];
    }
}


#pragma mark Managing the upload

- (void)waitFor100ContinueBeforeUploading
{
    _uploadAccepted = NO;
}

- (BOOL)hasUploadBeenAccepted
{
    return _uploadAccepted;
}

- (BOOL)isUploadPaused
{
    return _uploadPaused;
}

- (void)pauseUpload
{
    _uploadPaused = YES;
}

- (void)unpauseUpload
{
    _uploadPaused = NO;
}

- (BOOL)hasUploadBeenAborted
{
    return _uploadAborted;
}

- (BOOL)is100ContinueRequired
{
    return [_request hasHeader:H(Expect) withValue:HV(100Continue)];
}

- (NSInteger)transferInputToBuffer:(uint8_t*)buffer limit:(NSUInteger)limit
{
    if (![_request isUpload]) return -1;

    if (_uploadStream == nil) {
        [self switchToState:SCHTTPResponseStateSendingData];
        if (_request.uploadStream != nil) {
            _uploadStream = _request.uploadStream;

        } else if (_request.uploadFile != nil) {
            _uploadStream = [NSInputStream inputStreamWithFileAtPath:_request.uploadFile];
            if (_uploadStream == nil) {
                _error = SCHTTPErrorWithReason(SCHTTPErrorCodeUploadFileStreamError,
                                               @"Couldn't upload file",
                                               @"File does not exist or cannot be read.");
                return -1;
            }
            SCHTTPLogTrace(@"%@ | Created input stream from file '%@' for upload.", self, self.request.uploadFile);

        } else {
            _uploadStream = [NSInputStream inputStreamWithData:_request.uploadData];
            if (_uploadStream == nil) {
                _error = SCHTTPErrorWithReason(SCHTTPErrorCodeUploadDataStreamError,
                                               @"Couldn't upload data",
                                               @"Upload data is not instance of NSData.");
                return -1;
            }
            SCHTTPLogTrace(@"%@ | Created input stream from in-memory NSData for upload.", self);
        }

        [_uploadStream open];
    }

    NSInteger read = [_uploadStream read:buffer maxLength:limit];
    if (read <= 0) {
        SCHTTPLogTrace(@"%@ | Upload stream read %@, closing stream...", self, read == 0 ? @"finished" : @"error");
        [_uploadStream close];
        _uploadStream = nil;
    } else {
        _uploadedBytes += read;
        [_request uploadProgressedToCurrent:_uploadedBytes ofTotal:_request.uploadSize];
        SCHTTPLogTrace(@"%@ | Transferred %ldb to server.", self, (long)read);
        if (read < limit) {
            SCHTTPLogTrace(@"%@ | Upload finished.", self);
            [self uploadFinished];
        }
    }

    return read;
}


#pragma mark Reading data from the server

- (BOOL)beginResponseWithLine:(NSString*)line
{
    if (_currentResponse != nil) [self finishCurrentResponse];

    _uploadedBytes = 0;
    _downloadSize = 0;
    _downloadedBytes = 0;
    _discardBodyForCurrentResponse = NO;
    _currentResponse = [SCHTTPResponse responseWithStatusLine:line];
    if (_currentResponse == nil) return NO; // May happen if line is not a valid status response line

    SCHTTPLogDebug(@"%@ | Receiving response with line '%@'.", self, line);
    if ([_request isUpload] && (_currentResponse.code >= 300)) {
        _uploadAborted = YES;
        SCHTTPLogTrace(@"%@ | ShouldAbortUpload flag set (final non-success response received)", self);
    }

    [self switchToState:SCHTTPResponseStateReadingHeaders];
    return YES;
}

- (BOOL)addHeaderToCurrentResponse:(NSString*)line
{
    if (_currentResponse == nil) return NO;

    return [self parseHeaderLine:line andAddToResponse:_currentResponse];
}

- (BOOL)appendDataToCurrentResponse:(uint8_t*)bytes withLength:(NSUInteger)length
{
    if (_currentResponse == nil) return NO;
    if (_discardBodyForCurrentResponse) return YES;

    if ([self transferBytes:bytes withLength:length toHandler:_request.responseContentHandler]) {
        _downloadedBytes += length;
        [_request downloadProgressedToCurrent:_downloadedBytes ofTotal:_downloadSize];
        return YES;
    }

    return NO;
}


#pragma mark Querying context information

- (SCHTTPResponse*)lastResponse
{
    return [_receivedResponses lastObject];
}

- (BOOL)isCurrentResponse100Continue
{
    if (_currentResponse == nil) return NO;

    return _currentResponse.code == 100;
}


#pragma mark Private helpers

- (void)uploadFinished
{
    [self switchToState:SCHTTPResponseStateReadingStatusLine];
}

- (BOOL)parseHeaderLine:(NSString*)headerLine andAddToResponse:(SCHTTPResponse*)response
{
    if (headerLine == nil) return NO;

    NSRange range = [headerLine rangeOfString:@": "];
    if (range.location == NSNotFound) return NO;

    NSString* headerName = [headerLine substringToIndex:range.location];
    NSString* headerValue = [headerLine substringFromIndex:NSMaxRange(range)];
    [response setValue:headerValue forHeader:headerName];

    // If it's the Content-Length header, set our expected download size
    if ([headerName isEqualToString:H(ContentLength)]) _downloadSize = (NSUInteger)[headerValue integerValue];

    SCHTTPLogTrace(@"%@ | Received header '%@: %@'.", self, headerName, headerValue);

    return YES;
}

- (BOOL)transferBytes:(uint8_t*)bytes withLength:(NSUInteger)length toHandler:(id<SCHTTPContentHandler>)handler
{
    NSError* error = nil;
    NSInteger written = [handler appendResponseBytes:bytes withLength:length error:&error];
    if (error != nil) {
        _error = error;
        SCHTTPLogError(@"%@ | Error raised while attempting to transfer %lub to response content handler: %@",
                       self, (unsigned long)length, [error localizedDescription]);
        return NO;
    } else if (written < length) {
        _error = SCHTTPErrorWithReason(SCHTTPErrorCodeDownloadCannotWriteToHandler,
                                       @"Error handling response content",
                                       @"Response handler capacity reached before content was fully read.");
        SCHTTPLogError(@"%@ | Could only write %ld bytes to response handler (expecting %lu)",
                       self, (long)written, (unsigned long)length);
        return NO;
    }

    SCHTTPLogTrace(@"%@ | Transferred %lub to response content handler.", self, (unsigned long)length);
    return YES;
}

- (void)switchToState:(SCHTTPResponseState)state
{
    SCHTTPResponseState oldState = _state;
    _state = state;
    SCHTTPLogTrace(@"%@ | Transitioned from state: '%@'", self, [self humanReadableState:oldState]);
}


#pragma mark Debug

- (NSString*)humanReadableState:(SCHTTPResponseState)state
{
    switch (state) {
        case SCHTTPResponseStateReady:
            if ([_request isUpload]) return @"wait send ";
            else return @"wait resp ";
        case SCHTTPResponseStateSendingData:
            return @"tx request";
        case SCHTTPResponseStateReadingStatusLine:
            return @"wait resp ";
        case SCHTTPResponseStateReadingHeaders:
            return @"rx headers";
        case SCHTTPResponseStateReadingData:
            return @"rx content";
        default:
            return @"terminated";
    }
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ | %@", _request, [self humanReadableState:_state]];
}

@end
