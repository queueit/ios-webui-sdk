#import <WebKit/WebKit.h>
#import "QueueITEngine.h"

@interface QueueITWKViewController : UIViewController

-(instancetype _Nullable )initWithHost:(nonnull UIViewController *)host
                           queueEngine:(nonnull QueueITEngine*) engine
                              queueUrl:(nonnull NSString*)queueUrl
                        eventTargetUrl:(nonnull NSString*)eventTargetUrl
                            customerId:(nonnull NSString*)customerId
                               eventId:(nonnull NSString*)eventId;

- (void)close: (void (^ __nullable)(void))completion;

- (BOOL)handleSpecialUrls:(nonnull NSURL*) url
          decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler;

- (BOOL) isTargetUrl:(nonnull NSURL*) targetUrl
      destinationUrl:(nonnull NSURL*) destinationUrl;

- (BOOL) isBlockedUrl:(nonnull NSURL*) destinationUrl;

@end

