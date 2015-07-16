#import "QueueStatus.h"

NSString * const KEY_QUEUE_ID = @"QueueId";
NSString * const KEY_QUEUE_URL = @"QueueUrl";
NSString * const KEY_REQUERY_INTERVAl = @"AskAgainInSeconds";
NSString * const KEY_ERROR_MESSAGE = @"ErrorMessage";
NSString * const KEY_ERROR_TYPE = @"ErrorType";
NSString * const KEY_QUEUE_URL_TTL_IN_MINUTES = @"QueueUrlTTLInMinutes";

@implementation QueueStatus

-(instancetype)init:(NSString *)queueId
           queueUrl:(NSString *)queueUrlString
    requeryInterval:(int)requeryInterval
       errorMessage:(NSString*)errorMessage
          errorType:(NSString*)errorType
        queueUrlTTL:(int)queueUrlTTL
{
    if(self = [super init]) {
        self.queueId = queueId;
        self.queueUrlString = queueUrlString;
        self.requeryInterval = requeryInterval;
        self.errorMessage = errorMessage;
        self.errorType = errorType;
        self.queueUrlTTL = queueUrlTTL;
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    int requeryInterval = 0;
    if(![dictionary[KEY_REQUERY_INTERVAl] isEqual:[NSNull null]])
    {
        requeryInterval = [dictionary[KEY_REQUERY_INTERVAl] intValue];
    }
    
    int queueUrlTTL = 0;
    if(![dictionary[KEY_QUEUE_URL_TTL_IN_MINUTES] isEqual:[NSNull null]])
    {
        queueUrlTTL = [dictionary[KEY_QUEUE_URL_TTL_IN_MINUTES] intValue];
    }
    
    return [self init:dictionary[KEY_QUEUE_ID]
             queueUrl:dictionary[KEY_QUEUE_URL]
      requeryInterval:requeryInterval
         errorMessage:dictionary[KEY_ERROR_MESSAGE]
            errorType:dictionary[KEY_ERROR_TYPE]
          queueUrlTTL:queueUrlTTL];
}

@end
