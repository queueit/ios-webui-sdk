#import <Foundation/Foundation.h>

@interface QueueTryPassResult : NSObject

@property (nonatomic, strong) NSString* _Nonnull queueUrl;
@property (nonatomic, strong) NSString* _Nonnull targetUrl;
@property (nonatomic) int urlTTLInMinutes;
@property (nonatomic, strong) NSString* _Nonnull redirectType;
@property (nonatomic) BOOL isPassedThrough;
@property (nonatomic) NSString* _Nullable queueToken;


-(instancetype _Nonnull )
    initWithQueueUrl: (NSString* _Nullable) queueUrl
    targetUrl:(NSString* _Nonnull)targetUrl
    urlTTLInMinutes: (int) urlTTLInMinutes
    redirectType: (NSString* _Nonnull) redirectType
    isPassedThrough: (BOOL) isPassedThrough
    queueToken: (NSString* _Nullable) queueToken;

@end
