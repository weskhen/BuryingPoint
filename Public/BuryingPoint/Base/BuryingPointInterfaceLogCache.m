//
//  BuryingPointInterfaceLogCache.m
//  BuryingPoint
//
//  Created by wujian on 2019/4/11.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "BuryingPointInterfaceLogCache.h"
#import "BuryingPointRequestModel.h"

@interface BuryingPointInterfaceLogCache ()

@property (nonatomic, strong) NSMutableDictionary  *requestLogMap;
/// 记录所有已上传的request id
@property (nonatomic, strong) NSMutableArray  *oldReqIdList;
@property (nonatomic, strong) dispatch_semaphore_t lock;
@end

@implementation BuryingPointInterfaceLogCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lock = dispatch_semaphore_create(1);
        self.oldReqIdList = [[NSMutableArray alloc] init];
        self.requestLogMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - publicMethod

- (BOOL)addRequestModel:(BuryingPointRequestModel *)model {
    NSNumber *reqId = model.reqId;
    if (reqId == nil) {
        NSLog(@"reqId不能为nil");
        return NO;
    }
    
    BOOL success = NO;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    // 已经添加过的id 不重复添加
    if (![self.oldReqIdList containsObject:reqId] && ![self.requestLogMap objectForKey:reqId]) {
        [self.requestLogMap setObject:model forKey:reqId];
        success = YES;
    } else {
        model.discard = YES;
    }
    dispatch_semaphore_signal(_lock);
    return success;
}

- (BOOL)updateRequestModel:(BuryingPointRequestModel *)model {
    NSNumber *reqId = model.reqId;
    if (reqId == nil || model.discard) {
        NSLog(@"reqId不能为nil");
        return NO;
    }
    
    BOOL success = NO;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (![self.oldReqIdList containsObject:reqId]) {
        [self.requestLogMap setObject:model forKey:reqId];
        success = YES;
    }
    dispatch_semaphore_signal(_lock);
    return success;
}


- (BuryingPointRequestModel *)getRequestModelByReqId:(NSNumber *)reqId {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    BuryingPointRequestModel *model = [self.requestLogMap objectForKey:reqId];
    dispatch_semaphore_signal(_lock);
    return model;
}

- (void)removeObjectByReqId:(NSNumber *)reqId {
    if (reqId == nil) return;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [self.requestLogMap removeObjectForKey:reqId];
    [self.oldReqIdList addObject:reqId];
    dispatch_semaphore_signal(_lock);
}

@end
