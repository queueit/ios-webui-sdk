#import <Foundation/Foundation.h>
#import "QueueStatus.h"

typedef void (^QueueServiceSuccess)(NSData *data);
typedef void (^QueueServiceFailure)(NSError *error, NSString* errorMessage);

@interface QueueService : NSObject
+ (QueueService *)sharedInstance;

-(NSString*)enqueue:(NSString*)customerId
       encodedToken:(NSString*)encodedToken
     eventOrAliasId:(NSString*)eventorAliasId
             userId:(NSString*)userId
          userAgent:(NSString*)userAgent
         sdkVersion:(NSString*)sdkVersion
         layoutName:(NSString*)layoutName
           language:(NSString*)language
            success:(void(^)(QueueStatus* queueStatus))success
            failure:(QueueServiceFailure)failure;


@end
