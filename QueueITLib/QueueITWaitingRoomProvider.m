#import "QueueITWaitingRoomProvider.h"
#import "IOSUtils.h"
#import "QueueITApiClient.h"
#import "QueueCache.h"
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
@property QueueCache* cache;


@end

@implementation QueueITWaitingRoomProvider

static int MAX_RETRY_SEC = 10;
static int INITIAL_WAIT_RETRY_SEC = 1;

-(instancetype _Nonnull)init:(NSString* _Nonnull)customerId
                       eventOrAliasId:(NSString* _Nonnull)eventOrAliasId
                           layoutName:(NSString* _Nullable)layoutName
                    language:(NSString* _Nullable)language {
    
    if(self = [super init]) {
        self.cache = [QueueCache instance:customerId eventId:eventOrAliasId];
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
    if(![self checkConnection:error]) {
        return NO;
    }
    
    if(self.requestInProgress) {
        *error = [NSError errorWithDomain:@"QueueITRuntimeException" code:RequestAlreadyInProgress userInfo:nil];
        return NO;
    }
    
    [IOSUtils getUserAgent:^(NSString * userAgent) {
        [self tryEnqueueWithUserAgent:userAgent enqueueToken:enqueueToken enqueueKey:enqueueKey];
    }];
    
    return YES;
}

-(void)tryEnqueueWithUserAgent:(NSString*)secretAgent
                  enqueueToken:(NSString*)enqueueToken
                    enqueueKey:(NSString*)enqueueKey
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
            [self enqueueRetryMonitor:enqueueToken enqueueKey:enqueueKey];
            return;
        }
        
        [self handleAppEnqueueResponse: queueStatus.queueId
                              queueURL:queueStatus.queueUrlString
                  queueURLTTLInMinutes:queueStatus.queueUrlTTL
                        eventTargetURL:queueStatus.eventTargetUrl
                          queueItToken:queueStatus.queueitToken];
        
        self.requestInProgress = NO;
    }
        failure:^(NSError *error, NSString* errorMessage)
     {
        if (error.code >= 400 && error.code < 500)
        {
            [self.providerQueueITUnavailableDelegate notifyProviderQueueITUnavailable: errorMessage];
        }
        else
        {
            [self enqueueRetryMonitor:enqueueToken enqueueKey:enqueueKey];
        }
    }];
}

-(void)handleAppEnqueueResponse:(NSString*) queueId
                       queueURL:(NSString*) queueURL
           queueURLTTLInMinutes:(int) ttl
                 eventTargetURL:(NSString*) targetURL
                   queueItToken:(NSString*) token {

    bool isPassedThrough = [self isNullOrEmpty:token];
    
    NSString* redirectType = [self getRedirectTypeFromToken:token];
    
    QueueTryPassResult* queueTryPassResult =  [[QueueTryPassResult alloc]
                                              initWithQueueUrl:queueURL targetUrl:targetURL
                                              urlTTLInMinutes:ttl
                                              redirectType:redirectType
                                              isPassedThrough:isPassedThrough
                                              queueToken:token];
    
    [self.providerSuccessDelegate notifyProviderSuccess:queueTryPassResult];
}

-(void)enqueueRetryMonitor:(NSString*)enqueueToken
                enqueueKey:(NSString*)enqueueKey
{
    if (self.deltaSec < MAX_RETRY_SEC)
    {
        [self tryEnqueue:enqueueToken enqueueKey:enqueueKey error:nil];
        
        [NSThread sleepForTimeInterval:self.deltaSec];
        self.deltaSec = self.deltaSec * 2;
    }
    else
    {
        self.deltaSec = INITIAL_WAIT_RETRY_SEC;
        self.requestInProgress = NO;
        [self.providerQueueITUnavailableDelegate notifyProviderQueueITUnavailable: @"Unexpected error. Try again later"];
    }
}

-(BOOL)checkConnection:(NSError **)error
{
    int count = 0;
    while (count < 5)
    {
        NetworkStatus netStatus = [self.internetReachability currentReachabilityStatus];
        if (netStatus == NotReachable)
        {
            [NSThread sleepForTimeInterval:1.0f];
            count++;
        }
        else
        {
            return YES;
        }
    }
    *error = [NSError errorWithDomain:@"QueueITRuntimeException" code:NetworkUnavailable userInfo:nil];
    return NO;
}

-(BOOL)IsRequestInProgress {
    return self.requestInProgress;
}

-(BOOL)isSafetyNet:(NSString*) queueId
          queueURL:(NSString*) queueURL
{
    bool queueIdExists = queueId != nil && queueId != (id)[NSNull null];
    bool queueUrlExists = queueURL != nil && queueURL != (id)[NSNull null];
    return queueIdExists && !queueUrlExists;
}

-(BOOL)isDisabled:(NSString*) queueId
         queueURL:(NSString*) queueURL
{
    bool queueIdExists = queueId != nil && queueId != (id)[NSNull null];
    bool queueUrlExists = queueURL != nil && queueURL != (id)[NSNull null];
    return !queueIdExists && !queueUrlExists;
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
