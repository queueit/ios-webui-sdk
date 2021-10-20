#import <Foundation/Foundation.h>
#import "QueueConsts.h"

@interface IOSUtils : NSObject
+(NSString*)getUserId;
+(void)getUserAgent:(void (^)(NSString*))completionHandler;
+(NSString*)getLibraryVersion;
+(NSString*)getSdkVersion;
@end
