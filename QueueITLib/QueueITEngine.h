#import <UIKit/UIKit.h>
#import "QueuePassedInfo.h"
#import "QueueConsts.h"

@protocol QueuePassedDelegate;
@protocol QueueViewWillOpenDelegate;
@protocol QueueDisabledDelegate;
@protocol QueueITUnavailableDelegate;
@protocol QueueUserExitedDelegate;
@protocol QueueViewClosedDelegate;

@interface QueueITEngine : NSObject
@property (nonatomic)id<QueuePassedDelegate> queuePassedDelegate;
@property (nonatomic)id<QueueViewWillOpenDelegate> queueViewWillOpenDelegate;
@property (nonatomic)id<QueueDisabledDelegate> queueDisabledDelegate;
@property (nonatomic)id<QueueITUnavailableDelegate> queueITUnavailableDelegate;
@property (nonatomic)id<QueueUserExitedDelegate> queueUserExitedDelegate;
@property (nonatomic)id<QueueViewClosedDelegate> queueViewClosedDelegate;
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
-(void)raiseQueuePassed:(NSString*) queueitToken;
-(BOOL)isUserInQueue;
-(BOOL)isRequestInProgress;
-(NSString*) errorTypeEnumToString:(QueueITRuntimeError)errorEnumVal;
-(void)raiseUserExited;
-(void)updateQueuePageUrl:(NSString*)queuePageUrl;
-(void)raiseViewClosed;
-(void)close: (void (^ __nullable)(void))onComplete;
-(void)handleAppEnqueueResponse:(NSString*) queueId
                       queueURL:(NSString*) queueURL
           queueURLTTLInMinutes:(int) ttl
                 eventTargetURL:(NSString*) targetURL
                   queueItToken:(NSString*) token;

@end

@protocol QueuePassedDelegate <NSObject>
-(void)notifyYourTurn:(QueuePassedInfo*) queuePassedInfo;
@end

@protocol QueueViewWillOpenDelegate <NSObject>
-(void)notifyQueueViewWillOpen;
@end

@protocol QueueDisabledDelegate <NSObject>
-(void)notifyQueueDisabled;
@end

@protocol QueueITUnavailableDelegate <NSObject>
-(void)notifyQueueITUnavailable: (NSString *) errorMessage;
@end

@protocol QueueUserExitedDelegate <NSObject>
-(void)notifyUserExited;
@end

@protocol QueueViewClosedDelegate <NSObject>
-(void)notifyViewClosed;
@end
