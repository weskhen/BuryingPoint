//
//  BuryingPointDBTest.m
//  BuryingPointTests
//
//  Created by wujian on 2019/5/16.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIViewController+BuryingPoint.h"
#import "BuryingPointMonitor.h"

@interface BuryingPointDBTest : XCTestCase

@end

@implementation BuryingPointDBTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testForMutulTheard {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [KBuryingPointInstance checkUploadBuryingPointImmediately];
    });
//    dispatch_queue_t queueT = dispatch_queue_create("发送到", nil);
//    // Do any additional setup after loading the view, typically from a nib.
//    for (int i=0; i < 100; i++) {
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            dispatch_async(queueT, ^{
////                [self bp_executePageEvent];
//            });
//        });
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
////            [self bp_executePageEvent];
//        });
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
////            [self bp_executePageEvent];
//        });
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
////            [self bp_executePageEvent];
//        });
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
////            [self bp_executePageEvent];
//        });
//        
//    }
}

@end
