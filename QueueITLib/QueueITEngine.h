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
@property (nonatomic)id<QueuePassedDelegate> queuePassedDelegate;
@property (nonatomic)id<QueueViewWillOpenDelegate> queueViewWillOpenDelegate;
@property (nonatomic)id<QueueDisabledDelegate> queueDisabledDelegate;
@property (nonatomic)id<QueueITUnavailableDelegate> queueITUnavailableDelegate;
@property (nonatomic)id<QueueUserExitedDelegate> queueUserExitedDelegate;
@property (nonatomic)id<QueueViewClosedDelegate> queueViewClosedDelegate;
@property (nonatomic)id<QueueSessionRestartDelegate> queueSessionRestartDelegate;
@property (nonatomic, strong)NSString* errorMessage;

typedef enum {
    NetworkUnavailable = -100,
    RequestAlreadyInProgress = 10
} QueueITRuntimeError;
#define QueueITRuntimeErrorArray @"Network connection is unavailable", @"Enqueue request is already in progress", nil

-(instancetype)initWithHost:(UIViewController *)host
                 customerId:(NSString*)customerId
             eventOrAliasId:(NSString*)eventOrAliasId
                 layoutName:(NSString*)layoutName
                   language:(NSString*)language;

-(void)setViewDelay:(int)delayInterval;
-(BOOL)run:(NSError **)error;
-(BOOL)runWithEnqueueToken:(NSString*) enqueueToken
                     error:(NSError **) error;
-(BOOL)runWithEnqueueKey:(NSString*) enqueueKey
                   error:(NSError **) error;
-(BOOL)isUserInQueue;
-(BOOL)isRequestInProgress;
-(NSString*) errorTypeEnumToString:(QueueITRuntimeError)errorEnumVal;
-(void)updateQueuePageUrl:(NSString*)queuePageUrl;
-(void)raiseUserExited;
-(void)raiseViewClosed;
-(void)raiseSessionRestart;
-(void)raiseQueuePassed:(NSString*) queueitToken;
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
-(void)notifyQueueITUnavailable:(NSString *) errorMessage;
@end

@protocol QueueUserExitedDelegate <NSObject>
-(void)notifyUserExited;
@end

@protocol QueueViewClosedDelegate <NSObject>
-(void)notifyViewClosed;
@end
