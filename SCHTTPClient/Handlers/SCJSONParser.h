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

#import "SCHTTPAccumulator.h"



#pragma mark -

@interface SCJSONParser : SCHTTPAccumulator


#pragma mark Defining default response pre-conditions for JSON parsing

/**
 Affects the `<acceptableResponses>` property for every new instance of this class that is created.

 Use this method if the default acceptable response codes don't fit your needs, as to avoid having to set them up for
 every new request.

 @param acceptableResponses Array of numbers.

 @see acceptableResponses
 */
+ (void)setDefaultAcceptableResponses:(NSArray*)acceptableResponses;

/**
 Affects the `<acceptableContentTypes>` property for every new instance of this class that is created.

 Use this method if the default acceptable content types don't fit your needs, as to avoid having to set them up for
 every new request.

 @param acceptableContentTypes Array of strings.

 @see acceptableContentTypes
 */
+ (void)setDefaultAcceptableContentTypes:(NSArray*)acceptableContentTypes;

@end