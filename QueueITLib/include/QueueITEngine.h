#import <UIKit/UIKit.h>
#import "QueuePassedInfo.h"

@protocol QueuePassedDelegate;
@protocol QueueViewWillOpenDelegate;
@protocol QueueDisabledDelegate;
@protocol QueueITUnavailableDelegate;
@protocol QueueUserExitedDelegate;

@interface QueueITEngine : NSObject
@property (nonatomic)id<QueuePassedDelegate> queuePassedDelegate;
@property (nonatomic)id<QueueViewWillOpenDelegate> queueViewWillOpenDelegate;
@property (nonatomic)id<QueueDisabledDelegate> queueDisabledDelegate;
@property (nonatomic)id<QueueITUnavailableDelegate> queueITUnavailableDelegate;
@property (nonatomic)id<QueueUserExitedDelegate> queueUserExitedDelegate;
@property (nonatomic, strong)NSString* errorMessage;
@property (nonatomic, strong)UIImage* closeImage;

typedef enum {
    NetworkUnavailable,
    RequestAlreadyInProgress
} QueueITRuntimeError;
#define QueueITRuntimeErrorArray @"Network connection is unavailable", @"Enqueue request is already in progress", nil

-(instancetype)initWithHost:(UIViewController*)host
                 customerId:(NSString*)customerId
             eventOrAliasId:(NSString*)eventOrAliasId
                 layoutName:(NSString*)layoutName
                   language:(NSString*)language
               encodedToken:(NSString*)encodedToken;

-(instancetype)initWithHost:(UIViewController *)host
                 customerId:(NSString*)customerId
             eventOrAliasId:(NSString*)eventOrAliasId
                eventDomain:(NSString*)eventDomain
                  targetURL:(NSString*)targetURL
                    queueId:(NSString*)queueId
                 layoutName:(NSString*)layoutName
                   language:(NSString*)language
               encodedToken:(NSString*)encodedToken;

-(void)setViewDelay:(int)delayInterval;
-(void)run;
-(void)raiseQueuePassed:(NSString*) queueitToken;
-(BOOL)isUserInQueue;
-(BOOL)isRequestInProgress;
-(NSString*) errorTypeEnumToString:(QueueITRuntimeError)errorEnumVal;
-(void)raiseUserExited;
-(void)updateQueuePageUrl:(NSString*)queuePageUrl;
@end

@protocol QueuePassedDelegate <NSObject>
-(void)notifyYourTurn:(QueuePassedInfo*) queuePassedInfo;
@end

@protocol QueueViewWillOpenDelegate <NSObject>
-(void)notifyQueueViewWillOpen;
-(void)notifyOnQueueIdChanged:(NSString*)queueId;
@end

@protocol QueueDisabledDelegate <NSObject>
-(void)notifyQueueDisabled;
@end

@protocol QueueITUnavailableDelegate <NSObject>
-(void)notifyQueueITUnavailable: (NSString *) errorMessage;
@end

@protocol QueueUserExitedDelegate <NSObject>
-(void)notifyUserExited;
@end
