#import "QueueStatus.h"

NSString * const KEY_QUEUE_ID = @"QueueId";
NSString * const KEY_QUEUE_URL = @"QueueUrl";
NSString * const KEY_EVENT_TARGET_URL = @"EventTargetUrl";
NSString * const KEY_QUEUE_URL_TTL_IN_MINUTES = @"QueueUrlTTLInMinutes";

@implementation QueueStatus

-(instancetype)init:(NSString *)queueId
           queueUrl:(NSString *)queueUrlString
     eventTargetUrl:(NSString *)eventTargetUrl
        queueUrlTTL:(int)queueUrlTTL
{
    if(self = [super init]) {
        self.queueId = queueId;
        self.queueUrlString = queueUrlString;
        self.eventTargetUrl = eventTargetUrl;
        self.queueUrlTTL = queueUrlTTL;
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    int queueUrlTTL = 0;
    if(![dictionary[KEY_QUEUE_URL_TTL_IN_MINUTES] isEqual:[NSNull null]])
    {
        queueUrlTTL = [dictionary[KEY_QUEUE_URL_TTL_IN_MINUTES] intValue];
    }
    
    return [self init:dictionary[KEY_QUEUE_ID]
             queueUrl:dictionary[KEY_QUEUE_URL]
       eventTargetUrl:dictionary[KEY_EVENT_TARGET_URL]
          queueUrlTTL:queueUrlTTL];
}

@end
