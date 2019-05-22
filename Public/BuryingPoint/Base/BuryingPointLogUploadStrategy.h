//
//  BuryingPointLogUploadStrategy.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/27.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>


/// 日志上传策略
typedef NS_ENUM(NSUInteger, BPLogUploadStrategy) {
    /// 默认普通策略 如收集到100条数上报一次 条数可接口外部配置
    BPLogUploadStrategyNone = 0,
    /// 立即发送 如App打开或退入后台时上报一次
    BPLogUploadStrategyImmediately = 1,
    /// 固定时间间隔  例如每隔10分钟上报一次 
    BPLogUploadStrategyInterval = 2,
    /// 全量立即上传模式
    BPLogUploadStrategyAllLogImmediately = 3,
};

@class BuryingPointBaseModel;
@class BuryingPointConfigure;

typedef void (^BPLogUploadStrategyBlock)(BOOL success);

@protocol BuryingPointLogUploadStrategyDelegate <NSObject>

/// 立即上传日志
- (void)uploadLogImmediatelyWithModelList:(NSArray<BuryingPointBaseModel *> *)modelList
                               modelClass:(Class)modelClass
                            callBackBlock:(BPLogUploadStrategyBlock)callBackBlock;
@optional
/// 校验是否可以上传日志了 默认YES (如无网络,无上传数据...)
- (BOOL)canStartUploadingLog;

@end

@interface BuryingPointLogUploadStrategy : NSObject

@property (nonatomic, weak) id <BuryingPointLogUploadStrategyDelegate> delegate;

/// 准备执行DB数据库
- (void)prepareExecutingDBOptions;

/// 设置当前配置
- (void)setCurrentConfigure:(BuryingPointConfigure *)config;

/// 上报日志及上报策略
- (void)detectLogWithModel:(BuryingPointBaseModel *)model uploadStrategy:(BPLogUploadStrategy)uploadStrategy;

/// 立即上传所有埋点数据
- (void)uploadAllBuryingPointImmediately;
@end

