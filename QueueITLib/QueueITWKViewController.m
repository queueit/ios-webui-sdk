#import "QueueITWKViewController.h"
#import "QueueITEngine.h"

@interface QueueITWKViewController ()<WKNavigationDelegate>
@property (nonatomic) WKWebView* webView;
@property (nonatomic, strong) UIViewController* host;
@property (nonatomic, strong) QueueITEngine* engine;
@property (nonatomic, strong)NSString* queueUrl;
@property (nonatomic, strong)NSString* eventTargetUrl;
@property (nonatomic, strong)UIActivityIndicatorView* spinner;
@property (nonatomic, strong)NSString* customerId;
@property (nonatomic, strong)NSString* eventId;
@property BOOL isQueuePassed;
@end

static NSString * const JAVASCRIPT_GET_BODY_CLASSES = @"document.getElementsByTagName('body')[0].className";

@implementation QueueITWKViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

-(instancetype)initWithHost:(UIViewController *)host
                queueEngine:(QueueITEngine*) engine
                   queueUrl:(NSString*)queueUrl
             eventTargetUrl:(NSString*)eventTargetUrl
                 customerId:(NSString*)customerId
                    eventId:(NSString*)eventId
{
    self = [super init];
    if(self) {
        self.host = host;
        self.engine = engine;
        self.queueUrl = queueUrl;
        self.eventTargetUrl = eventTargetUrl;
        self.customerId = customerId;
        self.eventId = eventId;
        self.isQueuePassed = NO;
    }
    return self;
}

#pragma mark - Lifeycle

- (void)viewDidLoad{
    [super viewDidLoad];
    
    WKPreferences* preferences = [WKPreferences new];
    preferences.javaScriptEnabled = YES;
    WKWebViewConfiguration* config = [WKWebViewConfiguration new];
    config.preferences = preferences;
    CGFloat navigationBarOffset = [self setupNavigationBar];
    WKWebView* view = [[WKWebView alloc]initWithFrame:CGRectMake(0,
                                                                 navigationBarOffset,
                                                                 self.view.bounds.size.width,
                                                                 self.view.bounds.size.height - navigationBarOffset) configuration:config];
    view.navigationDelegate = self;
    self.webView = view;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.spinner setColor:[UIColor grayColor]];
    [self.spinner startAnimating];
    
    [self.view addSubview:self.webView];
    [self.webView addSubview:self.spinner];
    
    NSURL *urlAddress = [NSURL URLWithString:self.queueUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlAddress];
    [self.webView loadRequest:request];
}

#pragma mark - Navigation Bar

- (CGFloat)setupNavigationBar{
    CGFloat navigationBarHeight = 44.0;
    CGFloat statusBarHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
    CGFloat navigationBarDividerHeight = 1.0;
    CGFloat navigationBarOffset = navigationBarHeight + navigationBarDividerHeight + statusBarHeight;
    UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0,
                                                                                       statusBarHeight,
                                                                                       self.view.frame.size.width,
                                                                                       navigationBarHeight)];
    [navigationBar setBarTintColor:[UIColor whiteColor]];

    UINavigationItem* navigationItem = [UINavigationItem new];
    if (self.closeImage != nil) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:self.closeImage
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(dismissController)];
        navigationItem.leftBarButtonItem = closeButton;
    }
    [navigationBar setItems:@[navigationItem]];
    [self.view addSubview:navigationBar];
    self.view.backgroundColor = [UIColor whiteColor];
    return navigationBarOffset;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView*)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler{
    
    if (!self.isQueuePassed) {
        NSURLRequest* request = navigationAction.request;
        NSString* urlString = [[request URL] absoluteString];
        NSString* targetUrlString = self.eventTargetUrl;
        NSLog(@"request Url: %@", urlString);
        NSLog(@"target Url: %@", targetUrlString);
        if (urlString != nil) {
            NSURL* url = [NSURL URLWithString:urlString];
            NSURL* targetUrl = [NSURL URLWithString:targetUrlString];
            if(urlString != nil && ![urlString isEqualToString:@"about:blank"]) {
                BOOL isQueueUrl = [self.queueUrl containsString:url.host];
                BOOL isNotFrame = [[[request URL] absoluteString] isEqualToString:[[request mainDocumentURL] absoluteString]];
                if (isNotFrame) {
                    if (isQueueUrl) {
                        [self.engine updateQueuePageUrl:urlString];
                    }
                    if ([targetUrl.host isEqualToString:url.host] && [targetUrl.path isEqualToString:url.path]) {
                        self.isQueuePassed = YES;
                        NSString* queueitToken = [self extractQueueToken:url.absoluteString];
                        [self.engine raiseQueuePassed:queueitToken];
                        [self.host dismissViewControllerAnimated:YES completion:^{
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        }];
                    }
                }
                if (navigationAction.navigationType == WKNavigationTypeLinkActivated && !isQueueUrl) {
                    if (@available(iOS 10, *)){
                        [[UIApplication sharedApplication] openURL:[request URL] options:@{} completionHandler:nil];
                    }
                    else {
                        [[UIApplication sharedApplication] openURL:[request URL]];
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
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
                [self.engine raiseUserExited];
            }
        }
    }];
}

-(void)appWillResignActive:(NSNotification*)note{
}

#pragma mark - Actions
- (void)dismissController{
    [self.host dismissViewControllerAnimated:YES completion:^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}


@end
