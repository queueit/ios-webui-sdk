#import <WebKit/WebKit.h>
#import "IOSUtils.h"

@implementation IOSUtils

WKWebView* webView;

+(NSString*)getUserId{
    UIDevice* device = [[UIDevice alloc]init];
    NSUUID* deviceid = [device identifierForVendor];
    NSString* uuid = [deviceid UUIDString];
    return uuid;
}

+(void)getUserAgent:(void (^)(NSString*))completionHandler{
    dispatch_async(dispatch_get_main_queue(), ^{
        WKWebView* view = [[WKWebView alloc] initWithFrame:CGRectZero];
        [view evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable userAgent, NSError * _Nullable error) {
            if (error == nil) {
                completionHandler(userAgent);
            }
            else {
                completionHandler(@"");
            }
            webView = nil;
        }];
        webView = view;
    });
}

+(NSString*)getLibraryVersion{
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];

    NSString *libName = infoDictionary[(NSString *)kCFBundleNameKey];
    NSString * major = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *minor = infoDictionary[(NSString*)kCFBundleVersionKey];
    NSString* libversion = [NSString stringWithFormat:@"%@-%@.%@", libName, major, minor];

    return libversion;
}

+(NSString*)getSdkVersion{
    return SDKVersion;
}

+(NSString*)convertTtlMinutesToSecondsString:(int)ttlMinutes
{
    long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    int secondsToAdd = ttlMinutes * 60.0;
    long timeStamp = currentTime + secondsToAdd;
    NSString* urlTtlString = [NSString stringWithFormat:@"%li", timeStamp];
    return urlTtlString;
}

@end
