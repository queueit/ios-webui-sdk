#import <Foundation/Foundation.h>
#import "QueueITWaitingRoomView.h"
#import "QueueITWKViewController.h"

@interface QueueITWaitingRoomView ()
@property (nonatomic, weak) UIViewController* host;
@property (nonatomic, weak) QueueITWKViewController* currentWebView;
@property NSString* customerId;
@property NSString* eventId;
@property int delayInterval;
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
    
    queueWKVC.delegate = self;
    
    if (@available(iOS 13.0, *)) {
        [queueWKVC setModalPresentationStyle: UIModalPresentationFullScreen];
    }
    if (self.delayInterval > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.host presentViewController:queueWKVC animated:YES completion:^{
                self.currentWebView = queueWKVC;
                [self.delegate notifyViewQueueDidAppear:self ];
            }];
        });
    } else {	
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.host presentViewController:queueWKVC animated:YES completion:^{
                self.currentWebView = queueWKVC;
                [self.delegate notifyViewQueueDidAppear:self ];
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
    [self.delegate notifyViewQueueWillOpen:self];
}

-(void)setViewDelay:(int)delayInterval {
    self.delayInterval = delayInterval;
}

-(void) notifyViewControllerUserExited {
    [self.delegate notifyViewUserExited:self];
}

-(void) notifyViewControllerClosed {
    [self.delegate notifyViewUserClosed:self];
}

-(void) notifyViewControllerSessionRestart {
    [self.delegate notifyViewSessionRestart:self];
}

-(void) notifyViewControllerQueuePassed:(NSString *)queueToken {
    QueuePassedInfo* queuePassedInfo = [[QueuePassedInfo alloc] initWithQueueitToken:queueToken];
    [self.delegate waitingRoomView:self notifyViewPassedQueue:queuePassedInfo];
}

-(void)notifyViewControllerPageUrlChanged:(NSString* _Nullable) urlString {
    [self.delegate waitingRoomView:self notifyViewUpdatePageUrl:urlString];
}

@end

