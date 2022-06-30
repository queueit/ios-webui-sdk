#import "QueueITWaitingRoomView.h"
#import "QueueTryPassResult.h"

@protocol ProviderSuccessDelegate;
@protocol ProviderFailureDelegate;

@interface QueueITWaitingRoomProvider : NSObject

typedef enum {
    NetworkUnavailable = -100,
    RequestAlreadyInProgress = 10
} QueueITRuntimeError;
#define QueueITRuntimeErrorArray @"Network connection is unavailable", @"Enqueue request is already in progress", nil

@property (nonatomic, weak)id<ProviderSuccessDelegate> _Nullable providerSuccessDelegate;
@property (nonatomic, weak)id<ProviderFailureDelegate> _Nullable providerFailureDelegate;

-(instancetype _Nonnull)init:(NSString* _Nonnull)customerId
                       eventOrAliasId:(NSString* _Nonnull)eventOrAliasId
                           layoutName:(NSString* _Nullable)layoutName
                             language:(NSString* _Nullable)language;
 
-(BOOL)TryPass: (NSError* _Nullable*_Nullable)error;
-(BOOL)TryPassWithEnqueueToken:(NSString* _Nullable)enqueueToken
                         error:(NSError* _Nullable*_Nullable)error;
-(BOOL)TryPassWithEnqueueKey:(NSString* _Nullable)enqueueKey
                       error:(NSError* _Nullable*_Nullable)error;
-(BOOL)IsRequestInProgress;
@end

@protocol ProviderSuccessDelegate <NSObject>
-(void)notifyProviderSuccess:(QueueTryPassResult* _Nonnull) queuePassResult;
@end

@protocol ProviderFailureDelegate <NSObject>
-(void)notifyProviderFailure:(NSString* _Nullable)errorMessage
                   errorCode:(long)errorCode;
@end
