#import <Foundation/Foundation.h>

@interface Turn : NSObject

@property (nonatomic, strong) NSString* queueId;
@property (nonatomic, strong) NSString* customerId;
@property (nonatomic, strong) NSString* eventId;

-(instancetype)init:(NSString*)queueId;

@end
