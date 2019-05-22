//
//  BuryingPointInterfaceLogCache.h
//  BuryingPoint
//
//  Created by wujian on 2019/4/11.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BuryingPointRequestModel;
@interface BuryingPointInterfaceLogCache : NSObject

/// 添加(已有新对象了不添加)
- (BOOL)addRequestModel:(BuryingPointRequestModel *)model;

/// 更新(没有对象直接添加新对象)
- (BOOL)updateRequestModel:(BuryingPointRequestModel *)model;

/// 获取
- (BuryingPointRequestModel *)getRequestModelByReqId:(NSNumber *)reqId;

/// 移除
- (void)removeObjectByReqId:(NSNumber *)reqId;

@end

