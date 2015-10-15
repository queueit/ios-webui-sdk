#import <UIKit/UIKit.h>
#import "QueueITEngine.h"
#import "QueueITViewController.h"
#import "QueueService.h"
#import "QueueStatus.h"
#import "IOSUtils.h"
#import "Reachability.h"

@interface QueueITEngine()
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic, strong)UIViewController* host;
@property (nonatomic, strong)NSString* customerId;
@property (nonatomic, strong)NSString* eventId;
@property (nonatomic, strong)NSString* layoutName;
@property (nonatomic, strong)NSString* language;
@property int delayInterval;
@property bool isInQueue;
@property bool isRequestInProgress;
@end

@implementation QueueITEngine

-(instancetype)initWithHost:(UIViewController *)host customerId:(NSString*)customerId eventOrAliasId:(NSString*)eventOrAliasId layoutName:(NSString*)layoutName language:(NSString*)language
{
    self = [super init];
    if(self) {
        self.host = host;
        self.customerId = customerId;
        self.eventId = eventOrAliasId;
        self.layoutName = layoutName;
        self.language = language;
        self.delayInterval = 0;
        self.isInQueue = NO;
        self.isRequestInProgress = NO;
        self.internetReachability = [Reachability reachabilityForInternetConnection];
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
    @throw [NSException exceptionWithName:@"QueueITRuntimeException" reason:@"Network connection is unavailable" userInfo:nil];
}



-(BOOL)isUserInQueue {
    return self.isInQueue;
}

-(void)run
{
    if(self.isRequestInProgress)
    {
        @throw [NSException exceptionWithName:@"QueueITRuntimeException" reason:@"Equeue request was already in progress" userInfo:nil];
    }
    
    [self checkConnection];
    
    NSString * key = [NSString stringWithFormat:@"%@-%@",self.customerId, self.eventId];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* url2TTL = [defaults dictionaryForKey:key];
    
    self.isRequestInProgress = YES;
    
    if (url2TTL)
    {
        long long cachedTime = [[[url2TTL allValues] objectAtIndex:0] longLongValue];
        long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
        
        if (currentTime < cachedTime)
        {
            NSString* queueUrlCached = [[url2TTL allKeys] objectAtIndex:0];
            [self showQueue:self.host queueUrl:queueUrlCached customerId:self.customerId eventId:self.eventId];
        }
        else
        {
            [self tryEnqueue:self.host customerId:self.customerId eventOrAliasId:self.eventId layoutName:self.layoutName language:self.language];
        }
    }
    else
    {
        [self tryEnqueue:self.host customerId:self.customerId eventOrAliasId:self.eventId layoutName:self.layoutName language:self.language];
    }
}

-(void)showQueue:(UIViewController*)host queueUrl:(NSString*)queueUrl customerId:(NSString*)customerId eventId:(NSString*)eventId
{
    [self raiseQueueViewWillOpen];
    QueueITViewController *queueVC = [[QueueITViewController alloc] initWithHost:host
                                                                     queueEngine:self
                                                                        queueUrl:queueUrl
                                                                      customerId:customerId eventId:eventId];
    
    if (self.delayInterval > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [host presentViewController:queueVC animated:YES completion:nil];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [host presentViewController:queueVC animated:YES completion:nil];
        });
    }
}

-(void)tryEnqueue:(UIViewController *)host customerId:(NSString*)customerId eventOrAliasId:(NSString*)eventOrAliasId layoutName:(NSString*)layoutName language:(NSString*)language
{
    NSString* userId = [IOSUtils getUserId];
    NSString* userAgent = [NSString stringWithFormat:@"%@;%@", [IOSUtils getUserAgent], [IOSUtils getLibraryVersion]];
    NSString* appType = @"iOS";
    
    QueueService* qs = [QueueService sharedInstance];
    [qs enqueue:customerId
 eventOrAliasId:eventOrAliasId
         userId:userId userAgent:userAgent
        appType:appType
     layoutName:layoutName
       language:language
        success:^(QueueStatus *queueStatus)
     {
         if (queueStatus.errorType != (id)[NSNull null])
         {
             self.isRequestInProgress = NO;
             [self handleServerError:queueStatus.errorType errorMessage:queueStatus.errorMessage];
         }
         //SafetyNet
         if (queueStatus.queueId != (id)[NSNull null] && queueStatus.queueUrlString == (id)[NSNull null] && queueStatus.requeryInterval == 0)
         {
             self.isRequestInProgress = NO;
         }
         //InQueue
         else if (queueStatus.queueId != (id)[NSNull null] && queueStatus.queueUrlString != (id)[NSNull null] && queueStatus.requeryInterval == 0)
         {
             [self showQueue:host queueUrl:queueStatus.queueUrlString customerId:customerId eventId:eventOrAliasId];
             [self updateCache:queueStatus.queueUrlString urlTTL:queueStatus.queueUrlTTL customerId:customerId eventId:eventOrAliasId];
         }
         //Idle
         else if (queueStatus.queueId == (id)[NSNull null] && queueStatus.queueUrlString != (id)[NSNull null] && queueStatus.requeryInterval == 0)
         {
             [self showQueue:host queueUrl:queueStatus.queueUrlString customerId:customerId eventId:eventOrAliasId];
         }
         //Disabled
         else if (queueStatus.requeryInterval > 0)
         {
             self.isRequestInProgress = NO;
             [self raiseQueueDisabled];
         }
     }
        failure:^(NSError *error)
     {
         self.isRequestInProgress = NO;
         @throw [NSException exceptionWithName:@"QueueITUnexpectedException" reason:[NSString stringWithFormat:@"%@", error.description] userInfo:nil];
     }];
}

-(void)handleServerError:(NSString*)errorType errorMessage:(NSString*)errorMessage
{
    if ([errorType isEqualToString:@"Configuration"])
    {
        @throw [NSException exceptionWithName:@"QueueITConfigurationException" reason:errorMessage userInfo:nil];
    }
    else if ([errorType isEqualToString:@"Runtime"])
    {
        @throw [NSException exceptionWithName:@"QueueITUnexpectedException" reason:errorMessage userInfo:nil];
    }
    else if ([errorType isEqualToString:@"Validation"])
    {
        @throw [NSException exceptionWithName:@"QueueITUnexpectedException" reason:errorMessage userInfo:nil];
    }
}

-(void)updateCache:(NSString*)queueUrl urlTTL:(int)queueUrlTTL customerId:(NSString*)customerId eventId:(NSString*)eventId
{
    long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    int secondsToAdd = queueUrlTTL * 60.0;
    long timeStapm = currentTime + secondsToAdd;
    
    NSString* urlTtlString = [NSString stringWithFormat:@"%li", timeStapm];
    NSMutableDictionary* url2TTL = [[NSMutableDictionary alloc] init];
    [url2TTL setObject:urlTtlString forKey:queueUrl];
    
    NSString* key = [NSString stringWithFormat:@"%@-%@",customerId, eventId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:url2TTL forKey:key];
    [defaults synchronize];
}

-(void) raiseQueuePassed:(NSString *)queueId
{
    NSString * key = [NSString stringWithFormat:@"%@-%@", self.customerId, self.eventId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    
    self.isInQueue = NO;
    self.isRequestInProgress = NO;
    [self.queuePassedDelegate notifyYourTurn:queueId];
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

@end