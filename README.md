[![CocoaPods](https://img.shields.io/cocoapods/v/QueueITLibrary.svg)](https://cocoapods.org/pods/QueueITLibrary)

# Queue-It iOS WebUI SDK

Library for integrating Queue-It's virtual waiting room into an iOS app that is written in either objective-c or swift.

## Installation

Before starting please download the whitepaper **Mobile App Integration** from GO Queue-it Platform.
This whitepaper contains the needed information to perform a successful integration.

### Requirements

In version 2.12.X the QueueITEngine will switch on the installed version of iOS as the old UIWebView has been marked deprecated from iOS 12. If the iOS version is above version 10.0.0 the newer WKWebView will be used instead of UIWebView.

Therefore the minimum iOS version for 2.12.X is 8.3, where WKWebViews were introduced. In the same round we have removed the target limit for iPhone only, so the library can be used with iPads as well.

From version 2.13.0 the QueueITEngine no longer supports the UIWebView and will only use WKWebView. Furthermore, the lowest supported version of iOS has been updated to version 9.3.

Version 3.0.0 introduces breaking chances as the interface to `QueueITEngine` has been modified so the `run` function is using the NSError pattern to return errors instead of throwing a NSException.

From version 3.3.0 and alternative to run function of `QueueITEngine` has been added to allow for more control of the queueing experience. 
 
### XCFramework

You can manually add the XCFramework that's published in [releases](https://github.com/queueit/ios-webui-sdk/releases).

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
gem install cocoapods
```

To integrate the SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.3'
use_frameworks!

target '<Your Target Name>' do
    pod 'QueueITLibrary', '~> 3.0.3'
end
```

Then, run the following command:

```bash
pod install
```

## Usage
### QueueITEngine run function. 
Queue-it IOS SDK exposed a single function, run of `QueueITEngine`, as a mechanism for integration to Queue it and starting the web view. 

We have a repository with a demo app [here](https://github.com/queueit/ios-demo-app "iOS demo app"), but you can get the basic idea of how to use the library in the following example.

In this demo application we have a `UITableViewController` that we want to protect using Queue-it. The header file of `UIViewController` has following signature:

```objc
#import <UIKit/UIKit.h>
#import "QueueITEngine.h"

@interface TopsTableViewController : UITableViewController<QueuePassedDelegate, QueueViewWillOpenDelegate, QueueDisabledDelegate, QueueITUnavailableDelegate, QueueViewClosedDelegate, QueueSessionRestartDelegate>
-(void)initAndRunQueueIt;
@end
```

The QueueITEngine class will open a web view to display the queue found from parameters provided.

The implementation of the example controller looks like follows:

```objc
-(void)initAndRunQueueIt
{
    NSString* customerId = @"yourCustomerId"; // Required
    NSString* waitingRoomIdOrAlias = @"yourWaitingRoomIdOrAlias"; // Required
    NSString* layoutName = @"yourLayoutName"; // Optional (pass nil if no layout specified)
    NSString* language = @"en-US"; // Optional (pass nil if no language specified)

    self.engine = [[QueueITEngine alloc]initWithHost:self customerId:customerId eventOrAliasId:waitingRoomIdOrAlias layoutName:layoutName language:language];
    [self.engine setViewDelay:5]; // Optional delay parameter you can specify (in case you want to inject some animation before Queue-It UIWebView or WKWebView will appear
    self.engine.queuePassedDelegate = self; // Invoked once the user is passed the queue
    self.engine.queueViewWillOpenDelegate = self; // Invoked to notify that Queue-It UIWebView or WKWebview will open
    self.engine.queueDisabledDelegate = self; // Invoked to notify that queue is disabled
    self.engine.queueITUnavailableDelegate = self; // Invoked in case QueueIT is unavailable (500 errors)
    self.engine.queueUserExitedDelegate = self; // Invoked when user chooses to leave the queue
    self.engine.queueViewClosedDelegate = self; // Invoked after the WebView is closed
    self.engine.queueSessionRestartDelegate = self; // Invoked after user clicks on a link to restart the session. The link is 'queueit://restartSession'.
    
    NSError* error = nil;
    BOOL success = [self.engine run:&error];
    /**
    To enqueue with an enqueue-token or key use one of the following:

    [self.engine runWithEnqueueKey:@"keyValue" error:&error];
    [self.engine runWithEnqueueToken:@"tokenValue" error:&error];
    **/
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

// This callback will be called when the user has been through the queue.
// Here you should store session information, so user will only be sent to queue again if the session has timed out.
-(void) notifyYourTurn:(QueuePassedInfo*) queuePassedInfo {
    NSLog(@"You have been through the queue");
    NSLog(@"QUEUE TOKEN: %@", queuePassedInfo.queueitToken);
}

// This callback will be called just before the webview (hosting the queue page) will be shown.
// Here you can change some relevant UI elements.
-(void) notifyQueueViewWillOpen {
    NSLog(@"Queue will open");
}

// This callback will be called when the queue used (event alias ID) is in the 'disabled' state.
// Most likely the application should still function, but the queue's 'disabled' state can be changed at any time,
// so session handling is important.
-(void)notifyQueueDisabled:(QueueDisabledInfo* _Nullable) queueDisabledInfo {
    NSLog(@"Queue is disabled");
}

// This callback will be called when the mobile application can't reach Queue-it's servers.
// Most likely because the mobile device has no internet connection.
// Here you decide if the application should function or not now that is has no queue-it protection.
-(void) notifyQueueITUnavailable:(NSString*) errorMessage {
    NSLog(@"QueueIT is currently unavailable");
}

// This callback will be called after a user clicks a close link in the layout and the WebView closes.
// The close link is "queueit://close". Whenever the user navigates to this link, the SDK intercepts the navigation
// and closes the webview.
-(void)notifyViewClosed {
    NSLog(@"The queue view was closed.")
}

// This callback will be called when the user clicks on a link to restart the session.
// The link is 'queueit://restartSession'. Whenever the user navigates to this link, the SDK intercepts the navigation,
// closes the WebView, clears the URL cache and calls this callback.
// In this callback you would normally call run/runWithToken/runWithKey in order to restart the queueing.
-(void) notifySessionRestart {
    NSLog(@"Session was restarted");
    [self initAndRunQueueIt];
}
```

As the App developer you must manage the state (whether user was previously queued up or not) inside the apps storage.
After you have received the "notifyYourTurn callback", the app must remember this, possibly with a date / time expiration.
When the user wants to navigate to specific screen on the app which needs Queue-it protection, your code will check this state/saved variable, and only call SDK method QueueITEngine.run in the case the user did not previously queue up (or his session time expired). 
When the user clicks back, the same check needs to be done.

### Using QueueITWaitingRoomProvider and QueueITWaitingRoomView (From SDK version 3.3.0)

If you're using SDK version ```3.3.0``` or newer, it's possible to get finner control of application queueing logic using methods exposed by the new ```QueueITWaitingRoomProvider``` and ```QueueITWaitingRoomView``` instead of the single run function exposed by QueueITEngine. 

#### Verifying if user need to wait with QueueITWaitingRoomProvider
Using one of ```QueueITWaitingRoomProvider``` methods below, it is possible to check if the given end user needs to wait on the waiting room, or for example the waiting room status is on idle or safetynet modes and there is no need to wait / open the webview and show the waiting room.  
* ```TryPass```
* ```TryPassWithEnqueueToken``` 
* ```TryPassWithEnqueueKey```

Calling one of the above methods will trigger either the ```notifyProviderSuccess``` callback on success, or ```notifyProviderFailure``` callback on failure.

When using the ```notifyProviderQueueITUnavailable``` from the ```ProviderSuccessDelegate``` it'll provide with a ```QueueTryPassResult``` depending on the ```isPassThrough``` result:

* ```true``` means that the ```QueueItToken``` is *not* empty, and more information is available in the ```QueueTryPassResult```
* ```false``` means that the waiting room is *active*. You can show the visitor the waiting room by calling ```show``` from the ```QueueITWaitingRoomView```, by providing a ```queueUrl``` and ```targetUrl``` *([Read more about it here](#showing-the-queue-page-to-visitors))*

#### Showing the queue page to visitors with QueueITWaitingRoomView: 

The ```QueueITWaitingRoomView``` class is available to show the Waiting room on a webview.

When the waiting room is queueing visitors, each visitor has to visit it once. Using the ```show``` method you can do this, you have to provide the ```queueUrl```, and the ```targetUrl``` which is returned by the ```notifyProviderSuccess``` from ```QueueITWaitingRoomProvider``` class, given the waiting room is *active*. 


#### Sample code showing the queue page:
``` objc
-(void)notifyProviderSuccess:(QueueTryPassResult* _Nonnull) queuePassResult {   
   [self.waitingRoomView show:queuePassResult.queueUrl targetUrl:queuePassResult.targetUrl];
}
```

### Lifecycle diagram 
The following diagram shows a sample application logic using Queue it SDK, and denoting when the state of end user needs to be checked before calling QueueITEngine run function, to avoid queueing the same user more than once for a single use case. 
![App Integration Flow](https://github.com/queueit/ios-webui-sdk/blob/master/App%20integration%20flow.PNG "App Integration Flow")
