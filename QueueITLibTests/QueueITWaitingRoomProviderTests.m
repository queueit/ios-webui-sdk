#import <XCTest/XCTest.h>
#import "QueueITWaitingRoomProvider.h"
#import "QueueITWaitingRoomProvider+Internal.h"

// Subclass that forces a deterministic network-availability answer so the
// connectivity path can be tested without a real network.
@interface StubProvider : QueueITWaitingRoomProvider
@property (nonatomic) BOOL stubAvailable;
@end

@implementation StubProvider
-(BOOL)isNetworkAvailable { return self.stubAvailable; }
@end

// Subclass that skips the live NWPathMonitor so the real isNetworkAvailable
// decision logic can be driven deterministically via networkPath* state.
@interface NoMonitorProvider : QueueITWaitingRoomProvider
@end

@implementation NoMonitorProvider
-(void)startNetworkMonitor { /* no-op: no live monitor in tests */ }
@end

@interface QueueITWaitingRoomProviderTests : XCTestCase
@end

@implementation QueueITWaitingRoomProviderTests

- (StubProvider *)makeProviderAvailable:(BOOL)available {
    StubProvider *p = [[StubProvider alloc] initWithCustomerId:@"customer"
                                                eventOrAliasId:@"event"
                                                    layoutName:nil
                                                      language:nil
                                             waitingRoomDomain:nil
                                               queuePathPrefix:nil];
    p.stubAvailable = available;
    return p;
}

// Bug 31409: checkConnection used to sleep up to 5x1s on the calling thread
// when offline. It must now fail fast without blocking.
- (void)testCheckConnectionDoesNotBlockWhenOffline {
    StubProvider *p = [self makeProviderAvailable:NO];
    NSDate *start = [NSDate date];
    NSError *error = nil;
    BOOL ok = [p checkConnection:&error];
    NSTimeInterval elapsed = -[start timeIntervalSinceNow];

    XCTAssertFalse(ok);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, NetworkUnavailable);
    XCTAssertLessThan(elapsed, 0.5, @"checkConnection blocked the calling thread");
}

- (void)testCheckConnectionSucceedsWhenOnline {
    StubProvider *p = [self makeProviderAvailable:YES];
    NSError *error = nil;
    XCTAssertTrue([p checkConnection:&error]);
    XCTAssertNil(error);
}

// TryPass() (backing QueueITEngine.run) must return immediately even offline.
- (void)testTryPassReturnsImmediatelyWhenOffline {
    StubProvider *p = [self makeProviderAvailable:NO];
    NSDate *start = [NSDate date];
    NSError *error = nil;
    BOOL started = [p TryPass:&error];
    NSTimeInterval elapsed = -[start timeIntervalSinceNow];

    XCTAssertFalse(started);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, NetworkUnavailable);
    XCTAssertLessThan(elapsed, 0.5, @"TryPass blocked the calling thread");
}

// A NULL error pointer must not crash (callers may pass NULL).
- (void)testCheckConnectionToleratesNullErrorPointer {
    StubProvider *p = [self makeProviderAvailable:NO];
    XCTAssertFalse([p checkConnection:NULL]);
}

// Bug 31409: the connectivity decision must not report a false
// NetworkUnavailable before the path monitor has determined connectivity,
// and must respect the monitor once it has. Driven deterministically.
- (void)testAssumesAvailableUntilMonitorDetermines {
    NoMonitorProvider *p =
        [[NoMonitorProvider alloc] initWithCustomerId:@"customer"
                                       eventOrAliasId:@"event"
                                           layoutName:nil
                                             language:nil
                                    waitingRoomDomain:nil
                                      queuePathPrefix:nil];

    // Undetermined -> assume available (avoids the reachability false negative).
    XCTAssertTrue([p isNetworkAvailable]);

    // Monitor reports offline -> respect it.
    p.networkPathDetermined = YES;
    p.networkPathSatisfied = NO;
    XCTAssertFalse([p isNetworkAvailable]);

    // Monitor reports online -> respect it.
    p.networkPathSatisfied = YES;
    XCTAssertTrue([p isNetworkAvailable]);
}

@end
