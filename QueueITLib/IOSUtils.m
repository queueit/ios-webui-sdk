#import <UIKit/UIKit.h>
#import "IOSUtils.h"

@implementation IOSUtils

+(NSString*)getUserId{
    UIDevice* device = [[UIDevice alloc]init];
    NSUUID* deviceid = [device identifierForVendor];
    NSString* uuid = [deviceid UUIDString];
    return uuid;
}

+(NSString*)getUserAgent{
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString* secretAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    return secretAgent;
}

+(NSString*)getLibraryVersion{
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[(NSString*)kCFBundleVersionKey];
    NSString *libName = infoDictionary[(NSString *)kCFBundleNameKey];
    NSString* libversion = [NSString stringWithFormat:@"%@-%@", libName, version];
    
    return libversion;
}


@end
