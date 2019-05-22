//
//  BuryingPointMonitor.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "BuryingPointMonitor.h"
#import "BuryingPointMacro.h"
#import "BuryingPointUploadPlugin.h"
#import "BuryingPointRequestModel.h"
#import "BuryingPointInterfaceLogCache.h"
#import "BuryingPointAliLogGroup.h"

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


#define BP_RunOnChildThread SuppressPerformSelectorLeakWarning(if ([NSThread isMainThread]) { dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performSelector:_cmd]; }); return; };)

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


#define BP_RunOnChildThread SuppressPerformSelectorLeakWarning(if ([NSThread isMainThread]) { dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performSelector:_cmd]; }); return; };)

@interface BuryingPointMonitor ()<BuryingPointLogUploadStrategyDelegate>

/// 接口请求日志缓存
@property (nonatomic, strong) BuryingPointInterfaceLogCache  *interfaceLogCache;
/// 当前log上传策略
@property (nonatomic, strong) BuryingPointLogUploadStrategy *currentStrategy;

@end
@implementation BuryingPointMonitor

+ (BuryingPointMonitor *)shareInstance{
    static BuryingPointMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BuryingPointMonitor new];
    });
    return instance;
}

#pragma mark - publicMethod
- (void)startPrepareDBEnv {
    BP_RunOnChildThread;
    [self.currentStrategy prepareExecutingDBOptions];
}

- (void)checkUploadBuryingPointImmediately {
    BP_RunOnChildThread;
    if (_currentStrategy == nil) {
        NSLog(@"DB还未初始化好!");
    }
    [self.currentStrategy uploadAllBuryingPointImmediately];
}

/// 统一处理日志数据
- (void)handleEventLogWithModel:(BuryingPointBaseModel *)model strategy:(BPLogUploadStrategy)strategy {
    BP_RunOnChildThread;
    if (_currentStrategy == nil) {
        NSLog(@"DB还未初始化好!!");
    }
    [self.currentStrategy detectLogWithModel:model uploadStrategy:strategy];
}

- (void)recordStartRequest:(id)requestMode {
    BP_RunOnChildThread;
    BuryingPointRequestModel *model = [BuryingPointRequestModel new];
    model.reqTime = [KBPServerTimestamp currentTimeInMilliseconds];
    //这里处理赋值
//    model.reqUrl =
//    model.reqJsonString
    [self.interfaceLogCache addRequestModel:model];
}

- (void)recordFinishRequest:(id)requestMode {
    BuryingPointRequestModel *model = [self.interfaceLogCache getRequestModelByReqId:@(0)];
    model.respTime = [KBPServerTimestamp currentTimeInMilliseconds];
    
    if (model.reqId == nil || model.discard) {
        /// 需要被丢弃的数据
        return;
    }
    
    // 接口日志跟踪结束 存入数据库 不立即上报
    [self handleEventLogWithModel:model strategy:BPLogUploadStrategyNone];
    /// 从cache中移除
    [self.interfaceLogCache removeObjectByReqId:model.reqId];
}

#pragma mark - privateMethod

#pragma mark - BuryingPointLogUploadStrategyDelegate
- (void)uploadLogImmediatelyWithModelList:(NSArray<BuryingPointBaseModel *> *)modelList
                               modelClass:(Class)modelClass
                            callBackBlock:(BPLogUploadStrategyBlock)callBackBlock {
    // 阿里云日志上传
    [BuryingPointUploadPlugin uploadAliLogWithList:modelList modelClass:modelClass logSerializeType:self.configure.logSerializeType successBlock:^{
        if (callBackBlock) {
            callBackBlock(YES);
        }
    } faildBlock:^(NSError * _Nonnull error) {
        // 上传失败
        if (callBackBlock) {
            callBackBlock(NO);
        }
    }];
}

- (BOOL)canStartUploadingLog {
    return YES;
}


#pragma mark - setter/getter
- (void)setCurrentPage:(NSString *)currentPage {
    _currentPage = currentPage;
    self.startTime = [KBPServerTimestamp currentTimeInMilliseconds];
}

- (void)setLastPage:(NSString *)lastPage {
    _lastPage = lastPage;
    self.stopTime = [KBPServerTimestamp currentTimeInMilliseconds];
}

- (BuryingPointConfigure *)configure {
    if (!_configure) {
        _configure = [BuryingPointConfigure new];
    }
    return _configure;
}

- (BuryingPointLogUploadStrategy *)currentStrategy {
    if (!_currentStrategy) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self->_currentStrategy = [[BuryingPointLogUploadStrategy alloc] init];
            [self->_currentStrategy setCurrentConfigure:self.configure];
            self->_currentStrategy.delegate = self;
        });
    }
    return _currentStrategy;
}

- (BuryingPointInterfaceLogCache *)interfaceLogCache {
    if (!_interfaceLogCache) {
        _interfaceLogCache = [[BuryingPointInterfaceLogCache alloc] init];
    }
    return _interfaceLogCache;
}
@end
