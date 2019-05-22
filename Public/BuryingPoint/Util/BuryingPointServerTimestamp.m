//
//  BuryingPointServerTimestamp.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "BuryingPointServerTimestamp.h"

NSString *const KServerTimeLocalDiffTime            = @"KServerTimeLocalDiffTime";

@interface BuryingPointServerTimestamp ()

@property (nonatomic, assign) NSTimeInterval diffTime;

@end
@implementation BuryingPointServerTimestamp

+ (BuryingPointServerTimestamp *)sharedInstance {
    static BuryingPointServerTimestamp *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BuryingPointServerTimestamp alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.diffTime = 0;
    }
    return self;
}

#pragma mark - publicMethod
- (NSTimeInterval)currentTimeInMilliseconds
{
    return [self currentTimeInMillisecondsWithServerSync:YES];
}

- (NSTimeInterval)currentTimeInMillisecondsWithServerSync:(BOOL)flag
{
    NSTimeInterval timestamp = [[[NSDate alloc] init] timeIntervalSince1970] * 1000;
    if (flag){
        NSTimeInterval diff = self.diffTime;
        if (diff == 0) {
            // 取数据库的
            diff = [[NSUserDefaults standardUserDefaults] doubleForKey:KServerTimeLocalDiffTime];
        }
        timestamp -= diff;
    }
    timestamp = ceil(timestamp);//向上取整:12.123456 -> 13;
    
    return timestamp;
}

- (void)checkSaveServerTimeToDB:(NSTimeInterval )serverTime {
    NSTimeInterval now = [self currentTimeInMillisecondsWithServerSync:NO];
    NSTimeInterval diffTime = now - serverTime;
    if (self.diffTime == 0) {
        // app启动的第一次保存到DB
        [[NSUserDefaults standardUserDefaults] setDouble:diffTime forKey:KServerTimeLocalDiffTime];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    self.diffTime = diffTime;
}


@end
