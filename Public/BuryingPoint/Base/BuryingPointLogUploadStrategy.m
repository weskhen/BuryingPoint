//
//  BuryingPointLogUploadStrategy.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/27.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "BuryingPointLogUploadStrategy.h"
#import "BuryingPointDataBase.h"
#import "BuryingPointConfigure.h"
#import "BuryingPointMacro.h"
#import "BuryingPointPageModel.h"
#import "BuryingPointEventModel.h"
#import "BuryingPointRequestModel.h"
#import "BuryingPointAliLogGroup.h"

/// 表更新key字段前缀
static NSString *KBuryingPointDBVersion = @"KBuryingPointDBVersion";

@interface BuryingPointLogUploadStrategy ()

/// 埋点数据库操作
@property (nonatomic, strong) BuryingPointDataBase  *bpDataBase;
/// model 对象列表
@property (nonatomic, copy) NSArray<Class>  *modelClassList;
/// 当前配置信息
@property (nonatomic, strong, readonly) BuryingPointConfigure  *currentConfig;
/// 上传计时器GCD
@property (nonatomic, strong) dispatch_source_t  uploadTimer;
/// 计时器上传校验不通过失败次数统计
@property (nonatomic, assign) NSInteger timerUploadCheckFailedCount;

/// 是否正在处理数据上传中 同一时间只触发一次
@property (nonatomic, assign) BOOL isUploading;

/// 是否正在上传所有log中
@property (nonatomic, assign) BOOL isUploadAllLog;

@end

@implementation BuryingPointLogUploadStrategy

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isUploading = NO;
        /// 初始化DB环境
        [self.bpDataBase initDBEnvironment];
        /// 先检查数据库表更新
        [self checkUpdataeDataBase];

        /// 实例化之后 将上次处于上传中的状态重置到未上传
        NSTimeInterval logStartTime = [KBPServerTimestamp currentTimeInMilliseconds] - self.currentConfig.logLimitTime*1000;
        [self.modelClassList enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray *modelList = [self.bpDataBase searchAllUploadingStateModelClass:obj limitTime:logStartTime];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [self.bpDataBase markBuryingPointTableWithLogState:0 modelList:modelList];
            });
        }];
    }
    return self;
}

#pragma mark - publicMethod
- (void)prepareExecutingDBOptions {
    NSLog(@"DB数据库环境准备完毕 可以开始执行数据库操作");
}

- (void)setCurrentConfigure:(BuryingPointConfigure *)config {
    _currentConfig = config;
}

- (void)detectLogWithModel:(BuryingPointBaseModel *)model uploadStrategy:(BPLogUploadStrategy)uploadStrategy {
    // 防止线程
    if (![model isKindOfClass:[BuryingPointBaseModel class]])  return;
    // 先保存
    BOOL success = [self.bpDataBase insertDBWithModel:model];
    if (!success) {
        NSLog(@"数据插入失败");
        return;
    }
    // 后根据策略处理数据
    switch (uploadStrategy) {
        case BPLogUploadStrategyNone:
            // 普通发送策略 触发校验 上传条件是否满足
            [self checkUploadLogWithModel:model.class];
            break;
        case BPLogUploadStrategyImmediately:
            // 立即发送策略
            [self checkUploadLogImmediately:model.class];
            break;
        case BPLogUploadStrategyInterval:
            // 时间间隔发送策略
            [self checkUploadStrategyInterval:model.class];
            break;
        case BPLogUploadStrategyAllLogImmediately:
            // 立即上传获取所有的埋点
            [self uploadAllBuryingPointImmediately];
            break;
        default:
            break;
    }
}

- (void)uploadAllBuryingPointImmediately {
    if (self.isUploadAllLog) {
        return;
    }
    //各个类型数据一起上报 需要后端接口支持 目前分多个接口上报
    if (self.isUploading) {
        // 正在上传log 延迟3秒后再触发
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadAllBuryingPointImmediately];
        });
        return;
    }
    self.isUploading = YES;
    self.isUploadAllLog = YES;
    NSArray<Class> *classList = self.modelClassList;
    if (classList.count < 1) return;
    
    __block BOOL hasData = NO;
    [classList enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger count = [self.bpDataBase columnCountWithTableName:NSStringFromClass(obj)];
        if (count > 0) {
            hasData = YES;
            *stop = YES;
        }
    }];
    
    // 没有数据需要上传了 结束全量请求
    if (hasData == NO) {
        self.isUploading = NO;
        self.isUploadAllLog = NO;
        return;
    }
    
    dispatch_group_t queueGroup = dispatch_group_create();
    [classList enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_group_enter(queueGroup);
        [self uploadLogImmediately:obj groupQueue:queueGroup];
    }];
    
    __weak __typeof(&*self)weakSelf = self;
    dispatch_group_notify(queueGroup, dispatch_get_main_queue(), ^(){
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf uploadAllBuryingPointImmediately];
    });
}


