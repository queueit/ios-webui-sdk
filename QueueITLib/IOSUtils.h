#import <Foundation/Foundation.h>

@interface IOSUtils : NSObject
+(NSString*)getUserId;
+(NSString*)getUserAgent;
+(NSString*)getLibraryVersion;
+(NSString*)getSdkVersion;
@end
