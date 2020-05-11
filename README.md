[![CocoaPods](https://img.shields.io/cocoapods/v/QueueITLibrary.svg)](https://cocoapods.org/pods/QueueITLibrary)

# Queue-It iOS WebUI SDK

Library for integrating Queue-It's virtual waiting room into an iOS app that is written in either objective-c or swift.

## Installation

### Requirements
In version 2.12.X the QueueITEngine will switch on the installed version of iOS as the old UIWebView has been marked deprecated from iOS 12. If the iOS version is above version 10.0.0 the newer WKWebView will be used instead of UIWebView.

Therefore the minimum iOS version for 2.12.X is 8.3, where WKWebViews were introduced. In the same round we have removed the target limit for iPhone only, so the library can be used with iPads as well.

From version 2.13.0 the QueueITEngine no longer supports the UIWebView and will only use WKWebView. Furthermore, the lowest supported version of iOS has been updated to version 9.3.

Version 3.0.0 introduces breaking chances as the interface to `QueueITEngine` has been modified so the `run` function is using the NSError pattern to return errors instead of throwing a NSException.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate the SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.3'
use_frameworks!

target '<Your Target Name>' do
    pod 'QueueITLibrary', '~> 3.0.0'
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage

We have a repository with a demo app [here](https://github.com/queueit/ios-demo-app "iOS demo app"), but you can get the basic idea of how to use the library in the following example.

In this example we have a `UITableViewController` that we want to protect using Queue-it. The header file of `UIViewController` has following signature:

```objc
#import <UIKit/UIKit.h>
#import "QueueITEngine.h"

@interface TopsTableViewController : UITableViewController<QueuePassedDelegate, QueueViewWillOpenDelegate, QueueDisabledDelegate, QueueITUnavailableDelegate>
-(void)initAndRunQueueIt;
@end
```

The QueueITEngine class will open a web view to display the queue found from parameters provided.

The implementation of the example controller looks like follows:

```objc
-(void)initAndRunQueueIt
{
    NSString* customerId = @"yourCustomerId"; // Required
    NSString* eventOrAliasId = @"yourEventId"; // Required
    NSString* layoutName = @"yourLayoutName"; // Optional (pass nil if no layout specified)
    NSString* language = @"en-US"; // Optional (pass nil if no language specified)
    
    self.engine = [[QueueITEngine alloc]initWithHost:self customerId:customerId eventOrAliasId:eventOrAliasId layoutName:layoutName language:language];
    [self.engine setViewDelay:5]; // Optional delay parameter you can specify (in case you want to inject some animation before Queue-It UIWebView or WKWebView will appear
    self.engine.queuePassedDelegate = self; // Invoked once the user is passed the queue
    self.engine.queueViewWillOpenDelegate = self; // Invoked to notify that Queue-It UIWebView or WKWebview will open
    self.engine.queueDisabledDelegate = self; // Invoked to notify that queue is disabled
    self.engine.queueITUnavailableDelegate = self; // Invoked in case QueueIT is unavailable (500 errors)
    self.engine.queueUserExitedDelegate = self; // Invoked when user chooses to leave the queue
    
    @try
    {
        NSError* error = nil;
        BOOL success = [self.engine run:&error];
        if (!success) {
            if ([error code] == NetworkUnavailable) {
                // Thrown when Queue-It detects no internet connectivity
                NSLog(@"%ld", (long)[error code]);
                NSLog(@"Network unavailable was caught in DetailsViewController");
                NSLog(@"isRequestInProgress - %@", self.engine.isRequestInProgress ? @"YES" : @"NO");
            }
            else if ([error code] == RequestAlreadyInProgress) {
                // Thrown when request to Queue-It has already been made and currently in progress. In general you can ignore this.
            }
            else {
                NSLog(@"Unknown error was returned by QueueITEngine in DetailsViewController");
            }
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception was caught in DetailsViewController");
    }
}

-(void) notifyYourTurn: (QueuePassedInfo*) queuePassedInfo { 
    // Callback for engine.queuePassedDelegate
    NSLog(@"You have been through the queue");
    NSLog(@"QUEUE TOKEN: %@", queuePassedInfo.queueitToken);
}

-(void) notifyQueueViewWillOpen { 
    // Callback for engine.queueViewWillOpenDelegate
    NSLog(@"Queue will open");
}

-(void) notifyQueueDisabled { 
    // Callback for engine.queueDisabledDelegate
    NSLog(@"Queue is disabled");
}

-(void) notifyQueueITUnavailable: (NSString*) errorMessage { 
    // Callback for engine.queueITUnavailableDelegate
    NSLog(@"QueueIT is currently unavailable");
}

-(void) notifyUserExited {
    // Callback for engine.queueUserExitedDelegate 
    NSLog(@"User has left the queue");
}
```
As the App developer you must manage the state (whether user was previously queued up or not) inside the apps storage.
After you have received the "On Queue Passed callback", the app must remember this, possibly with a date / time expiration.
When the user goes to the next page - you check this state, and only call QueueITEngine.run in the case where the user did not previously queue up.
When the user clicks back, the same check needs to be done.

![App Integration Flow](https://github.com/queueit/ios-webui-sdk/blob/master/App%20integration%20flow.PNG "App Integration Flow")
