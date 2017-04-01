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
                        [self.engine raiseQueuePassed];
                        [self.host dismissViewControllerAnimated:YES completion:nil];
                    } else if (navigationType == UIWebViewNavigationTypeLinkClicked && !isQueueUrl) {
                        [[UIApplication sharedApplication] openURL:[request URL]];
                        return NO;
                    }
                }
            }
        }
    }

    [self.engine.queueUrlChangesDelegate notifyWebViewShouldStartLoadRequestForUrl:[[request URL] absoluteString]];

    return YES;
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
}

-(void)appWillResignActive:(NSNotification*)note
{
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self.host dismissViewControllerAnimated:YES completion:nil];
}

@end
