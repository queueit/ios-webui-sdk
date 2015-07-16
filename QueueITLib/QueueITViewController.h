#import <UIKit/UIKit.h>
#import "Turn.h"
#import "QueueITEngine.h"

@interface QueueITViewController : UIViewController

-(instancetype)initWithHost:(UIViewController *)host
                queueEngine:(QueueITEngine*) engine
                   queueUrl:(NSString*)queueUrl
                 customerId:(NSString*)customerId
                    eventId:(NSString*)eventId;

@end