#pragma mark - privateMethod
- (void)checkUpdataeDataBase {
    NSArray<Class> *classList = self.modelClassList;
    [classList enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isSubclassOfClass:BuryingPointBaseModel.class]) {
            NSString *tableName = NSStringFromClass(obj);
            NSString *key = [NSString stringWithFormat:@"%@_%@",KBuryingPointDBVersion,tableName];
            NSString *modelSavedVersion = [[NSUserDefaults standardUserDefaults] stringForKey:key];
            modelSavedVersion = modelSavedVersion?:@"1.0";
            // 比较存储的表版本号 与当前最新的版本比较
            id result = [obj performSelector:@selector(modelDBVersion)];
            NSString *currentVerion = result;
            if (modelSavedVersion && ![modelSavedVersion isEqualToString:currentVerion]) {
                // 需要更新
                BOOL success = [self.bpDataBase checkDataBaseUpdate:obj];
                if (success) {
                    [[NSUserDefaults standardUserDefaults] setObject:currentVerion forKey:key];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSLog(@"BuryingPointBaseModel的子类::%@\n", tableName);
                } else {
                    NSAssert(NO, [tableName stringByAppendingString:@"更新失败"]);
                }
            }
        }
    }];
}

/// runtime 遍历获取指定类的所有子类,性能相比于直接获取较差,所以还是手动
- (NSArray<Class> *)getAllSubClassNameWithClass:(Class)class {
    NSMutableArray *results = [NSMutableArray array];
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL,0);
    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; i++) {
            if (class_getSuperclass(classes[i]) == class){
                [results addObject:classes[i]];
                NSLog(@"%@\n", NSStringFromClass(classes[i]));
            }
        }
        free(classes);
    }
    return results;
}

- (void)checkUploadLogWithModel:(Class)modelClass {
    NSInteger count = [self.bpDataBase columnCountWithTableName:NSStringFromClass(modelClass)];
    if (count >= self.currentConfig.maxLogUploadNum) {
        // 满足条件 考虑上传
        [self checkUploadLogImmediately:modelClass];
    }
}

- (void)checkUploadLogImmediately:(Class)modelClass {
    BOOL canUploading = YES;
    if ([self.delegate respondsToSelector:@selector(canStartUploadingLog)]) {
        canUploading = [self.delegate canStartUploadingLog];
    }
    if (canUploading) {
        [self uploadLogImmediately:modelClass];
    }
}

- (void)checkUploadStrategyInterval:(Class)modelClass {
    if (!self.uploadTimer) {
        self.uploadTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("BuryingPointTimerQueue", DISPATCH_QUEUE_SERIAL));
        
        dispatch_source_set_timer(self.uploadTimer, DISPATCH_TIME_NOW, self.currentConfig.timerUploadTime*NSEC_PER_SEC, 0.1*NSEC_PER_SEC);
        __weak __typeof(&*self)weakSelf = self;
        dispatch_source_set_event_handler(self.uploadTimer, ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            BOOL canUploading = YES;
            if ([strongSelf.delegate respondsToSelector:@selector(canStartUploadingLog)]) {
                canUploading = [strongSelf.delegate canStartUploadingLog];
            }
            if (!canUploading) {
                // 校验不通过 统计本次timer次数
                strongSelf.timerUploadCheckFailedCount++;
                // 达到一定次数后 先取消计时器
                if (strongSelf.timerUploadCheckFailedCount >= strongSelf.currentConfig.timerUploadCheckFailedMaxCount) {
                    dispatch_source_cancel(strongSelf.uploadTimer);
                    strongSelf.uploadTimer = nil;
                    strongSelf.timerUploadCheckFailedCount = 0;
                }
            }else {
                // 校验通过 开始立即上传
                [strongSelf uploadLogImmediately:modelClass];
                strongSelf.timerUploadCheckFailedCount = 0;
            }
        });
        dispatch_resume(self.uploadTimer);
    }
}

