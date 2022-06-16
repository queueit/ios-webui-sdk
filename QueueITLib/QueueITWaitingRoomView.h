#import "QueueITWKViewController.h"
#import "QueueDisabledInfo.h"
#import "QueuePassedInfo.h"

@protocol ViewQueuePassedDelegate;
@protocol ViewQueueWillOpenDelegate;
@protocol ViewUserClosedDelegate;
@protocol ViewUserExitedDelegate;
@protocol ViewSessionRestartDelegate;
@protocol ViewQueueUpdatePageUrlDelegate;
@protocol ViewQueueDidAppearDelegate;

@interface QueueITWaitingRoomView : NSObject<ViewControllerSessionRestartDelegate, ViewControllerUserExitedDelegate, ViewControllerClosedDelegate, ViewControllerQueuePassedDelegate, ViewControllerPageUrlChangedDelegate>

@property (nonatomic, weak)id<ViewUserExitedDelegate> _Nullable viewUserExitedDelegate;
@property (nonatomic, weak)id<ViewUserClosedDelegate> _Nullable viewUserClosedDelegate;
@property (nonatomic, weak)id<ViewSessionRestartDelegate> _Nullable viewSessionRestartDelegate;
@property (nonatomic, weak)id<ViewQueuePassedDelegate> _Nullable viewQueuePassedDelegate;
@property (nonatomic, weak)id<ViewQueueDidAppearDelegate> _Nullable viewQueueDidAppearDelegate;
@property (nonatomic, weak)id<ViewQueueWillOpenDelegate> _Nullable viewQueueWillOpenDelegate;
@property (nonatomic, weak)id<ViewQueueUpdatePageUrlDelegate> _Nullable viewQueueUpdatePageUrlDelegate;

-(instancetype _Nonnull)initWithHost:(UIViewController* _Nonnull)host
                        customerId: (NSString* _Nonnull)customerId
                        eventId: (NSString* _Nonnull)eventId;

-(void)show:(NSString* _Nonnull)queueUrl targetUrl:(NSString* _Nonnull)targetUrl;
-(void)setViewDelay:(int)delayInterval;
-(BOOL)isUserInQueue;
-(void)close:(void (^ __nullable)(void))onComplete;

@end

@protocol ViewUserExitedDelegate <NSObject>
-(void) notifyViewUserExited;
@end

@protocol ViewUserClosedDelegate <NSObject>
-(void) notifyViewUserClosed;
@end

@protocol ViewSessionRestartDelegate <NSObject>
-(void) notifyViewSessionRestart;
@end

@protocol ViewQueuePassedDelegate <NSObject>
-(void) notifyViewPassedQueue:(QueuePassedInfo* _Nullable)queuePassedInfo;
@end

@protocol ViewQueueDidAppearDelegate <NSObject>
-(void) notifyViewQueueDidAppear;
@end

@protocol ViewQueueWillOpenDelegate <NSObject>
-(void) notifyViewQueueWillOpen;
@end

@protocol ViewQueueUpdatePageUrlDelegate <NSObject>
-(void) notifyViewUpdatePageUrl:(NSString* _Nullable) urlString;
@end
