//
//  ViewController.m
//  Sample
//
//  Created by Matt Reach on 2019/8/8.
//  Copyright © 2019 Matt Reach. All rights reserved.
//
/*
 2019-08-09 15:32:45.167682+0800 Sample[71167:6725646] SCHTTP |  INFO | curl_global_init() successfully executed; SCHTTP booted with libcurl '7.60.0-DEV'.
 2019-08-09 15:32:45.168243+0800 Sample[71167:6725662] SCHTTP |  INFO | GET http://localhost/2.8/HelloWorld.png | wait resp  | Request starting…
 2019-08-09 15:32:45.173574+0800 Sample[71167:6725662] SCHTTP | DEBUG | GET http://localhost/2.8/HelloWorld.png | wait resp  | Receiving response with line 'HTTP/1.1 200 OK'.
 2019-08-09 15:32:45.173621+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Transitioned from state: 'wait resp '
 2019-08-09 15:32:45.173695+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Received header 'Server: nginx/1.13.9'.
 2019-08-09 15:32:45.173742+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Received header 'Date: Fri, 09 Aug 2019 07:32:45 GMT'.
 2019-08-09 15:32:45.173786+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Received header 'Content-Type: image/png'.
 2019-08-09 15:32:45.173864+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Received header 'Content-Length: 324064'.
 2019-08-09 15:32:45.173910+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Received header 'Last-Modified: Tue, 27 Jan 2015 17:54:20 GMT'.
 2019-08-09 15:32:45.174129+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Received header 'Connection: keep-alive'.
 2019-08-09 15:32:45.174171+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Received header 'ETag: "54c7d0cc-4f1e0"'.
 2019-08-09 15:32:45.174209+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | Received header 'Accept-Ranges: bytes'.
 2019-08-09 15:32:45.174237+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx headers | All headers received.
 2019-08-09 15:32:45.174330+0800 Sample[71167:6725662] SCHTTP | DEBUG | GET http://localhost/2.8/HelloWorld.png | rx headers | Request handler accepted 200 OK response.
 2019-08-09 15:32:45.174366+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx content | Transitioned from state: 'rx headers'
 2019-08-09 15:32:45.174412+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | rx content | Transferred 16141b to response content handler.
 2019-08-09 15:32:45.184532+0800 Sample[71167:6725662] SCHTTP | TRACE | GET http://localhost/2.8/HelloWorld.png | terminated | Transitioned from state: 'rx content'
 2019-08-09 15:32:45.184578+0800 Sample[71167:6725662] SCHTTP | DEBUG | GET http://localhost/2.8/HelloWorld.png | terminated | Response with status '200' (OK) finished with error parsing content: Request timed out..
 2019-08-09 15:32:45.184623+0800 Sample[71167:6725662] SCHTTP |  INFO | GET http://localhost/2.8/HelloWorld.png | terminated | Request abnormally terminated:(28) Request timed out.
 2019-08-09 15:32:45.298084+0800 Sample[71167:6725646] Error: Request timed out.
  */

 //curl_easy_setopt(handle, CURLOPT_LOW_SPEED_TIME, context.request.downloadTimeout.duration /* value type must be long, can't be double!!! */)
 

#import "ViewController.h"
#import <SCHTTPClient/SCHTTP.h>
#import <SCHTTPClient/SCHTTPExecutor.h>
#import <SCHTTPClient/curl.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [SCHTTPExecutor InitCurl];
//    int maxQueueSize = [[SCHTTPExecutor sharedExecutor] maxQueueSize];
    // Do any additional setup after loading the view.
    [self getImageExample];
}

- (void)getImageExample
{
    [[SCHTTPRequest readResource:@"http://localhost/2.8/HelloWorld.png"] setup:^(id request) {
        [request downloadContentAsImage]; // alternative to 'asImage' fluent syntax
    } execute:^(SCHTTPResponse* response) {
        NSImage* image = response.content;
        NSLog(@"image size: %@", NSStringFromSize(image.size));
    } error:^(NSError* error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }];
}

- (void)getExample
{
    [[SCHTTPRequest readResource:@"http://biasedbit.com"] execute:^(SCHTTPResponse* response) {
        NSLog(@"Finished: %lu %@ -- received %lu bytes of '%@' %@",
              response.code, response.message, response.contentSize,
              response[@"Content-Type"], response.headers);
    } error:^(NSError* error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
