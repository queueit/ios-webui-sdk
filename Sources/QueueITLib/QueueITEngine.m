#import "QueueITEngine.h"
#import "QueueITWKViewController.h"
#import "QueueService.h"
#import "QueueStatus.h"
#import "IOSUtils.h"
#import "Reachability.h"
#import "QueueCache.h"

@interface QueueITEngine()
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic, strong)UIViewController* host;
@property (nonatomic, strong)NSString* customerId;
@property (nonatomic, strong)NSString* eventId;
@property (nonatomic, strong)NSString* encodedToken;
@property (nonatomic, strong)NSString* eventDomain;
@property (nonatomic, strong)NSString* eventTargetURL;
@property (nonatomic, strong)NSString* queueId;
@property (nonatomic, strong)NSString* layoutName;
@property (nonatomic, strong)NSString* language;
@property int delayInterval;
@property bool isInQueue;
@property bool requestInProgress;
@property int queueUrlTtl;
@property (nonatomic, strong)QueueCache* cache;
@property int deltaSec;
@end

@implementation QueueITEngine

static int MAX_RETRY_SEC = 10;
static int INITIAL_WAIT_RETRY_SEC = 1;

-(instancetype)initWithHost:(UIViewController*)host customerId:(NSString*)customerId eventOrAliasId:(NSString*)eventOrAliasId
                 layoutName:(NSString*)layoutName language:(NSString*)language encodedToken:(NSString*)encodedToken
{
    self = [super init];
    if(self) {
        self.cache = [QueueCache instance:customerId eventId:eventOrAliasId];
        self.host = host;
        self.customerId = customerId;
        self.eventId = eventOrAliasId;
        self.layoutName = layoutName;
        self.language = language;
        self.encodedToken = encodedToken;
        self.delayInterval = 0;
        self.isInQueue = NO;
        self.requestInProgress = NO;
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        self.deltaSec = INITIAL_WAIT_RETRY_SEC;
    }
    return self;
}

-(instancetype)initWithHost:(UIViewController*)host customerId:(NSString*)customerId eventOrAliasId:(NSString*)eventOrAliasId
                eventDomain:(NSString*)eventDomain targetURL:(NSString*)targetURL queueId:(NSString*)queueId
                 layoutName:(NSString*)layoutName language:(NSString*)language encodedToken:(NSString*)encodedToken {
    if (self = [super init]) {
        self.cache = [QueueCache instance:customerId eventId:eventOrAliasId];
        self.host = host;
        self.customerId = customerId;
        self.eventId = eventOrAliasId;
        self.eventDomain = eventDomain;
        self.queueId = queueId;
        self.eventTargetURL = targetURL;
        self.layoutName = layoutName;
        self.language = language;
        self.delayInterval = 0;
        self.isInQueue = NO;
        self.requestInProgress = NO;
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        self.deltaSec = INITIAL_WAIT_RETRY_SEC;
    }
    return self;
}

-(void)setViewDelay:(int)delayInterval {
    self.delayInterval = delayInterval;
}

-(void)checkConnection
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
            return;
        }
    }
    @throw [NSException exceptionWithName:@"QueueITRuntimeException" reason:[self errorTypeEnumToString:NetworkUnavailable] userInfo:nil];
}

-(NSString*) errorTypeEnumToString:(QueueITRuntimeError)errorEnumVal
{
    NSArray *errorTypeArray = [[NSArray alloc] initWithObjects:QueueITRuntimeErrorArray];
    return [errorTypeArray objectAtIndex:errorEnumVal];
}

-(BOOL)isUserInQueue {
    return self.isInQueue;
}

-(BOOL)isRequestInProgress {
    return self.requestInProgress;
}

-(void)run
{
    [self checkConnection];
    
    if(self.requestInProgress)
    {
        @throw [NSException exceptionWithName:@"QueueITRuntimeException" reason:[self errorTypeEnumToString:RequestAlreadyInProgress] userInfo:nil];
    }
    
    self.requestInProgress = YES;
    
    NSString * queueURL = [self queueURL];
    if (queueURL != NULL && self.eventTargetURL != NULL)
    {
        [self showQueue:queueURL targetUrl:self.eventTargetURL];
    } else if (![self tryShowQueueFromCache])
    {
        [self tryEnqueue];
    }

}

-(BOOL)tryShowQueueFromCache
{
    if (![self.cache isEmpty])
    {
        NSString* urlTtlString = [self.cache getUrlTtl];
        long long cachedTime = [urlTtlString longLongValue];
        long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
        if (currentTime < cachedTime)
        {
            NSString* targetUrl = [self.cache getTargetUrl];
            NSString* queueUrl = [self.cache getQueueUrl];
            [self showQueue:queueUrl targetUrl:targetUrl];
            return YES;
        }
    }
    return NO;
}

-(void)showQueue:(NSString*)queueUrl targetUrl:(NSString*)targetUrl
{
    [self raiseQueueViewWillOpen];
    
    QueueITWKViewController *queueWKVC = [[QueueITWKViewController alloc] initWithHost:self.host
                                                                           queueEngine:self
                                                                              queueUrl:queueUrl
                                                                        eventTargetUrl:targetUrl
                                                                            customerId:self.customerId
                                                                               eventId:self.eventId];

    queueWKVC.closeImage = self.closeImage;
    queueWKVC.modalPresentationStyle = UIModalPresentationFullScreen;

    if (self.delayInterval > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.host presentViewController:queueWKVC animated:YES completion:nil];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.host presentViewController:queueWKVC animated:YES completion:nil];
        });
    }
}

