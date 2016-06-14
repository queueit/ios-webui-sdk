# QueueIT.iOS.Lib
Library for integrating Queue-it sdk into an iOS app

Following is an example of using sdk:

In this example I have a UITableViewController that is using QueueIT sdk.  The header file of UIViewController has following signature:

#import <UIKit/UIKit.h>
#import "QueueITEngine.h"

@interface TopsTableViewController : UITableViewController<QueuePassedDelegate, QueueViewWillOpenDelegate, QueueDisabledDelegate, QueueITUnavailableDelegate>
-(void)initAndRunQueueIt;
@end

Then the implementation file of this controller has following code which configures and invokes sdk's api:

-(void)initAndRunQueueIt
{
    NSString* customerId = @"sasha"; //required
    NSString* eventAlias = @"3103i"; //required
    NSString* layoutName = @"mobileios"; //optional (pass nil if no layout specified)
    NSString* language = @"en-US"; //optional (pass nil if no language specified)
    
    self.engine = [[QueueITEngine alloc]initWithHost:self customerId:customerId eventOrAliasId:eventAlias layoutName:layoutName language:language];
    [self.engine setViewDelay:5]; //delay parameter you can specify (in case you want to inject some animation before QueueIT-UIWebView will appear
    self.engine.queuePassedDelegate = self; //invoked once the user is passed the queue
    self.engine.queueViewWillOpenDelegate = self; //invoked to notify that QueueIT-UIWebView will open
    self.engine.queueDisabledDelegate = self; //invoked to notify that queue is disabled
    self.engine.queueITUnavailableDelegate = self; //invoked in case QueueIT is unavailable (500 errors)
    
    @try
    {
        [self.engine run];
    }
    @catch (NSException *exception)
    {
        if ([exception reason] == [self.engine errorTypeEnumToString:NetworkUnavailable]) {
            //thrown when QueueIT detects no internet connectivity
        } else if ([exception reason] == [self.engine errorTypeEnumToString:RequestAlreadyInProgress]) {
           //thrown when request to QueueIT has already been made and currently in progress
        }
    }
}

-(void) notifyYourTurn { //callback for engine.queuePassedDelegate
    NSLog(@"You have been through the queue");
}

-(void) notifyQueueViewWillOpen { //callback for engine.queueViewWillOpenDelegate
    NSLog(@"Queue will open");
}

-(void) notifyQueueDisabled { //callback for engine.queueDisabledDelegate
    NSLog(@"Queue is disabled");
}

-(void) notifyQueueITUnavailable { //callback for engine.queueITUnavailableDelegate
    NSLog(@"QueueIT is currently unavailable");
}



