//
//  BuryingPointDataBase.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "BuryingPointDataBase.h"
#import "BuryingPointFMDB.h"
#import "BuryingPointBaseModel.h"

@interface BuryingPointDataBase ()

@property (nonatomic, strong) BuryingPointFMDB *dbPlugin;

/// 数据库查找比较耗时 用本地的变量跟踪item的变化 不保证值100%准
@property (nonatomic, assign) NSInteger selectItemtCount;
@property (nonatomic, assign) BOOL hasRequestCount;

@end

@implementation BuryingPointDataBase


- (void)dealloc
{
    NSLog(@"%s",__func__);
}

#pragma mark - publicMethod

- (void)initDBEnvironment {
    self.selectItemtCount = 0;
    _dbPlugin = [[BuryingPointFMDB alloc] initWithDBName:@"wesk.sqlite"];
//    _dbPlugin = [BuryingPointFMDB shareDatabase:@"wesk.sqlite"];
    if (_dbPlugin == nil) {
        NSLog(@"数据库创建失败");
        _dbPlugin = [[BuryingPointFMDB alloc] initWithDBName:@"wesk.sqlite"];
    }
}

- (BOOL)insertDBWithModel:(BuryingPointBaseModel *)model {
    // 如果存在表了直接插入新数据
    NSString *tableName = NSStringFromClass(model.class);
    BOOL success = [self.dbPlugin insertTable:tableName dicOrModel:model];
    if (success) {
        self.selectItemtCount ++;
    }
    return success;
}

- (NSArray *)insertDBWithTableName:(NSString *)tableName
                         modelList:(NSArray<BuryingPointBaseModel *> *)modelList {
    NSInteger totalCount = modelList.count;
    NSArray *failList = [self.dbPlugin insertTable:tableName dicOrModelList:modelList];
    self.selectItemtCount += (totalCount - failList.count);
    return failList;
}

- (NSInteger)columnCountWithTableName:(NSString *)tableName {
    if (self.selectItemtCount < 0) {
        // 值异常重新读区数据库
        self.hasRequestCount = NO;
    }
    if (!self.hasRequestCount) {
        self.hasRequestCount = YES;
        NSString *whereSql = @"WHERE logState = 0";
        NSInteger itemtCount = [self.dbPlugin tableItemCount:tableName whereSql:whereSql];
        self.selectItemtCount = itemtCount;
    }
    return self.selectItemtCount;
}

- (BOOL)deleteTableWithModel:(BuryingPointBaseModel *)model {
    NSString *tableName = NSStringFromClass([model class]);
    NSMutableString *sqlCode = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE  pkid = '%ld';",tableName,(long)model.pkid];
    BOOL success = [self.dbPlugin deleteTableItem:tableName sqlCode:sqlCode];
    if (success && model.logState == 0) {
        self.selectItemtCount--;
    }
    return success;
}

- (NSArray *)deleteTableErrorListWithModelList:(NSArray<BuryingPointBaseModel *> *)modelList {
    NSMutableArray *failList = [NSMutableArray array];
    [modelList enumerateObjectsUsingBlock:^(BuryingPointBaseModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL success = [self deleteTableWithModel:obj];
        if (!success) {
            [failList addObject:obj];
        }
    }];
    return failList;
}

- (BOOL)dropTableWithTableName:(NSString *)tableName {
    return [self.dbPlugin dropTable:tableName];
}

- (BOOL)checkDataBaseUpdate:(Class)modelClass
{
    //数据
    NSString *tableName = NSStringFromClass(modelClass);
    return [self.dbPlugin checkDataBaseUpdateWithTableName:tableName dicOrModel:modelClass];
}

- (NSArray *)searchWithModelClass:(Class)modelClass
                           maxNum:(NSUInteger)maxNum
{
    NSString *tableName = NSStringFromClass(modelClass);
    NSString *sqlCode = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE logState = 0 limit %ld",tableName,(long)maxNum];
    return [self.dbPlugin searchTable:tableName dicOrModel:modelClass sqlCode:sqlCode];
}

- (NSArray *)searchAllUploadingStateModelClass:(Class)modelClass
                                     limitTime:(NSTimeInterval)limitTime {
    NSString *tableName = NSStringFromClass(modelClass);
    NSString *sqlCode = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE logState = 0 AND timestamp > %f",tableName,limitTime];
    return [self.dbPlugin searchTable:tableName dicOrModel:modelClass sqlCode:sqlCode];
}

- (NSArray *)searchWithModelClass:(Class)modelClass
                        limitTime:(NSTimeInterval)limitTime
                           maxNum:(NSUInteger)maxNum {
    NSString *tableName = NSStringFromClass(modelClass);
    NSString *sqlCode = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE logState = 1 AND timestamp > %f limit %ld",tableName,limitTime,(long)maxNum];
    return [self.dbPlugin searchTable:tableName dicOrModel:modelClass sqlCode:sqlCode];
}

- (void)markBuryingPointTableWithLogState:(NSInteger)logState
                                modelList:(NSArray<BuryingPointBaseModel *> *)modelList {
    if (modelList.count < 1) {
        return;
    }
    [modelList enumerateObjectsUsingBlock:^(BuryingPointBaseModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *tableName = NSStringFromClass(obj.class);
        NSString *whereSql = [NSString stringWithFormat:@"WHERE pkid = %ld",(long)obj.pkid];
        BOOL success = [self.dbPlugin updateTable:tableName dicOrModel:@{@"logState":@(logState)} whereSql:whereSql];
        if (success && logState == 1) {
            self.selectItemtCount--;
        }
    }];
}

@end
