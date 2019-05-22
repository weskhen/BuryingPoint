//
//  BuryingPointDataBase.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BuryingPointBaseModel;
@interface BuryingPointDataBase : NSObject

/// 初始化DB环境
- (void)initDBEnvironment;

/// 插入定义表 一条数据
- (BOOL)insertDBWithModel:(BuryingPointBaseModel *)model;
/// 插入表 多条数据 返回插入失败的数据对象列表 空代表所有数据插入成功
- (NSArray *)insertDBWithTableName:(NSString *)tableName
                         modelList:(NSArray<BuryingPointBaseModel *> *)modelList;
/// 表内 个数
- (NSInteger)columnCountWithTableName:(NSString *)tableName;

/// 删除表的某一条数据 model对应的名字就是表名
- (BOOL)deleteTableWithModel:(BuryingPointBaseModel *)model;

/// 删除表多条数据 model对应的名字就是表名
- (NSArray *)deleteTableErrorListWithModelList:(NSArray<BuryingPointBaseModel *> *)modelList;

/// 删除表 慎用!!!
- (BOOL)dropTableWithTableName:(NSString *)tableName;

/// 数据库表模型升级
- (BOOL)checkDataBaseUpdate:(Class)modelClass;

/// 表数据查询 logState = 0
- (NSArray *)searchWithModelClass:(Class)modelClass
                           maxNum:(NSUInteger)maxNum;
/// 表查询 正在上传中的数据 logState = 1
- (NSArray *)searchAllUploadingStateModelClass:(Class)modelClass
                                     limitTime:(NSTimeInterval)limitTime;
/// 表数据查询 上传失败或没有上传的数据 logState = 0
- (NSArray *)searchWithModelClass:(Class)modelClass
                        limitTime:(NSTimeInterval)limitTime
                           maxNum:(NSUInteger)maxNum;

/// 更新对象列表中的上传状态 不保证sql语句100%成功  logState mark日志的状态
- (void)markBuryingPointTableWithLogState:(NSInteger)logState
                                modelList:(NSArray<BuryingPointBaseModel *> *)modelList;

@end

