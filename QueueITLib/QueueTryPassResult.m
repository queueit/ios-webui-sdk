#import "QueueTryPassResult.h"


@implementation QueueTryPassResult

-(instancetype _Nonnull )
    initWithQueueUrl: (NSString* _Nullable) queueUrl
    targetUrl:(NSString* _Nonnull)targetUrl
    urlTTLInMinutes: (int) urlTTLInMinutes
    redirectType: (NSString* _Nonnull) redirectType
    isPassedThrough: (BOOL) isPassedThrough
    queueToken: (NSString* _Nullable) queueToken
{
    if(self = [super init]) {
        self.queueUrl = queueUrl;
        self.targetUrl = targetUrl;
        self.urlTTLInMinutes = urlTTLInMinutes;
        self.redirectType = redirectType;
        self.isPassedThrough = isPassedThrough;
    }
    
    return self;
}

@end
