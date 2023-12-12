#import "QueueITWKViewController.h"
#import "QueueConsts.h"

@interface QueueITWKViewController ()<WKNavigationDelegate>
@property (nonatomic) WKWebView* webView;
@property (nonatomic, strong) UIViewController* host;

@property (nonatomic, strong)NSString* queueUrl;
@property (nonatomic, strong)NSString* eventTargetUrl;
@property (nonatomic, strong)UIActivityIndicatorView* spinner;
@property (nonatomic, strong)NSString* customerId;
@property (nonatomic, strong)NSString* eventId;
@property BOOL isQueuePassed;
@end

static NSString * const JAVASCRIPT_GET_BODY_CLASSES = @"document.getElementsByTagName('body')[0].className";

@implementation QueueITWKViewController

-(instancetype)initWithHost:(UIViewController *)host
                   queueUrl:(NSString*)queueUrl
             eventTargetUrl:(NSString*)eventTargetUrl
                 customerId:(NSString*)customerId
                    eventId:(NSString*)eventId
{
    self = [super init];
    if(self) {
        self.host = host;
        self.queueUrl = queueUrl;
        self.eventTargetUrl = eventTargetUrl;
        self.customerId = customerId;
        self.eventId = eventId;
        self.isQueuePassed = NO;
    }
    return self;
}

- (void)close:(void (^ __nullable)(void))onComplete {
    [self.host dismissViewControllerAnimated:YES completion:^{
        if(onComplete!=nil){
            onComplete();
        }
    }];
}

- (BOOL) isTargetUrl:(nonnull NSURL*) targetUrl
      destinationUrl:(nonnull NSURL*) destinationUrl {
    NSString* destinationHost = destinationUrl.host;
    NSString* destinationPath = destinationUrl.path;
    NSString* targetHost = targetUrl.host;
    NSString* targetPath = targetUrl.path;
    
    return [destinationHost isEqualToString: targetHost]
    && [destinationPath isEqualToString: targetPath];
}

- (BOOL) isBlockedUrl:(nonnull NSURL*) destinationUrl {
    NSString* path = destinationUrl.path;
    if([path hasPrefix: @"/what-is-this.html"]){
        return true;
    }
    return false;
}

- (BOOL)handleSpecialUrls:(NSURL*) url
          decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler {
    if([[url absoluteString] isEqualToString: QueueCloseUrl]){
        [self close: ^{
            [self.delegate notifyViewControllerClosed];
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
        return true;
    } else if ([[url absoluteString] isEqualToString: QueueRestartSessionUrl]){
        [self close:^{
            [self.delegate notifyViewControllerSessionRestart];
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
        return true;
    }
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.spinner = [[UIActivityIndicatorView alloc]initWithFrame:self.view.bounds];
    [self.spinner setColor:[UIColor grayColor]];
    
    WKPreferences* preferences = [[WKPreferences alloc]init];
    preferences.javaScriptEnabled = YES;
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc]init];
    config.preferences = preferences;
    WKWebView* webview = [[WKWebView alloc]initWithFrame:self.view.bounds configuration:config];
    webview.navigationDelegate = self;
    [webview setAutoresizingMask: UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    // Make webview transparent
    webview.opaque = NO;
    webview.backgroundColor = [UIColor clearColor];
    self.webView = webview;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self.spinner startAnimating];
    self.webView.frame = self.view.bounds;
    self.spinner.frame = self.view.bounds;
    
    [self.view addSubview:self.webView];
    [self.webView addSubview:self.spinner];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.queueUrl]]];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.webView removeFromSuperview];
    self.webView = nil;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView*)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler{
	    if (!self.isQueuePassed) {
        NSURLRequest* request = navigationAction.request;
        NSString* urlString = [[request URL] absoluteString];
        NSString* targetUrlString = self.eventTargetUrl;
        if (urlString != nil) {
            NSURL* url = [NSURL URLWithString:urlString];
            NSURL* targetUrl = [NSURL URLWithString:targetUrlString];
            if(urlString != nil && ![urlString isEqualToString:@"about:blank"]) {
                BOOL isQueueUrl = [self.queueUrl containsString:url.host];
                BOOL isNotFrame = [[[request URL] absoluteString] isEqualToString:[[request mainDocumentURL] absoluteString]];

                if([self handleSpecialUrls:url decisionHandler:decisionHandler]){
                    return;
                }

                if([self isBlockedUrl: url]){
                    decisionHandler(WKNavigationActionPolicyCancel);
                    return;
                }

                if (isNotFrame) {
                    if (isQueueUrl) {
                        [self raiseQueuePageUrl:urlString];
                    }
                    if ([self isTargetUrl: targetUrl
                           destinationUrl: url]) {
                        self.isQueuePassed = YES;
                        NSString* queueitToken = [self extractQueueToken:url.absoluteString];
                        [self.delegate notifyViewControllerQueuePassed:queueitToken];
                        [self.host dismissViewControllerAnimated:YES completion:^{
                        }];
                        decisionHandler(WKNavigationActionPolicyCancel);
                        return;
                    }
                }
                if (navigationAction.navigationType == WKNavigationTypeLinkActivated && !isQueueUrl) {
                    if (@available(iOS 10, *)){
                        [[UIApplication sharedApplication] openURL:[request URL] options:@{} completionHandler:^(BOOL success){

                        }];
                    }
                    else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                        [[UIApplication sharedApplication] openURL:[request URL]];
#pragma GCC diagnostic pop
                    }

                    decisionHandler(WKNavigationActionPolicyCancel);
                    return;
                }
            }
	        }
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

- (NSString*)extractQueueToken:(NSString*) url {
    NSString* tokenKey = @"queueittoken=";
    if ([url containsString:tokenKey]) {
        NSString* token = [url substringFromIndex:NSMaxRange([url rangeOfString:tokenKey])];
        if([token containsString:@"&"]) {
            token = [token substringToIndex:NSMaxRange([token rangeOfString:@"&"]) - 1];
        }
        return token;
    }
    return nil;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self.spinner stopAnimating];
    if (![self.webView isLoading])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    
    // Check if user exitted through the default exit link and notify the engine
    [self.webView evaluateJavaScript:JAVASCRIPT_GET_BODY_CLASSES completionHandler:^(id result, NSError* error){
        if (error != nil) {
            NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
        }
        else {
            NSString* resultString = [NSString stringWithFormat:@"%@", result];
            NSArray<NSString *> *htmlBodyClasses = [resultString componentsSeparatedByString:@" "];
            BOOL isExitClassPresent = [htmlBodyClasses containsObject:@"exit"];
            if (isExitClassPresent) {
                [self.delegate notifyViewControllerUserExited];
            }
        }
    }];
}

- (void)raiseQueuePageUrl:(NSString *)urlString {
    [self.delegate notifyViewControllerPageUrlChanged:urlString];
}

-(void)appWillResignActive:(NSNotification*)note
{
}

@end
