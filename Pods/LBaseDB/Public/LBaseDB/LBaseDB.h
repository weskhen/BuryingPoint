//
//  LBaseDB.h
//  LBaseDB
//
//  Created by wujian on 2019/4/17.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 FMDB 线程安全使用心得:
 1. 使用inTransaction/inDatabase 来确保线程和事务的安全, 优先使用inTransaction.但不能嵌套使用!
 2. FMResultSet对象需要手动调用close方法.
 3. 多线程下确保FMDatabase对象唯一!
 **/

@interface LBaseDB : NSObject

/**
 单例方法创建数据库, 如果使用shareDatabase创建,则默认在NSDocumentDirectory下创建wesk.sqlite, 但只要使用这三个方法任意一个创建成功, 之后即可使用三个中任意一个方法获得同一个实例,参数可随意或nil
 
 dbName 数据库的名称 如: @"wesk.sqlite", 如果dbName = nil,则默认dbName=@"wesk.sqlite"
 dbPath 数据库的路径, 如果dbPath = nil, 则路径默认为NSDocumentDirectory
 */
+ (instancetype)shareDatabase;
+ (instancetype)shareDatabase:(NSString *)dbName;
+ (instancetype)shareDatabase:(NSString *)dbName path:(NSString *)dbPath;

/// 实例方法创建数据库, 同上
- (instancetype)initWithDBName:(NSString *)dbName;
- (instancetype)initWithDBName:(NSString *)dbName path:(NSString *)dbPath;

/// 表操作: 如给表增加索引 等 sqlCode:具体的sql语句
- (BOOL)detectTable:(NSString *)tableName
            sqlCode:(NSString *)sqlCode;

/// 创建表索引(非唯一索引) propertyName:需要建立索引的属性名
- (BOOL)creatIndexOnTable:(NSString *)tableName
             propertyName:(NSString *)propertyName;

/// 建表
- (BOOL)createTable:(NSString *)tableName
         dicOrModel:(id)parameters;

/// 插入单条数据
- (BOOL)insertTable:(NSString *)tableName
         dicOrModel:(id)parameters;

/// 插入多条表数据
- (NSArray *)insertTable:(NSString *)tableName
          dicOrModelList:(NSArray *)dataList;

/// 通过sql删除删除对应表数据
- (BOOL)deleteTableItem:(NSString *)tableName
                sqlCode:(NSString *)sqlCode;

/// 更新表数据
- (BOOL)updateTable:(NSString *)tableName
         dicOrModel:(id)parameters
           whereSql:(NSString *)whereSql;

/// 查表数据
- (NSArray *)searchTable:(NSString *)tableName
              dicOrModel:(id)parameters
                 sqlCode:(NSString *)sqlCode;

/// 表item个数
- (NSInteger)tableItemCount:(NSString *)tableName;

- (NSInteger)tableItemCount:(NSString *)tableName
                   whereSql:(NSString *)sqlCode;
/// 表字段插入
- (BOOL)alterTable:(NSString *)tableName
        dicOrModel:(id)parameters;

/// 删表
- (BOOL)dropTable:(NSString *)tableName;

/// 表升级
- (BOOL)checkDataBaseUpdateWithTableName:(NSString *)tableName
                              dicOrModel:(id)parameters;


/// model字段属性对应数据库中的key属性
+ (NSString *)propertTypeConvert:(NSString *)typeStr;

@end
