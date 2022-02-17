#import "QueueDisabledInfo.h"

@implementation QueueDisabledInfo

-(instancetype)initWithQueueitToken:(NSString *)queueitToken
{
    if(self = [super init]) {
        self.queueitToken = queueitToken;
    }
    
    return self;
}

@end
