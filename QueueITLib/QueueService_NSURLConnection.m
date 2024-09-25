#import "QueueService_NSURLConnection.h"
#import "SDKQueueService_NSURLConnectionRequest.h"

@interface QueueService_NSURLConnection()<SDKQueueService_NSURLConnectionRequestDelegate>
@end


@implementation QueueService_NSURLConnection

- (NSString *)submitRequestWithURL:(NSURL *)URL
                            method:(NSString *)httpMethod
                              body:(NSDictionary *)bodyDict
                    expectedStatus:(NSInteger)expectedStatus
                           success:(QueueServiceSuccess)success
                           failure:(QueueServiceFailure)failure
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:httpMethod];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDict
                                                       options:0
                                                         error:&error];
    [request setHTTPBody: jsonData];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    SDKQueueService_NSURLConnectionRequest *connectionRequest;
    connectionRequest = [[SDKQueueService_NSURLConnectionRequest alloc] initWithRequest:request
                                                                  expectedStatusCode:expectedStatus
                                                                             success:success
                                                                             failure:failure
                                                                            delegate:self];
    
    NSString *connectionID = [connectionRequest uniqueIdentifier];
    
    return connectionID;
}

#pragma mark - NSURLConnectionRequestDelegate

- (void)requestDidComplete:(SDKQueueService_NSURLConnectionRequest *)request
{
}

@end
