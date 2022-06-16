#import <UIKit/UIKit.h>
#import "QueuePassedInfo.h"
#import "QueueDisabledInfo.h"
#import "QueueTryPassResult.h"
#import "QueueConsts.h"
#import "QueueITWaitingRoomView.h"
#import "QueueITWaitingRoomProvider.h"

@protocol QueuePassedDelegate;
@protocol QueueViewWillOpenDelegate;
@protocol QueueViewDidAppearDelegate;
@protocol QueueDisabledDelegate;
@protocol QueueITUnavailableDelegate;
@protocol QueueUserExitedDelegate;
@protocol QueueViewClosedDelegate;
@protocol QueueSessionRestartDelegate;
@protocol QueueSuccessDelegate;

@interface QueueITEngine : NSObject<ViewUserExitedDelegate, ViewUserClosedDelegate, ViewSessionRestartDelegate, ViewQueuePassedDelegate, ViewQueueDidAppearDelegate, ViewQueueWillOpenDelegate, ViewQueueUpdatePageUrlDelegate, ProviderQueueDisabledDelegate, ProviderQueueITUnavailableDelegate, ProviderSuccessDelegate>

@property (nonatomic, weak)id<QueuePassedDelegate> _Nullable queuePassedDelegate;
@property (nonatomic, weak)id<QueueViewWillOpenDelegate> _Nullable queueViewWillOpenDelegate;
@property (nonatomic, weak)id<QueueViewDidAppearDelegate> _Nullable queueViewDidAppearDelegate;
@property (nonatomic, weak)id<QueueDisabledDelegate> _Nullable queueDisabledDelegate;
@property (nonatomic, weak)id<QueueITUnavailableDelegate> _Nullable queueITUnavailableDelegate;
@property (nonatomic, weak)id<QueueUserExitedDelegate> _Nullable queueUserExitedDelegate;
@property (nonatomic, weak)id<QueueViewClosedDelegate> _Nullable queueViewClosedDelegate;
@property (nonatomic, weak)id<QueueSessionRestartDelegate> _Nullable queueSessionRestartDelegate;
@property (nonatomic, weak)id<QueueSuccessDelegate> _Nullable queueSuccessDelegate;

@property (nonatomic, strong)NSString* _Nullable errorMessage;
@property (nonatomic, copy)NSString*  _Nonnull customerId;
@property (nonatomic, copy)NSString*  _Nonnull  eventId;
@property (nonatomic, copy)NSString*  _Nullable  layoutName;
@property (nonatomic, copy)NSString*  _Nullable  language;

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

@protocol QueueUserExitedDelegate <NSObject>
-(void)notifyUserExited;
@end

@protocol QueueViewClosedDelegate <NSObject>
-(void)notifyViewClosed;
@end

@protocol QueueDisabledDelegate <NSObject>
-(void)notifyQueueDisabled:(QueueDisabledInfo* _Nullable) queueDisabledInfo;
@end

@protocol QueueITUnavailableDelegate <NSObject>
-(void)notifyQueueITUnavailable:(NSString* _Nonnull) errorMessage;
@end

@protocol QueueSuccessDelegate <NSObject>
-(void)notifyQueueSuccess:(QueueTryPassResult* _Nullable) queuePassResult;
@end
