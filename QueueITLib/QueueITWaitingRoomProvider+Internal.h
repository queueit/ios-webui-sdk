#import "QueueITWaitingRoomProvider.h"

// Internal surface exposed for unit testing. Not part of the public API.
@interface QueueITWaitingRoomProvider (Internal)
-(BOOL)isNetworkAvailable;
-(BOOL)checkConnection:(NSError**)error;
-(void)startNetworkMonitor;
@property (atomic) BOOL networkPathDetermined;
@property (atomic) BOOL networkPathSatisfied;
@end
