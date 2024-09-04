#import "QueueITWaitingRoomProvider.h"
#import "IOSUtils.h"
#import "QueueITApiClient.h"
#import "QueueTryPassResult.h"
#import "Reachability.h"

// TODO: Include all the method calls here 
@interface QueueITWaitingRoomProvider()
@property (nonatomic) Reachability *internetReachability;
@property NSString* customerId;
@property NSString* eventOrAliasId;
@property NSString* layoutName;
@property NSString* language;
@property BOOL requestInProgress;
@property int deltaSec;


@end

@implementation QueueITWaitingRoomProvider

static int MAX_RETRY_SEC = 10;
static int INITIAL_WAIT_RETRY_SEC = 1;

-(instancetype _Nonnull)initWithCustomerId:(NSString* _Nonnull)customerId
                       eventOrAliasId:(NSString* _Nonnull)eventOrAliasId
                           layoutName:(NSString* _Nullable)layoutName
                    language:(NSString* _Nullable)language {
    
    if(self = [super init]) {
        self.customerId = customerId;
        self.eventOrAliasId = eventOrAliasId;
        self.layoutName = layoutName;
        self.language = language;
        self.deltaSec = INITIAL_WAIT_RETRY_SEC;
        self.internetReachability = [Reachability reachabilityForInternetConnection];
    }
    
    return self;
}
 
-(BOOL) TryPass: (NSError**)error {
    return [self tryEnqueue:nil enqueueKey:nil error:error];
}

-(BOOL) TryPassWithEnqueueToken: (NSString*)enqueueToken error:(NSError *__autoreleasing *)error {
    return [self tryEnqueue:enqueueToken enqueueKey:nil error:error];
}

-(BOOL) TryPassWithEnqueueKey: (NSString*)enqueueKey error:(NSError *__autoreleasing *)error {
   return [self tryEnqueue:nil enqueueKey:enqueueKey error:error];
}


-(BOOL)tryEnqueue:(NSString*)enqueueToken
        enqueueKey:(NSString*)enqueueKey
             error:(NSError**)error
 {
     if (self.requestInProgress) {
         *error = [NSError errorWithDomain:@"QueueITRuntimeException" code:RequestAlreadyInProgress userInfo:nil];
         return NO;
     }

     [self checkConnectionWithCompletion:^(BOOL isConnected) {
         if (!isConnected) {
             *error = [NSError errorWithDomain:@"QueueITRuntimeException" code:NetworkUnavailable userInfo:nil];
             self.requestInProgress = NO;
             return;
         }

         self.requestInProgress = YES;

         [IOSUtils getUserAgent:^(NSString *userAgent) {
             [self tryEnqueueWithUserAgent:userAgent enqueueToken:enqueueToken enqueueKey:enqueueKey error:error];
         }];
     }];

     return YES;
 }


-(void)tryEnqueueWithUserAgent:(NSString*)secretAgent
                  enqueueToken:(NSString*)enqueueToken
                    enqueueKey:(NSString*)enqueueKey
                    error:(NSError**)error
{
    NSString* userId = [IOSUtils getUserId];
    NSString* userAgent = [NSString stringWithFormat:@"%@;%@", secretAgent, [IOSUtils getLibraryVersion]];
    NSString* sdkVersion = [IOSUtils getSdkVersion];
    
    QueueITApiClient* apiClient = [QueueITApiClient getInstance];
    [apiClient enqueue:self.customerId
               eventOrAliasId:self.eventOrAliasId
               userId:userId
               userAgent:userAgent
               sdkVersion:sdkVersion
               layoutName:self.layoutName
               language:self.language
               enqueueToken:enqueueToken
               enqueueKey:enqueueKey
               success:^(QueueStatus *queueStatus)
{
        if (queueStatus == NULL) {
            [self enqueueRetryMonitor:enqueueToken enqueueKey:enqueueKey error:error];
            return;
        }
        
        [self handleAppEnqueueResponse: queueStatus.queueId
                              queueURL:queueStatus.queueUrlString
                        eventTargetURL:queueStatus.eventTargetUrl
                          queueItToken:queueStatus.queueitToken];
        
        self.requestInProgress = NO;
    }
        failure:^(NSError *error, NSString* errorMessage)
     {
        if (error.code >= 400 && error.code < 500)
        {
            [self.delegate waitingRoomProvider:self notifyProviderFailure:errorMessage errorCode:error.code];
        }
        else
        {
            [self enqueueRetryMonitor:enqueueToken enqueueKey:enqueueKey error:&error];
        }
    }];
}

-(void)handleAppEnqueueResponse:(NSString*) queueId
                       queueURL:(NSString*) queueURL
                 eventTargetURL:(NSString*) targetURL
                   queueItToken:(NSString*) token {

    bool isPassedThrough = ![self isNullOrEmpty:token];
    
    NSString* redirectType = [self getRedirectTypeFromToken:token];
    
    QueueTryPassResult* queueTryPassResult =  [[QueueTryPassResult alloc]
                                              initWithQueueUrl:queueURL
                                              targetUrl:targetURL
                                              redirectType:redirectType
                                              isPassedThrough:isPassedThrough
                                              queueToken:token];
    
    [self.delegate waitingRoomProvider:self notifyProviderSuccess:queueTryPassResult];
}

-(void)enqueueRetryMonitor:(NSString*)enqueueToken
                enqueueKey:(NSString*)enqueueKey
                error:(NSError**)error
{
    if (self.deltaSec < MAX_RETRY_SEC) {

        // Schedule retry on a background thread
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.deltaSec * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self tryEnqueue:enqueueToken enqueueKey:enqueueKey error:error];
            self.deltaSec = self.deltaSec * 2;
        });

    } else {
        self.deltaSec = INITIAL_WAIT_RETRY_SEC;
        self.requestInProgress = NO;
        [self.delegate waitingRoomProvider:self notifyProviderFailure:@"Error! Queue is unavailable." errorCode:3];
    }
}

- (void)checkConnectionWithCompletion:(void(^)(BOOL isConnected))completion {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        BOOL isConnected = NO;
        int count = 0;
        while (count < 5) {
            NetworkStatus netStatus = [self.internetReachability currentReachabilityStatus];
            if (netStatus == NotReachable) {
                [NSThread sleepForTimeInterval:1.0f];  // Blocking sleep
                count++;
            } else {
                isConnected = YES;
                break;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(isConnected);
            }
        });

    });
}

-(BOOL)IsRequestInProgress {
    return self.requestInProgress;
}

-(BOOL)isNullOrEmpty:(NSString*)queueToken {
    bool isNull = queueToken == nil || queueToken == (id)[NSNull null];
    bool isEmpty = isNull || [queueToken length] == 0;
    
    return isNull && isEmpty;
}

-(NSString*) getRedirectTypeFromToken: (NSString*) queueToken {
    
    if([self isNullOrEmpty:queueToken])
    {
        return @"queue";
    }
    
    NSString *searchedString = queueToken;
    NSRange   searchedRange = NSMakeRange(0, [searchedString length]);
    NSString *pattern = @"\\~rt_(.*?)\\~";
    NSError  *error = nil;

    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:searchedString options:0 range: searchedRange];
    return [searchedString substringWithRange:[match rangeAtIndex:1]];
}

@end
