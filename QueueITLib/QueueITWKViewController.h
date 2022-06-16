#import <WebKit/WebKit.h>

@protocol ViewControllerClosedDelegate;
@protocol ViewControllerUserExitedDelegate;
@protocol ViewControllerSessionRestartDelegate;
@protocol ViewControllerQueuePassedDelegate;
@protocol ViewControllerPageUrlChangedDelegate;

@interface QueueITWKViewController : UIViewController

@property (nonatomic, weak)id<ViewControllerClosedDelegate> _Nullable viewControllerClosedDelegate;
@property (nonatomic, weak)id<ViewControllerUserExitedDelegate> _Nullable viewControllerUserExitedDelegate;
@property (nonatomic, weak)id<ViewControllerSessionRestartDelegate> _Nullable viewControllerRestartDelegate;
@property (nonatomic, weak)id<ViewControllerQueuePassedDelegate> _Nullable viewControllerQueuePassedDelegate;
@property (nonatomic, weak)id<ViewControllerPageUrlChangedDelegate> _Nullable viewControllerPageUrlChangedDelegate;

-(instancetype _Nullable )initWithHost:(nonnull UIViewController *)host
                              queueUrl:(nonnull NSString*)queueUrl
                        eventTargetUrl:(nonnull NSString*)eventTargetUrl
                            customerId:(nonnull NSString*)customerId
                               eventId:(nonnull NSString*)eventId;

- (void) close:(void (^ __nullable)(void))completion;
- (BOOL) handleSpecialUrls:(nonnull NSURL*) url
           decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler;
- (BOOL) isTargetUrl:(nonnull NSURL*) targetUrl
      destinationUrl:(nonnull NSURL*) destinationUrl;
- (BOOL) isBlockedUrl:(nonnull NSURL*) destinationUrl;

@end

@protocol ViewControllerClosedDelegate <NSObject>
-(void)notifyViewControllerClosed;
@end

@protocol ViewControllerUserExitedDelegate <NSObject>
-(void)notifyViewControllerUserExited;
@end

@protocol ViewControllerSessionRestartDelegate <NSObject>
-(void)notifyViewControllerSessionRestart;
@end

@protocol ViewControllerQueuePassedDelegate <NSObject>
-(void)notifyViewControllerQueuePassed:(NSString* _Nullable) queueToken;
@end

@protocol ViewControllerPageUrlChangedDelegate <NSObject>
-(void)notifyViewControllerPageUrlChanged:(NSString* _Nullable) urlString;
@end
