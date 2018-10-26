#import "QueueITViewController.h"
#import "QueueITEngine.h"

@interface QueueITViewController ()<UIWebViewDelegate>

@property (nonatomic) UIWebView* webView;
@property (nonatomic, strong) UIViewController* host;
@property (nonatomic, strong) QueueITEngine* engine;
@property (nonatomic, strong)NSString* queueUrl;
@property (nonatomic, strong)NSString* eventTargetUrl;
@property (nonatomic, strong)UIActivityIndicatorView* spinner;
@property (nonatomic, strong)NSString* customerId;
@property (nonatomic, strong)NSString* eventId;
@property BOOL isQueuePassed;

@end

static NSString * const JAVASCRIPT_GET_BODY_CLASSES = @"document.getElementsByTagName(\"body\")[0].className";

@implementation QueueITViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated{
    self.spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.spinner setColor:[UIColor grayColor]];
    [self.spinner startAnimating];
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.view addSubview:self.webView];
    [self.webView addSubview:self.spinner];
    
    NSURL *urlAddress = [NSURL URLWithString:self.queueUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlAddress];
    [self.webView loadRequest:request];
    self.webView.delegate = self;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (!self.isQueuePassed) {
        NSString* urlString = [[request URL] absoluteString];
        NSString* targetUrlString = self.eventTargetUrl;
        
        if (urlString != nil) {
            NSURL* url = [NSURL URLWithString:urlString];
            NSURL* targetUrl = [NSURL URLWithString:targetUrlString];
            if(urlString != nil && ![urlString isEqualToString:@"about:blank"]) {
                BOOL isQueueUrl = [self.queueUrl containsString:url.host];
                BOOL isFrame = ![[[request URL] absoluteString] isEqualToString:[[request mainDocumentURL] absoluteString]];
                if (!isFrame) {
                    if (isQueueUrl) {
                        [self.engine updateQueuePageUrl:urlString];
                    }
                    if ([targetUrl.host containsString:url.host]) {
                        self.isQueuePassed = YES;
                        NSString* queueitToken = [self extractQueueToken:url.absoluteString];
                        [self.engine raiseQueuePassed:queueitToken];
                        [self.host dismissViewControllerAnimated:YES completion:^{
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        }];
                    }
                }
                if (navigationType == UIWebViewNavigationTypeLinkClicked && !isQueueUrl) {
                    [[UIApplication sharedApplication] openURL:[request URL]];
                    return NO;
                }
            }
        }
    }
    return YES;
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

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self.spinner stopAnimating];
    if (![self.webView isLoading])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }

    // Check if user exitted through the default exit link and notify the engine
    NSArray<NSString *> *htmlBodyClasses = [[self.webView stringByEvaluatingJavaScriptFromString:JAVASCRIPT_GET_BODY_CLASSES] componentsSeparatedByString:@" "];
    BOOL isExitClassPresent = [htmlBodyClasses containsObject:@"exit"];
    if (isExitClassPresent) {
        [self.engine raiseUserExited];
    }
}

-(void)appWillResignActive:(NSNotification*)note
{
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self.host dismissViewControllerAnimated:YES completion:^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

@end
