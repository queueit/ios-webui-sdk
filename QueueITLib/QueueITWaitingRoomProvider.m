#import "QueueITWaitingRoomProvider.h"
#import "IOSUtils.h"
#import "QueueITApiClient.h"
#import "QueueTryPassResult.h"
#import <Network/Network.h>

// TODO: Include all the method calls here
@interface QueueITWaitingRoomProvider()
@property (nonatomic) id pathMonitor; // nw_path_monitor_t
@property (atomic) BOOL networkPathDetermined;
@property (atomic) BOOL networkPathSatisfied;
@property (nonatomic) dispatch_queue_t retryQueue;
@property NSString* customerId;
@property NSString* eventOrAliasId;
@property NSString* layoutName;
@property NSString* language;
@property NSString* waitingRoomDomain;
@property NSString* queuePathPrefix;
@property BOOL requestInProgress;
@property int deltaSec;


@end

@implementation QueueITWaitingRoomProvider

static int MAX_RETRY_SEC = 10;
static int INITIAL_WAIT_RETRY_SEC = 1;

-(instancetype _Nonnull)initWithCustomerId:(NSString* _Nonnull)customerId
                            eventOrAliasId:(NSString* _Nonnull)eventOrAliasId
                                layoutName:(NSString* _Nullable)layoutName
                                  language:(NSString* _Nullable)language
                         waitingRoomDomain:(NSString* _Nullable)waitingRoomDomain
                           queuePathPrefix:(NSString* _Nullable)queuePathPrefix
{
    
    if(self = [super init]) {
        self.customerId = customerId;
        self.eventOrAliasId = eventOrAliasId;
        self.layoutName = layoutName;
        self.language = language;
        self.waitingRoomDomain = waitingRoomDomain;
        self.queuePathPrefix = queuePathPrefix;
        self.deltaSec = INITIAL_WAIT_RETRY_SEC;
        self.retryQueue = dispatch_queue_create("com.queue-it.waitingroom.retry", DISPATCH_QUEUE_SERIAL);
        [self startNetworkMonitor];
    }

    return self;
}

-(void)startNetworkMonitor {
    nw_path_monitor_t monitor = nw_path_monitor_create();
    dispatch_queue_t monitorQueue = dispatch_queue_create("com.queue-it.waitingroom.pathmonitor", DISPATCH_QUEUE_SERIAL);
    nw_path_monitor_set_queue(monitor, monitorQueue);
    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(monitor, ^(nw_path_t _Nonnull path) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        strongSelf.networkPathSatisfied = (nw_path_get_status(path) == nw_path_status_satisfied);
        strongSelf.networkPathDetermined = YES;
    });
    nw_path_monitor_start(monitor);
    self.pathMonitor = monitor;
}

-(void)dealloc {
    if (self.pathMonitor != nil) {
        nw_path_monitor_cancel((nw_path_monitor_t)self.pathMonitor);
    }
}

// Non-blocking connectivity check. NWPathMonitor is authoritative once it has
// reported a path; until then we assume the network is available to avoid
// false negatives on a cold read.
-(BOOL)isNetworkAvailable {
    if (self.networkPathDetermined) {
        return self.networkPathSatisfied;
    }
    return YES;
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
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"QueueITRuntimeException" code:RequestAlreadyInProgress userInfo:nil];
        }
        return NO;
    }
    
    [IOSUtils getUserAgent:^(NSString * userAgent) {
        [self tryEnqueueWithUserAgent:userAgent enqueueToken:enqueueToken enqueueKey:enqueueKey error:error];
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
     waitingRoomDomain:self.waitingRoomDomain
       queuePathPrefix:self.queuePathPrefix
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
        
        [self handleAppEnqueueResponse:queueStatus.queueId
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
                   queueItToken:(NSString*) token
{
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
    if (self.deltaSec < MAX_RETRY_SEC)
    {
        int delaySec = self.deltaSec;
        self.deltaSec = self.deltaSec * 2;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)delaySec * NSEC_PER_SEC),
                       self.retryQueue, ^{
            [weakSelf tryEnqueue:enqueueToken enqueueKey:enqueueKey error:nil];
        });
    }
    else
    {
        self.deltaSec = INITIAL_WAIT_RETRY_SEC;
        self.requestInProgress = NO;
        [self.delegate waitingRoomProvider:self notifyProviderFailure:@"Error! Queue is unavailable." errorCode:3];
    }
}

-(BOOL)checkConnection:(NSError **)error
{
    if ([self isNetworkAvailable])
    {
        return YES;
    }
    if (error != NULL)
    {
        *error = [NSError errorWithDomain:@"QueueITRuntimeException" code:NetworkUnavailable userInfo:nil];
    }
    return NO;
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
