//
//  BuryingPointMonitor.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BuryingPointConfigure.h"
#import "BuryingPointLogUploadStrategy.h"
#import "BuryingPointNotification.h"

#define KBuryingPointInstance [BuryingPointMonitor shareInstance]

@interface BuryingPointMonitor : NSObject

/// 埋点相关配置
@property (nonatomic, strong) BuryingPointConfigure  *configure;

/// 当前页面描述
@property (nonatomic, copy) NSString *currentPage;
/// 页面DidAppear
@property (nonatomic, assign) NSTimeInterval startTime;

/// 记录上一个页面
@property (nonatomic, copy) NSString *lastPage;
/// 页面DidDisAppear
@property (nonatomic, assign) NSTimeInterval stopTime;

/// 数据所属的id 非必传
@property (nonatomic, copy) NSString *ownerId;

/// 单例
+ (BuryingPointMonitor *)shareInstance;

/// 数据库环境准备中 默认app启动的时候调用 数据库环境未初始化成功后 所有操作无效
- (void)startPrepareDBEnv;


/// 根据上报策略 上报埋点
- (void)handleEventLogWithModel:(BuryingPointBaseModel *)model strategy:(BPLogUploadStrategy)strategy;

/// 校验所有埋点数据立即上传
- (void)checkUploadBuryingPointImmediately;

/// 记录接口请求 发起请求时调用
- (void)recordStartRequest:(id)requestMode;

/// 记录接口请求 请求响应时调用
- (void)recordFinishRequest:(id)requestMode;
@end

