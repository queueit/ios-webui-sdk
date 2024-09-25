#import <Foundation/Foundation.h>
#import "QueueService.h"

@protocol SDKQueueService_NSURLConnectionRequestDelegate;

@interface SDKQueueService_NSURLConnectionRequest : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (NSString *)uniqueIdentifier;

- (instancetype)initWithRequest:(NSURLRequest *)request
             expectedStatusCode:(NSInteger)statusCode
                        success:(QueueServiceSuccess)success
                        failure:(QueueServiceFailure)failure
                       delegate:(id<SDKQueueService_NSURLConnectionRequestDelegate>)delegate;

@end

@protocol SDKQueueService_NSURLConnectionRequestDelegate <NSObject>
- (void)requestDidComplete:(SDKQueueService_NSURLConnectionRequest *)request;
@end