- (void)uploadLogImmediately:(Class)modelClass {
    if (self.isUploading) {
        return;
    }
    self.isUploading = YES;
    // 有效日志的最早事件
    NSTimeInterval logStartTime = [KBPServerTimestamp currentTimeInMilliseconds] - self.currentConfig.logLimitTime*1000;
    NSArray *resultList = [self.bpDataBase searchWithModelClass:modelClass limitTime:logStartTime maxNum:self.currentConfig.maxLogUploadNum];
    if (resultList.count == 0) {
        self.isUploading = NO;
        return;
    }
    // 对读取出来的数据标记为上传中 防止被多次读取上传
    [self.bpDataBase markBuryingPointTableWithLogState:1 modelList:resultList];
    
    // 准备开始上传
    if ([self.delegate respondsToSelector:@selector(uploadLogImmediatelyWithModelList:modelClass:callBackBlock:)]) {
        __weak __typeof(&*self)weakSelf = self;
        [self.delegate uploadLogImmediatelyWithModelList:resultList modelClass:modelClass callBackBlock:^(BOOL success) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.isUploading = NO;
            if (!success) {
                // 上传失败的数据保留 重置标志位为未上传 触发重传可在网络请求中实现
                [strongSelf.bpDataBase markBuryingPointTableWithLogState:0 modelList:resultList];
                return ;
            }
            // 判断是否保存上传后的数据
            if (self.currentConfig.isSaveUploadData) {
                // 若保存数据 直接重置标志位为上传成功
                [strongSelf.bpDataBase markBuryingPointTableWithLogState:2 modelList:resultList];
            } else {
                // 上传成功 删除数据库中对应的数据
                NSArray *failList = [strongSelf.bpDataBase deleteTableErrorListWithModelList:resultList];
                if (failList && failList.count > 0) {
                    // 删除失败数据保留 重置标志位为上传成功
                    [strongSelf.bpDataBase markBuryingPointTableWithLogState:2 modelList:failList];
                }
            }
        }];
    } else {
        self.isUploading = NO;
    }
}

- (void)uploadLogImmediately:(Class)modelClass groupQueue:(dispatch_group_t)queueGroup {
    // 有效日志的最早时间
    NSTimeInterval logStartTime = [KBPServerTimestamp currentTimeInMilliseconds] - self.currentConfig.logLimitTime*1000;
    NSArray *resultList = [self.bpDataBase searchWithModelClass:modelClass limitTime:logStartTime maxNum:self.currentConfig.maxLogUploadNum];
    // 对读取出来的数据标记为上传中 防止被多次读取上传
    [self.bpDataBase markBuryingPointTableWithLogState:1 modelList:resultList];
    if (resultList.count == 0) {
        dispatch_group_leave(queueGroup);
        return;
    }
    if ([self.delegate respondsToSelector:@selector(uploadLogImmediatelyWithModelList:modelClass:callBackBlock:)]) {
        __weak __typeof(&*self)weakSelf = self;
        [self.delegate uploadLogImmediatelyWithModelList:resultList modelClass:modelClass callBackBlock:^(BOOL success) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (success) {
                // 判断是否保存上传后的数据
                if (self.currentConfig.isSaveUploadData) {
                    // 若保存数据 直接重置标志位为上传成功
                    [strongSelf.bpDataBase markBuryingPointTableWithLogState:2 modelList:resultList];
                } else {
                    // 上传成功 删除数据库中对应的数据
                    NSArray *failList = [strongSelf.bpDataBase deleteTableErrorListWithModelList:resultList];
                    if (failList && failList.count > 0) {
                        // 删除失败数据保留 重置标志位为上传成功
                        [strongSelf.bpDataBase markBuryingPointTableWithLogState:2 modelList:failList];
                    }
                }
            } else {
                // 上传失败的数据保留 重置标志位为未上传 触发重传可在网络请求中实现
                [strongSelf.bpDataBase markBuryingPointTableWithLogState:0 modelList:resultList];
            }
            dispatch_group_leave(queueGroup);
        }];
    } else {
        dispatch_group_leave(queueGroup);
    }
}

#pragma mark - getter
- (BuryingPointDataBase *)bpDataBase {
    if (!_bpDataBase) {
        _bpDataBase = [[BuryingPointDataBase alloc] init];
    }
    return _bpDataBase;
}

- (NSArray *)modelClassList {
    if (!_modelClassList) {
        /// runtime 遍历获取指定类的所有子类,性能相比于直接获取较差,所以还是手动(写具体的类提高性能)
        _modelClassList = [self getAllSubClassNameWithClass:BuryingPointBaseModel.class];
//        _modelClassList = [NSArray arrayWithObjects:BuryingPointPageModel.class, BuryingPointEventModel.class, BuryingPointRequestModel.class, nil];
    }
    return _modelClassList;
}
@end
