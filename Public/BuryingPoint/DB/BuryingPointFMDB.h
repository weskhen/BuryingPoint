//
//  BuryingPointFMDB.h
//  BuryingPoint
//
//  Created by wujian on 2019/4/4.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LBaseDB/LBaseDB.h>

@class BuryingPointBaseModel;
@interface BuryingPointFMDB : LBaseDB


/// 删除当前表中 model数据
- (BOOL)deleteTableWithModel:(BuryingPointBaseModel *)model;

/// 删除当前表中model列表表数据
- (NSArray *)deleteTableWithModelList:(NSArray<BuryingPointBaseModel *> *)modelList;

@end

