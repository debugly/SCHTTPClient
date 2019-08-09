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

#import "SCHTTPRequest+PrivateInterface.h"
#import "SCHTTPRequestInternal.h"
#import "SCHTTPUtils.h"

#pragma mark -

@implementation SCHTTPRequest (PrivateInterface)


#pragma mark Events

- (BOOL)executionStarted
{
    if ([self hasFinished]) return NO;

    self.startTimestamp = SCHTTPCurrentTimeMillis();
    if (self.startBlock != nil) {
        dispatch_async(self.callbackQueue, ^{
            self.startBlock();

            self.startBlock = nil;
        });
    }

    return YES;
}

- (BOOL)executionFailedWithFinalResponse:(SCHTTPResponse*)response error:(NSError*)error
{
    if ([self hasFinished]) return NO;

    self.endTimestamp = SCHTTPCurrentTimeMillis();
    self.error = error;
    self.response = response;

    if (self.finishBlock != nil) {
        dispatch_async(self.callbackQueue, ^{
            self.finishBlock(self);

            self.uploadProgressBlock = nil;
            self.downloadProgressBlock = nil;
            self.finishBlock = nil;
        });
    }
    
    return YES;
}

- (BOOL)uploadProgressedToCurrent:(NSUInteger)current ofTotal:(NSUInteger)total
{
    if ([self hasFinished]) return NO;

    self.sentBytes = current;

    if (self.uploadProgressBlock != nil) {
        dispatch_async(self.callbackQueue, ^{
            self.uploadProgressBlock(current, total);
        });
    }

    return YES;
}

- (BOOL)downloadProgressedToCurrent:(NSUInteger)current ofTotal:(NSUInteger)total
{
    if ([self hasFinished]) return NO;

    self.receivedBytes = current;

    if (self.downloadProgressBlock != nil) {
        dispatch_async(self.callbackQueue, ^{
            self.downloadProgressBlock(current, total);
        });
    }

    return YES;
}

@end
