#import <WebKit/WebKit.h>
#import "QueueITEngine.h"

@interface QueueITWKViewController : UIViewController

@property (nonatomic, strong) UIImage *closeImage;

-(instancetype)initWithHost:(UIViewController*)host
                queueEngine:(QueueITEngine*) engine
                   queueUrl:(NSString*)queueUrl
             eventTargetUrl:(NSString*)eventTargetUrl
                 customerId:(NSString*)customerId
                    eventId:(NSString*)eventId;

@end
