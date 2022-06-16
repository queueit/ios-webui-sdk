#import "QueueITEngine.h"
#import "QueueITApiClient.h"
#import "QueueStatus.h"
#import "IOSUtils.h"
#import "QueueCache.h"
#import "QueueITWaitingRoomView.h"
#import "QueueITWaitingRoomProvider.h"

@interface QueueITEngine()
@property (nonatomic, weak)UIViewController* host;
@property (nonatomic, weak)QueueCache* cache;

@property QueueITWaitingRoomProvider* waitingRoomProvider;
@property QueueITWaitingRoomView* waitingRoomView;
@end

@implementation QueueITEngine

-(instancetype)initWithHost:(UIViewController *)host customerId:(NSString*)customerId eventOrAliasId:(NSString*)eventOrAliasId layoutName:(NSString*)layoutName language:(NSString*)language
{
    self = [super init];
    if(self) {
        self.waitingRoomProvider = [[QueueITWaitingRoomProvider alloc] init:customerId
                                                                        eventOrAliasId:eventOrAliasId
                                                                        layoutName:layoutName
                                                                        language:language];
        
        self.waitingRoomView = [[QueueITWaitingRoomView alloc] initWithHost: host customerId: customerId eventId: eventOrAliasId];
        self.cache = [QueueCache instance:customerId eventId:eventOrAliasId];
        self.host = host;
        self.customerId = customerId;
        self.eventId = eventOrAliasId;
        self.layoutName = layoutName;
        self.language = language;
        
        self.waitingRoomView.viewUserExitedDelegate = self;
        self.waitingRoomView.viewUserClosedDelegate = self;
        self.waitingRoomView.viewSessionRestartDelegate = self;
        self.waitingRoomView.viewQueuePassedDelegate = self;
        self.waitingRoomView.viewQueueWillOpenDelegate = self;
        self.waitingRoomView.viewQueueUpdatePageUrlDelegate = self;
        self.waitingRoomView.viewQueueDidAppearDelegate = self;
        
        self.waitingRoomProvider.providerQueueDisabledDelegate = self;
        self.waitingRoomProvider.providerQueueITUnavailableDelegate = self;
        self.waitingRoomProvider.providerSuccessDelegate = self;
    }
    return self;
}

-(void)setViewDelay:(int)delayInterval {
    [self.waitingRoomView setViewDelay:delayInterval];
}

-(BOOL)isUserInQueue {
    return [self.waitingRoomView isUserInQueue];
}

-(BOOL)isRequestInProgress {
    return [self.waitingRoomProvider IsRequestInProgress];
}

-(BOOL)runWithEnqueueKey:(NSString *)enqueueKey
                   error:(NSError *__autoreleasing *)error
{
    return [self.waitingRoomProvider TryPassWithEnqueueKey:enqueueKey error:error];
}

-(BOOL)runWithEnqueueToken:(NSString *)enqueueToken
                     error:(NSError *__autoreleasing *)error
{
    return [self.waitingRoomProvider TryPassWithEnqueueToken:enqueueToken error:error];
}

-(BOOL)run:(NSError **)error
{
    if(![self tryShowQueueFromCache]) {
        return [self.waitingRoomProvider TryPass:error];
    }
    return YES;
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
    [self notifyViewQueueWillOpen];
    
    [self.waitingRoomView show:queueUrl targetUrl:targetUrl];
}

-(void)updateQueuePageUrl:(NSString *)queuePageUrl
{
    if (![self.cache isEmpty]) {
        NSString* urlTtlString = [self.cache getUrlTtl];
        NSString* targetUrl = [self.cache getTargetUrl];
        [self.cache update:queuePageUrl urlTTL:urlTtlString targetUrl:targetUrl];
    }
}

-(void)notifyViewUserExited {
    [self.queueUserExitedDelegate notifyUserExited];
}

- (void)notifyViewUserClosed {
    [self.queueViewClosedDelegate notifyViewClosed];
}

-(void)notifyViewSessionRestart {
    [self.cache clear];
    [self.queueSessionRestartDelegate notifySessionRestart];
}

-(void) notifyViewPassedQueue:(QueuePassedInfo *)queuePassedInfo {
    [self.cache clear];
    [self.queuePassedDelegate notifyYourTurn:queuePassedInfo];
}

-(void) notifyViewQueueDidAppear{
    [self.queueViewDidAppearDelegate notifyQueueViewDidAppear];
}

-(void) notifyViewQueueWillOpen {
    [self.queueViewWillOpenDelegate notifyQueueViewWillOpen];
}

-(void) notifyViewUpdatePageUrl:(NSString* _Nullable) urlString {
    [self updateQueuePageUrl:urlString];
}

-(void) notifyProviderQueueDisabled:(QueueDisabledInfo *)queueDisabledInfo {
    [self.queueDisabledDelegate notifyQueueDisabled:queueDisabledInfo];
}

-(void)notifyProviderQueueITUnavailable:(NSString* _Nonnull) errorMessage {
    [self.queueITUnavailableDelegate notifyQueueITUnavailable:errorMessage];
}

-(void)notifyProviderSuccess:(QueueTryPassResult* _Nonnull) queuePassResult {
    if([[queuePassResult redirectType]  isEqual: @"safetynet"])
    {
        QueuePassedInfo* queuePassedInfo = [[QueuePassedInfo alloc] initWithQueueitToken:queuePassResult.queueToken];
        [self.queuePassedDelegate notifyYourTurn:queuePassedInfo];
        return;
    }
    else if([[queuePassResult redirectType]  isEqual: @"disabled"])
    {
        QueueDisabledInfo* queueDisabledInfo = [[QueueDisabledInfo alloc]initWithQueueitToken:queuePassResult.queueToken];
        [self.queueDisabledDelegate notifyQueueDisabled:queueDisabledInfo];
        return;
    }
    
    [self showQueue:queuePassResult.queueUrl targetUrl:queuePassResult.targetUrl];
    [self.cache clear];
    [self.queueSuccessDelegate notifyQueueSuccess:queuePassResult];
}

@end
