#import "QueueStatus.h"

NSString * const KEY_QUEUE_ID = @"QueueId";
NSString * const KEY_QUEUE_URL = @"QueueUrl";
NSString * const KEY_EVENT_TARGET_URL = @"EventTargetUrl";
NSString * const KEY_QUEUEIT_TOKEN = @"QueueitToken";

@implementation QueueStatus

-(instancetype)init:(NSString *)queueId
           queueUrl:(NSString *)queueUrlString
     eventTargetUrl:(NSString *)eventTargetUrl
       queueitToken:(NSString *)queueitToken
{
    if(self = [super init]) {
        self.queueId = queueId;
        self.queueUrlString = queueUrlString;
        self.eventTargetUrl = eventTargetUrl;
        self.queueitToken = queueitToken;
    }

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *queueId;
    NSString *queueUrlString;
    NSString *eventTargetUrl;
    NSString *queueitToken;
    id value;
    

    value = dictionary[KEY_QUEUE_ID];
    if ([value isKindOfClass:[NSString class]]) {
        queueId = (NSString*)value;
    }

    value = dictionary[KEY_QUEUE_URL];
    if ([value isKindOfClass:[NSString class]]) {
        queueUrlString = (NSString*)value;
    }

    value = dictionary[KEY_EVENT_TARGET_URL];
    if ([value isKindOfClass:[NSString class]]) {
        eventTargetUrl = (NSString*)value;
    }

    value = dictionary[KEY_QUEUEIT_TOKEN];
    if ([value isKindOfClass:[NSString class]]) {
        queueitToken = (NSString*)value;
    }

    return [self init:queueId
             queueUrl:queueUrlString
       eventTargetUrl:eventTargetUrl
         queueitToken:queueitToken];
}
@end
