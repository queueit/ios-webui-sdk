#import <UIKit/UIKit.h>

@protocol QueuePassedDelegate;
@protocol QueueViewWillOpenDelegate;
@protocol QueueDisabledDelegate;

@interface QueueITEngine : NSObject
@property (nonatomic)id<QueuePassedDelegate> queuePassedDelegate;
@property (nonatomic)id<QueueViewWillOpenDelegate> queueViewWillOpenDelegate;
@property (nonatomic)id<QueueDisabledDelegate> queueDisabledDelegate;
@property (nonatomic, strong)NSString* errorMessage;

typedef enum {
    NetworkUnavailable,
    RequestAlreadyInProgress
} QueueITRuntimeError;
#define QueueITRuntimeErrorArray @"Network connection is unavailable", @"Enqueue request is already in progress", nil

-(instancetype)initWithHost:(UIViewController *)host
                 customerId:(NSString*)customerId
             eventOrAliasId:(NSString*)eventOrAliasId
                 layoutName:(NSString*)layoutName
                   language:(NSString*)language;

-(void)setViewDelay:(int)delayInterval;
-(void)run;
-(void)raiseQueuePassed:(NSString *)queueId;
-(BOOL)isUserInQueue;
-(BOOL)isRequestInProgress;
-(NSString*) errorTypeEnumToString:(QueueITRuntimeError)errorEnumVal;

@end

@protocol QueuePassedDelegate <NSObject>
-(void)notifyYourTurn:(NSString*)queueId;
@end

@protocol QueueViewWillOpenDelegate <NSObject>
-(void)notifyQueueViewWillOpen;
@end

@protocol QueueDisabledDelegate <NSObject>
-(void)notifyQueueDisabled;
@end