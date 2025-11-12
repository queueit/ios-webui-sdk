#import "QueueITApiClient.h"
#import "QueueITApiClient_NSURLConnection.h"
#import "IOSUtils.h"

static QueueITApiClient *SharedInstance;

static NSString * const API_ROOT = @"https://%@.queue-it.net/api/mobileapp/queue";
static NSString * const API_ROOT_WITH_CUSTOM_DOMAIN = @"https://%@/api/mobileapp/queue";

@implementation QueueITApiClient

+ (QueueITApiClient *)getInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedInstance = [[QueueITApiClient_NSURLConnection alloc] init];
    });
    
    return SharedInstance;
}

-(NSString*)enqueue:(NSString *)customerId
     eventOrAliasId:(NSString *)eventorAliasId
  waitingRoomDomain:(NSString *)waitingRoomDomain
    queuePathPrefix:(NSString *)queuePathPrefix
             userId:(NSString *)userId
          userAgent:(NSString *)userAgent
         sdkVersion:(NSString*)sdkVersion
         layoutName:(NSString*)layoutName
           language:(NSString*)language
       enqueueToken:(NSString*)enqueueToken
         enqueueKey:(NSString*)enqueueKey
            success:(void (^)(QueueStatus *))success
            failure:(QueueServiceFailure)failure
{
    NSMutableDictionary* bodyDict = [[NSMutableDictionary alloc] init];
    [bodyDict setObject:userId forKey:@"userId"];
    [bodyDict setObject:userAgent forKey:@"userAgent"];
    [bodyDict setObject:sdkVersion forKey:@"sdkVersion"];
    
    if(layoutName){
        [bodyDict setObject:layoutName forKey:@"layoutName"];
    }
    
    if(language){
        [bodyDict setObject:language forKey:@"language"];
    }
    
    if(enqueueToken){
        [bodyDict setObject:enqueueToken forKey:@"enqueueToken"];
    }
    
    if(enqueueKey){
        [bodyDict setObject:enqueueKey forKey:@"enqueueKey"];
    }
    
    NSString* urlAsString;
        
    if ([waitingRoomDomain length] > 0) {
        NSString* newAPIDomain = waitingRoomDomain;
        if ([queuePathPrefix length] > 0) {
            queuePathPrefix = [IOSUtils sanitizeQueuePathPrefix:queuePathPrefix];
            newAPIDomain = [newAPIDomain stringByAppendingString:[NSString stringWithFormat:@"/%@", queuePathPrefix]];
        }
        urlAsString = [NSString stringWithFormat:API_ROOT_WITH_CUSTOM_DOMAIN, newAPIDomain];
     } else {
        urlAsString = [NSString stringWithFormat:API_ROOT, customerId];
     }
    
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/%@", customerId]];
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/%@", eventorAliasId]];
    urlAsString = [urlAsString stringByAppendingString:[NSString stringWithFormat:@"/enqueue"]];
    
    return [self submitPOSTPath:urlAsString body:bodyDict
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
    }
            ];
}

- (NSString *)submitPOSTPath:(NSString *)path
                        body:(NSDictionary *)bodyDict
                     success:(QueueServiceSuccess)success
                     failure:(QueueServiceFailure)failure
{
    NSURL *url = [NSURL URLWithString:path];
    return [self submitRequestWithURL:url
                               method:@"POST"
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
