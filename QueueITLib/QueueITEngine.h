#import <UIKit/UIKit.h>
#import "QueuePassedInfo.h"
#import "QueueConsts.h"

@protocol QueuePassedDelegate;
@protocol QueueViewWillOpenDelegate;
@protocol QueueDisabledDelegate;
@protocol QueueITUnavailableDelegate;
@protocol QueueUserExitedDelegate;
@protocol QueueViewClosedDelegate;
@protocol QueueSessionRestartDelegate;

@interface QueueITEngine : NSObject
@property (nonatomic)id<QueuePassedDelegate> _Nonnull queuePassedDelegate;
@property (nonatomic)id<QueueViewWillOpenDelegate> _Nullable queueViewWillOpenDelegate;
@property (nonatomic)id<QueueDisabledDelegate> _Nonnull queueDisabledDelegate;
@property (nonatomic)id<QueueITUnavailableDelegate> _Nullable queueITUnavailableDelegate;
@property (nonatomic)id<QueueUserExitedDelegate> _Nullable queueUserExitedDelegate;
@property (nonatomic)id<QueueViewClosedDelegate> _Nullable queueViewClosedDelegate;
@property (nonatomic)id<QueueSessionRestartDelegate> _Nullable queueSessionRestartDelegate;
@property (nonatomic, strong)NSString* _Nullable errorMessage;

typedef enum {
    NetworkUnavailable = -100,
    RequestAlreadyInProgress = 10
} QueueITRuntimeError;
#define QueueITRuntimeErrorArray @"Network connection is unavailable", @"Enqueue request is already in progress", nil

-(instancetype _Nonnull )initWithHost:(UIViewController* _Nonnull)host
                           customerId:(NSString* _Nonnull)customerId
                       eventOrAliasId:(NSString* _Nonnull)eventOrAliasId
                           layoutName:(NSString* _Nullable)layoutName
                             language:(NSString* _Nullable)language;

-(void)setViewDelay:(int)delayInterval;
-(BOOL)run:(NSError* _Nullable* _Nullable)error;
-(BOOL)runWithEnqueueToken:(NSString* _Nonnull) enqueueToken
                     error:(NSError* _Nullable*_Nullable) error;
-(BOOL)runWithEnqueueKey:(NSString* _Nonnull) enqueueKey
                   error:(NSError* _Nullable*_Nullable) error;
-(BOOL)isUserInQueue;
-(BOOL)isRequestInProgress;
-(NSString* _Nullable) errorTypeEnumToString:(QueueITRuntimeError)errorEnumVal;
-(void)updateQueuePageUrl:(NSString* _Nonnull)queuePageUrl;
-(void)raiseUserExited;
-(void)raiseViewClosed;
-(void)raiseSessionRestart;
-(void)raiseQueuePassed:(NSString* _Nullable) queueitToken;
-(void)close:(void (^ __nullable)(void))onComplete;
-(void)handleAppEnqueueResponse:(NSString* _Nullable) queueId
                       queueURL:(NSString* _Nullable) queueURL
           queueURLTTLInMinutes:(int) ttl
                 eventTargetURL:(NSString* _Nullable) targetURL
                   queueItToken:(NSString* _Nullable) token;

@end

@protocol QueuePassedDelegate <NSObject>
-(void)notifyYourTurn:(QueuePassedInfo* _Nullable) queuePassedInfo;
@end

@protocol QueueSessionRestartDelegate <NSObject>
-(void)notifySessionRestart;
@end

@protocol QueueViewWillOpenDelegate <NSObject>
-(void)notifyQueueViewWillOpen;
@end

@protocol QueueDisabledDelegate <NSObject>
-(void)notifyQueueDisabled;
@end

@protocol QueueITUnavailableDelegate <NSObject>
-(void)notifyQueueITUnavailable:(NSString* _Nonnull) errorMessage;
@end

@protocol QueueUserExitedDelegate <NSObject>
-(void)notifyUserExited;
@end

@protocol QueueViewClosedDelegate <NSObject>
-(void)notifyViewClosed;
@end
