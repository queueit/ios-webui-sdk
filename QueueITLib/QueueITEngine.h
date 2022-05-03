#import <UIKit/UIKit.h>
#import "QueuePassedInfo.h"
#import "QueueDisabledInfo.h"
#import "QueueConsts.h"

@protocol QueuePassedDelegate;
@protocol QueueViewWillOpenDelegate;
@protocol QueueViewDidAppearDelegate;
@protocol QueueDisabledDelegate;
@protocol QueueITUnavailableDelegate;
@protocol QueueUserExitedDelegate;
@protocol QueueViewClosedDelegate;
@protocol QueueSessionRestartDelegate;

@interface QueueITEngine : NSObject
@property (nonatomic, weak)id<QueuePassedDelegate> _Nullable queuePassedDelegate;
@property (nonatomic, weak)id<QueueViewWillOpenDelegate> _Nullable queueViewWillOpenDelegate;
@property (nonatomic, weak)id<QueueViewDidAppearDelegate> _Nullable queueViewDidAppearDelegate;
@property (nonatomic, weak)id<QueueDisabledDelegate> _Nullable queueDisabledDelegate;
@property (nonatomic, weak)id<QueueITUnavailableDelegate> _Nullable queueITUnavailableDelegate;
@property (nonatomic, weak)id<QueueUserExitedDelegate> _Nullable queueUserExitedDelegate;
@property (nonatomic, weak)id<QueueViewClosedDelegate> _Nullable queueViewClosedDelegate;
@property (nonatomic, weak)id<QueueSessionRestartDelegate> _Nullable queueSessionRestartDelegate;
@property (nonatomic, strong)NSString* _Nullable errorMessage;
@property (nonatomic, copy)NSString*  _Nonnull customerId;
@property (nonatomic, copy)NSString*  _Nonnull  eventId;
@property (nonatomic, copy)NSString*  _Nullable  layoutName;
@property (nonatomic, copy)NSString*  _Nullable  language;

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

@protocol QueueViewDidAppearDelegate <NSObject>
-(void)notifyQueueViewDidAppear;
@end

@protocol QueueDisabledDelegate <NSObject>
-(void)notifyQueueDisabled:(QueueDisabledInfo* _Nullable) queueDisabledInfo;
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
