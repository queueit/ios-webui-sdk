#import "QueueITApiClient.h"
#import "QueueITApiClient_NSURLConnection.h"

static QueueITApiClient *SharedInstance;

static NSString * const API_ROOT = @"https://%@.queue-it.net/api/mobileapp/queue";
static NSString * const TESTING_API_ROOT = @"https://%@.test.queue-it.net/api/mobileapp/queue";
static bool testingIsEnabled = NO;

@implementation QueueITApiClient

+ (QueueITApiClient *)getInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedInstance = [[QueueITApiClient_NSURLConnection alloc] init];
    });
    
    return SharedInstance;
}

+ (void) setTesting:(bool)enabled
{
    testingIsEnabled = enabled;
}

-(NSString*)enqueue:(NSString *)customerId
     eventOrAliasId:(NSString *)eventorAliasId
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
    if(testingIsEnabled){
        urlAsString = [NSString stringWithFormat:TESTING_API_ROOT, customerId];
    }else{
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
