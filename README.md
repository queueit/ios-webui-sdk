# QueueIT iOS SDK

Library for integrating Queue-it into an iOS app:

## Installation


### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate QueueIT iOS SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'QueueITLibrary', '~> 2.11.2'
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage

In this example we have a `UITableViewController` that we want to protect using Queue-it. The header file of `UIViewController` has following signature:

```objc
#import <UIKit/UIKit.h>
#import "QueueITEngine.h"

@interface TopsTableViewController : UITableViewController<QueuePassedDelegate, QueueViewWillOpenDelegate, QueueDisabledDelegate, QueueITUnavailableDelegate>
-(void)initAndRunQueueIt;
@end
```

The implementation of this controller looks like follows:

```objc
-(void)initAndRunQueueIt
{
    NSString* customerId = @"yourCustomerId"; //required
    NSString* eventOrAliasId = @"yourEventId"; //required
    NSString* layoutName = @"yourLayoutName"; //optional (pass nil if no layout specified)
    NSString* language = @"en-US"; //optional (pass nil if no language specified)
    
    self.engine = [[QueueITEngine alloc]initWithHost:self customerId:customerId eventOrAliasId:eventOrAliasId layoutName:layoutName language:language];
    [self.engine setViewDelay:5]; //delay parameter you can specify (in case you want to inject some animation before QueueIT-UIWebView will appear
    self.engine.queuePassedDelegate = self; //invoked once the user is passed the queue
    self.engine.queueViewWillOpenDelegate = self; //invoked to notify that QueueIT-UIWebView will open
    self.engine.queueDisabledDelegate = self; //invoked to notify that queue is disabled
    self.engine.queueITUnavailableDelegate = self; //invoked in case QueueIT is unavailable (500 errors)
    self.engine.queueUserExitedDelegate = self; //invoked when user chooses to leave the queue
    
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

-(void) notifyYourTurn: (QueuePassedInfo*) queuePassedInfo{ //callback for engine.queuePassedDelegate
    NSLog(@"You have been through the queue");
    NSLog(@"QUEUE TOKEN: %@", queuePassedInfo.queueitToken);
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

-(void) notifyUserExited {
    NSLog(@"User has left the queue");
}
```