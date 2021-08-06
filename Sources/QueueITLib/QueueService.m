#import "QueueService.h"
#import "QueueService_NSURLConnection.h"

static QueueService *SharedInstance;

static NSString * const API_ROOT = @"https://%@.queue-it.net/api/queue";

@implementation QueueService

+ (QueueService *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedInstance = [[QueueService_NSURLConnection alloc] init];
    });
    
    return SharedInstance;
}

-(NSString*)enqueue:(NSString*)customerId
       encodedToken:(NSString*)encodedToken
     eventOrAliasId:(NSString*)eventorAliasId
             userId:(NSString*)userId
          userAgent:(NSString*)userAgent
         sdkVersion:(NSString*)sdkVersion
         layoutName:(NSString*)layoutName
           language:(NSString*)language
            success:(void (^)(QueueStatus *))success
            failure:(QueueServiceFailure)failure
{
    NSMutableDictionary* bodyDict = [NSMutableDictionary new];
    [bodyDict setObject:userId forKey:@"userId"];
    [bodyDict setObject:userAgent forKey:@"userAgent"];
    [bodyDict setObject:sdkVersion forKey:@"sdkVersion"];
    
    if (layoutName) {
        [bodyDict setObject:layoutName forKey:@"layoutName"];
    }
    if (language) {
        [bodyDict setObject:language forKey:@"language"];
    }
    if (encodedToken) {
        [bodyDict setObject:encodedToken forKey:@"enqueueToken"];
    }
    
    NSString* urlAsString = [NSString stringWithFormat:API_ROOT, customerId];
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/%@", customerId]];
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/%@", eventorAliasId]];
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/appenqueue"]];

    return [self submitPUTPath:urlAsString body:bodyDict
            success:^(NSData *data)
            {
                NSError *error = nil;
                NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (userDict && [userDict isKindOfClass:[NSDictionary class]])
                {
                    QueueStatus* queueStatus = [[QueueStatus alloc] initWithDictionary:userDict];
                    
                    if (success != NULL) {
                        success(queueStatus);
                    }
                } else if (success != NULL) {
                    success(NULL);
                }
            }
            failure:^(NSError *error, NSString* errorMessage)
            {
                failure(error, errorMessage);
            }];
}

- (NSString *)submitPUTPath:(NSString *)path
                       body:(NSDictionary *)bodyDict
                    success:(QueueServiceSuccess)success
                    failure:(QueueServiceFailure)failure
{
    NSURL *url = [NSURL URLWithString:path];
    return [self submitRequestWithURL:url
                               method:@"PUT"
                                 body:bodyDict
                       expectedStatus:200
                              success:success
                              failure:failure];
}


#pragma mark - Abstract methods
- (NSString *)submitRequestWithURL:(NSURL *)URL
                            method:(NSString *)httpMethod
                              body:(NSDictionary *)bodyDict
                    expectedStatus:(NSInteger)expectedStatus
                           success:(QueueServiceSuccess)success
                           failure:(QueueServiceFailure)failure
{
    return nil;
}


@end
