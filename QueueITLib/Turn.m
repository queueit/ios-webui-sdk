#import "Turn.h"

@implementation Turn

-(instancetype)init:(NSString*)queueId
{
    if (self = [super init]) {
        self.queueId =  queueId;
    }
    
    return self;
}

@end
