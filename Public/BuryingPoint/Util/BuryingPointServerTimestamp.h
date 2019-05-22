//
//  BuryingPointServerTimestamp.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>


/// 服务器时间戳和本地时间戳的差
FOUNDATION_EXTERN NSString * const KServerTimeLocalDiffTime;

#define KBPServerTimestamp [BuryingPointServerTimestamp sharedInstance]

@interface BuryingPointServerTimestamp : NSObject

+ (BuryingPointServerTimestamp *)sharedInstance;

/// 获取当前时间戳 毫秒级
- (NSTimeInterval)currentTimeInMilliseconds;

/// 同步当前时间戳 flag: 是否考虑服务器
- (NSTimeInterval)currentTimeInMillisecondsWithServerSync:(BOOL)flag;

/// 需要同步服务器时间
- (void)checkSaveServerTimeToDB:(NSTimeInterval )serverTime;


@end