-(void)tryEnqueue
{
    [IOSUtils getUserAgent:^(NSString * userAgent) {
        [self tryEnqueueWithUserAgent:userAgent];
    }];
}

-(void)tryEnqueueWithUserAgent:(NSString*)secretAgent
{
    NSString* userId = [IOSUtils getUserId];
    NSString* userAgent = [NSString stringWithFormat:@"%@;%@", secretAgent, [IOSUtils getLibraryVersion]];
    NSString* sdkVersion = [IOSUtils getSdkVersion];
    
    QueueService* qs = [QueueService sharedInstance];
    [qs enqueue:self.customerId
   encodedToken:self.encodedToken
 eventOrAliasId:self.eventId
         userId:userId userAgent:userAgent
     sdkVersion:sdkVersion
     layoutName:self.layoutName
       language:self.language
        success:^(QueueStatus *queueStatus)
     {
         if (queueStatus == NULL) {
             [self enqueueRetryMonitor];
             return;
         }
         
         bool queueIdExists = queueStatus.queueId != nil && queueStatus.queueId != (id)[NSNull null];
         bool queueUrlExists = queueStatus.queueUrlString != nil && queueStatus.queueUrlString != (id)[NSNull null];
         
         //SafetyNet
         if (queueIdExists && !queueUrlExists)
         {
             [self.queueViewWillOpenDelegate notifyOnQueueIdChanged:queueStatus.queueId];
             [self raiseQueuePassed:queueStatus.queueitToken];
         }
         //InQueue
         else if (queueIdExists && queueUrlExists)
         {
             self.queueUrlTtl = queueStatus.queueUrlTTL;
             [self.queueViewWillOpenDelegate notifyOnQueueIdChanged:queueStatus.queueId];
             [self showQueue:queueStatus.queueUrlString targetUrl:queueStatus.eventTargetUrl];
             
             NSString* urlTtlString = [self convertTtlMinutesToSecondsString:queueStatus.queueUrlTTL];
             [self.cache update:queueStatus.queueUrlString urlTTL:urlTtlString targetUrl:queueStatus.eventTargetUrl];
         }
         //PostQueue or Idle
         else if (!queueIdExists && queueUrlExists)
         {
             [self showQueue:queueStatus.queueUrlString targetUrl:queueStatus.eventTargetUrl];
         }
         //Disabled
         else
         {
             self.requestInProgress = NO;
             [self raiseQueueDisabled];
         }
     }
        failure:^(NSError *error, NSString* errorMessage)
     {
         if (error.code >= 400 && error.code < 500)
         {
             [self.queueITUnavailableDelegate notifyQueueITUnavailable: errorMessage];
         }
         else
         {
             [self enqueueRetryMonitor];
         }
     }];
}

-(void)enqueueRetryMonitor
{
    if (self.deltaSec < MAX_RETRY_SEC)
    {
        [self tryEnqueue];
        
        [NSThread sleepForTimeInterval:self.deltaSec];
        self.deltaSec = self.deltaSec * 2;
    }
    else
    {
        self.deltaSec = INITIAL_WAIT_RETRY_SEC;
        self.requestInProgress = NO;
        [self.queueITUnavailableDelegate notifyQueueITUnavailable: @"Unexpected error. Try again later"];
    }
}

-(NSString*)convertTtlMinutesToSecondsString:(int)ttlMinutes
{
    long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    int secondsToAdd = ttlMinutes * 60.0;
    long timeStapm = currentTime + secondsToAdd;
    NSString* urlTtlString = [NSString stringWithFormat:@"%li", timeStapm];
    return urlTtlString;
}

-(void) raiseQueuePassed:(NSString*) queueitToken
{
    QueuePassedInfo* queuePassedInfo = [[QueuePassedInfo alloc]initWithQueueitToken:queueitToken];
    
    NSLog(@"clearing the cache: RAISEQUEUEPASSED");
    [self.cache clear];
    
    self.isInQueue = NO;
    self.requestInProgress = NO;
    [self.queuePassedDelegate notifyYourTurn:queuePassedInfo];
}


-(void) raiseQueueViewWillOpen
{
    self.isInQueue = YES;
    [self.queueViewWillOpenDelegate notifyQueueViewWillOpen];
}

-(void) raiseQueueDisabled
{
    [self.queueDisabledDelegate notifyQueueDisabled];
}

-(void) raiseUserExited
{
    if (self.isInQueue) {
        [self.queueUserExitedDelegate notifyUserExited];
        self.isInQueue = NO;
    }
}

-(void)updateQueuePageUrl:(NSString *)queuePageUrl
{
    if (![self.cache isEmpty]) {
        NSString* urlTtlString = [self.cache getUrlTtl];
        NSString* targetUrl = [self.cache getTargetUrl];
        [self.cache update:queuePageUrl urlTTL:urlTtlString targetUrl:targetUrl];
    }
}

-(NSString*)queueURL {
    if (self.eventDomain != NULL && self.queueId != NULL && self.eventId != NULL) {
        NSString *sdkVersion = [IOSUtils getSdkVersion];
        NSString *urlFormat = @"http://%@/?c=%@&e=%@&q=%@&cid=%@&sdkv=%@";
        NSString *queueURL = [NSString stringWithFormat:urlFormat,self.eventDomain, self.customerId, self.eventId, self.queueId, self.language, sdkVersion];
        return queueURL;
    }
    return NULL;
}

@end
