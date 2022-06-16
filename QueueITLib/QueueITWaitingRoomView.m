#import <Foundation/Foundation.h>
#import "QueueITWaitingRoomView.h"
#import "QueueITWKViewController.h"

@interface QueueITWaitingRoomView ()
@property (nonatomic, weak) UIViewController* host;
@property (nonatomic, weak) QueueITWKViewController* currentWebView;
@property NSString* customerId;
@property NSString* eventId;
@property int delayInterval;
@property BOOL isInQueue;
@end

@implementation QueueITWaitingRoomView

-(instancetype _Nonnull)initWithHost:(UIViewController *)host
                        customerId: (NSString* _Nonnull) customerId
                        eventId: (NSString * _Nonnull)eventId
                        
{
    if(self = [super init]) {
        self.host = host;
        self.customerId = customerId;
        self.eventId = eventId;
    }
    
    return self;
}

-(void) show:(NSString* _Nonnull)queueUrl targetUrl:(NSString* _Nonnull)targetUrl
{
    [self raiseQueueViewWillOpen];
    
    QueueITWKViewController *queueWKVC = [[QueueITWKViewController alloc] initWithHost:self.host
                                                                          queueUrl:queueUrl
                                                                          eventTargetUrl:targetUrl
                                                                          customerId:self.customerId
                                                                            eventId:self.eventId];
    
    queueWKVC.viewControllerClosedDelegate = self;
    queueWKVC.viewControllerUserExitedDelegate = self;
    queueWKVC.viewControllerRestartDelegate = self;
    queueWKVC.viewControllerQueuePassedDelegate = self;
    queueWKVC.viewControllerPageUrlChangedDelegate = self;
    
    if (@available(iOS 13.0, *)) {
        [queueWKVC setModalPresentationStyle: UIModalPresentationFullScreen];
    }
    if (self.delayInterval > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.host presentViewController:queueWKVC animated:YES completion:^{
                self.currentWebView = queueWKVC;
                self.isInQueue = YES;
                [self.viewQueueDidAppearDelegate notifyViewQueueDidAppear ];
            }];
        });
    } else {	
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.host presentViewController:queueWKVC animated:YES completion:^{
                self.currentWebView = queueWKVC;
                [self.viewQueueDidAppearDelegate notifyViewQueueDidAppear ];
            }];
        });
    }
}

-(void)close:(void (^ __nullable)(void))onComplete
{
    if(self.currentWebView!=nil){
        dispatch_async(dispatch_get_main_queue(), ^{
           [self.currentWebView close: onComplete];
        });
    }
}

- (void)raiseQueueViewWillOpen {
    [self.viewQueueWillOpenDelegate notifyViewQueueWillOpen];
}

-(void)setViewDelay:(int)delayInterval {
    self.delayInterval = delayInterval;
}

-(BOOL)isUserInQueue {
    return self.isInQueue;
}

-(void) notifyViewControllerUserExited {
    if (self.isInQueue) {
        [self.viewUserExitedDelegate notifyViewUserExited];
        self.isInQueue = NO;
    }
}

-(void) notifyViewControllerClosed {
    [self.viewUserClosedDelegate notifyViewUserClosed];
}

-(void) notifyViewControllerSessionRestart {
    [self.viewSessionRestartDelegate notifyViewSessionRestart];
}

-(void) notifyViewControllerQueuePassed:(NSString *)queueToken {
    self.isInQueue = NO;
    
    QueuePassedInfo* queuePassedInfo = [[QueuePassedInfo alloc] initWithQueueitToken:queueToken];
    [self.viewQueuePassedDelegate notifyViewPassedQueue:queuePassedInfo];
}

-(void)notifyViewControllerPageUrlChanged:(NSString* _Nullable) urlString {
    [self.viewQueueUpdatePageUrlDelegate notifyViewUpdatePageUrl:urlString];
}

@end

