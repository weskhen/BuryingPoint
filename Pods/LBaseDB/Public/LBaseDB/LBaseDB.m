//
//  LBaseDB.m
//  LBaseDB
//
//  Created by wujian on 2019/4/17.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "LBaseDB.h"
#import "FMDB.h"
#import <objc/runtime.h>
#import <YYModel/YYModel.h>

// 数据库中常见的几种类型
#define SQL_TEXT     @"TEXT" //文本
#define SQL_INTEGER  @"INTEGER" //int long integer ...
#define SQL_REAL     @"REAL" //浮点
#define SQL_BLOB     @"BLOB" //data


@interface LBaseDB ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) FMDatabase *db;

/// {tableName:[表里的字段名称]}
@property (nonatomic, strong) NSMutableDictionary  *columnsDictionary;

/// {tableName:{}}
@property (nonatomic, strong) NSMutableDictionary  *modelDictionary;

/// 当前已存在的表保存
@property (nonatomic, strong) NSMutableArray  *tableList;
@end

@implementation LBaseDB
static LBaseDB *jqdb = nil;

+ (instancetype)shareDatabase {
    return [LBaseDB shareDatabase:nil path:nil];
}

+ (instancetype)shareDatabase:(NSString *)dbName {
    return [LBaseDB shareDatabase:dbName path:nil];
}

+ (instancetype)shareDatabase:(NSString *)dbName path:(NSString *)dbPath {
    if (!jqdb) {
        jqdb = [[LBaseDB alloc] initWithDBName:dbName path:dbPath];
    }
    return jqdb;
}

- (instancetype)initWithDBName:(NSString *)dbName {
    return [self initWithDBName:dbName path:nil];
}

- (instancetype)initWithDBName:(NSString *)dbName path:(NSString *)dbPath {
    self = [super init];
    if (self) {
        _tableList = [[NSMutableArray alloc] init];
        
        if (!dbName) {
            dbName = @"wesk.sqlite";
        }
        NSString *path;
        if (!dbPath) {
            dbPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            path = [dbPath stringByAppendingPathComponent:dbName];
        } else {
            path = [dbPath stringByAppendingPathComponent:dbName];
        }
        
        BOOL isDirectory = YES;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        if (!isExist) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
                NSLog(@"sqlc路径创建失败!");
            }
        }
        // 创建FMDatabaseQueue对象
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
        FMDatabase *fmdb = [self.dbQueue valueForKey:@"_db"];
        ///为数据库设置缓存，提高查询效率
        [self.db setShouldCacheStatements:YES];
        
        self.db = fmdb;
        if (![fmdb open]) {
            //数据库打开失败
            NSLog(@"database can not open !");
            return nil;
        }
    }
    return self;
}

- (BOOL)detectTable:(NSString *)tableName
            sqlCode:(NSString *)sqlCode {
    __block BOOL success = NO;
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([db open]) {
            // 判断表是否存在
            success = [strongSelf isExistTable:tableName];
            if (!success) {
                success = [db executeUpdate:sqlCode];
            }
        }
        //有错 回滚
        if (!success) {
            *rollback = YES;
            return ;
        }
    }];

    return success;
}

- (BOOL)creatIndexOnTable:(NSString *)tableName
             propertyName:(NSString *)propertyName {
    return [self detectTable:tableName sqlCode:[self creatIndexSqlCodeInTable:tableName propertyName:propertyName]];
}


#pragma mark - 建表

/// 建表
- (BOOL)createTable:(NSString *)tableName dicOrModel:(id)parameters {
    if (![parameters isKindOfClass:[NSDictionary class]] && ![parameters isKindOfClass:[NSObject class]]) {
        NSLog(@"非法格式");
        return NO;
    }
    
    __block BOOL success = NO;
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([db open]) {
            // 判断表是否存在
            success = [strongSelf isExistTable:tableName];
            if (!success) {
                success = [db executeUpdate:[strongSelf convertModelToCreateTableSqlCode:tableName dicOrModel:parameters]];
            }
        }
        //有错 回滚
        if (!success) {
            *rollback = YES;
            return ;
        }
    }];
    
    return success;
}

#pragma mark - 插入单条数据
/// 插入单条数据
- (BOOL)insertTable:(NSString *)tableName
         dicOrModel:(id)parameters
{
    if (![parameters isKindOfClass:[NSDictionary class]] && ![parameters isKindOfClass:[NSObject class]]) {
        NSLog(@"格式不合法!");
        return NO;
    }
    __block BOOL success = NO;
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([db open]) {
            // 不存在表先创建
            if (![strongSelf isExistTable:tableName]) {
                success = [db executeUpdate:[strongSelf convertModelToCreateTableSqlCode:tableName dicOrModel:parameters]];
            } else {
                success = YES;
            }
            if (success) {
                success = [db executeUpdate:[strongSelf convertModelToInsertSqlCode:tableName dicOrModel:parameters]];
            }
        }
        if (!success) {
            *rollback = YES;
            return ;
        }
    }];
    
    return success;
}

#pragma mark - 插入多条表数据
/// 插入多条数据
- (NSArray *)insertTable:(NSString *)tableName
          dicOrModelList:(NSArray *)dataList {
    if (!dataList || dataList.count == 0) {
        return nil;
    }
    NSMutableArray *failList = [NSMutableArray array];
    [dataList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isSuccess = [self insertTable:tableName dicOrModel:obj];
        if (!isSuccess ) {
            [failList addObject:obj];
        }
    }];
    return failList;
}

#pragma mark - 删除表的某条数据
- (BOOL)deleteTableItem:(NSString *)tableName
                sqlCode:(NSString *)sqlCode {
    __block BOOL success = NO;
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf deleteTableItem:tableName db:db sqlCode:sqlCode];
        if (!success) {
            *rollback = YES;
            return ;
        }
    }];
    return success;
    
}

- (BOOL)deleteTableItem:(NSString *)tableName
                     db:(FMDatabase *)db
                sqlCode:(NSString *)sqlCode
{
    BOOL success = NO;
    if ([db open]) {
        success = [self isExistTable:tableName];
        if (success) {
            // 数据是否存在
            NSInteger itemCount = 0;
            FMResultSet *resultSet = [db executeQuery:[self countSqlCodeInTable:tableName]];
            while ([resultSet next])
            {
                itemCount = [resultSet intForColumn:@"count"];
                break;
            }
            if (itemCount > 0) {
                success = [db executeUpdate:sqlCode];
            }
            [resultSet close];
        }
    }
    return success;
}

#pragma mark - 删表

- (BOOL)dropTable:(NSString *)tableName {
    __block BOOL success = NO;
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([db open]) {
            // 此时需要判断完关闭数据库，再重新打开
            success = [strongSelf isExistTable:tableName];
            if (success) {
                NSString *sqlstr = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
                success = [db executeUpdate:sqlstr];
            }
        }
        
        if (success) {
            if ([self.tableList containsObject:tableName]) {
                [self.tableList removeObject:tableName];
            }
        }
    }];
    return success;
}

#pragma mark - 更新表数据

/// 更新表某一条数据 条件:format
- (BOOL)updateTable:(NSString *)tableName
         dicOrModel:(id)parameters
           whereSql:(NSString *)whereSql
{
    if (![parameters isKindOfClass:[NSDictionary class]] || ![parameters isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    __block BOOL success = NO;
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([db open]) {
            success = [strongSelf isExistTable:tableName];
            if (success) {
                NSDictionary *dic;
                NSArray *clomnArr = [strongSelf getColumnArr:tableName];
                if ([parameters isKindOfClass:[NSDictionary class]]) {
                    dic = parameters;
                } else {
                    dic = [strongSelf getModelPropertyKeyValue:parameters clomnArr:clomnArr];
                }
                
                NSMutableString *finalStr = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ", tableName];
                [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    if ([clomnArr containsObject:key] && ![key isEqualToString:@"pkid"]) {
                        [finalStr appendFormat:@"%@ = %@,", key, obj];
                    }
                }];
                [finalStr deleteCharactersInRange:NSMakeRange(finalStr.length-1, 1)];
                if (whereSql.length) [finalStr appendFormat:@" %@", whereSql];
                
                success =  [db executeUpdate:finalStr];
            }
        }
        if (!success) {
            *rollback = YES;
            return ;
        }
    }];
    
    
    return success;
}

#pragma mark - 查表数据
/// 查表数据 一般需要指定个数 这边需要在format中指定
- (NSArray *)searchTable:(NSString *)tableName
              dicOrModel:(id)parameters
                 sqlCode:(NSString *)sqlCode {
    if (![parameters isKindOfClass:[NSDictionary class]] && ![parameters isKindOfClass:[NSObject class]]) {
        return nil;
    }
    NSMutableArray *resultMArr = [NSMutableArray arrayWithCapacity:0];
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (![db open]) {
            return ;
        }
        if (![strongSelf isExistTable:tableName]) {
            return;
        }
        // 查询数据
        FMResultSet *resultSet = [db executeQuery:sqlCode];
        if (resultSet) {
            NSDictionary *dic = nil;
            if ([parameters isKindOfClass:[NSDictionary class]]) {
                dic = parameters;
                while ([resultSet next]) {
                    NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                        if ([obj isEqualToString:SQL_TEXT]) {
                            id value = [resultSet stringForColumn:key];
                            if (value)
                                [resultDic setObject:value forKey:key];
                        } else if ([obj isEqualToString:SQL_INTEGER]) {
                            [resultDic setObject:@([resultSet longLongIntForColumn:key]) forKey:key];
                        } else if ([obj isEqualToString:SQL_REAL]) {
                            [resultDic setObject:[NSNumber numberWithDouble:[resultSet doubleForColumn:key]] forKey:key];
                        } else if ([obj isEqualToString:SQL_BLOB]) {
                            id value = [resultSet dataForColumn:key];
                            if (value)
                                [resultDic setObject:value forKey:key];
                        }
                        
                    }];
                    
                    if (resultDic) [resultMArr addObject:resultDic];
                }
                
            } else {
                Class class = [parameters class];
                if (class) {
                    NSArray *clomnArr = [strongSelf getColumnArr:tableName];
                    NSDictionary *propertyType = [strongSelf checkConvertModelToDictionary:class];
                    while ([resultSet next]) {
                        id model = [class new];
                        [clomnArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([propertyType[obj] isEqualToString:SQL_TEXT]) {
                                id value = [resultSet stringForColumn:obj];
                                if (value)
                                    [model setValue:value forKey:obj];
                            } else if ([propertyType[obj] isEqualToString:SQL_INTEGER]) {
                                [model setValue:@([resultSet longLongIntForColumn:obj]) forKey:obj];
                            } else if ([propertyType[obj] isEqualToString:SQL_REAL]) {
                                [model setValue:[NSNumber numberWithDouble:[resultSet doubleForColumn:obj]] forKey:obj];
                            } else if ([propertyType[obj] isEqualToString:SQL_BLOB]) {
                                id value = [resultSet dataForColumn:obj];
                                if (value)
                                    [model setValue:value forKey:obj];
                            }
                        }];
                        
                        [resultMArr addObject:model];
                    }
                }
            }
            [resultSet close];
        }
    }];
    return resultMArr;
}



/// 判断是否存在表
- (BOOL)isExistTable:(NSString *)tableName
{
//    NSLog(@"-----------------%@",[NSThread currentThread]);
    if ([self.tableList containsObject:tableName]) {
        return YES;
    }
    BOOL success = NO;
    if ([self.db open]) {
        success = [self.db tableExists:tableName];
    }
    if (success) {
        [self.tableList addObject:tableName];
    }
    return success;
}

/// 获取表中共有多少条数据
- (NSInteger)tableItemCount:(NSString *)tableName
{
    return [self tableItemCount:tableName whereSql:nil];
}

- (NSInteger)tableItemCount:(NSString *)tableName
                   whereSql:(NSString *)sqlCode {
    __block NSInteger itemCount = 0;
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([db open]) {
            NSMutableString *currentSql = [strongSelf countSqlCodeInTable:tableName];
            if (sqlCode.length) [currentSql appendFormat:@" %@", sqlCode];
            FMResultSet *resultSet = [db executeQuery:currentSql];
            while ([resultSet next])
            {
                itemCount = [resultSet intForColumn:@"count"];
                break;
            }
            [resultSet close];
        }
    }];
    return itemCount;
}

#pragma mark - 插入表字段

- (BOOL)alterTable:(NSString *)tableName
        dicOrModel:(id)parameters
{
    if (![parameters isKindOfClass:[NSDictionary class]] && ![parameters isKindOfClass:[NSObject class]]) {
        return NO;
    }
    
    __block BOOL success = NO;
    __weak __typeof(&*self)weakSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([db open]) {
            if (![strongSelf isExistTable:tableName]) {
                return ;
            }
            // 进入字段更新,先置为成功(更新失败的认为失败,及时没有更新也认为更新成功)
            success = YES;
            if ([parameters isKindOfClass:[NSDictionary class]]) {
                NSArray *columnArr = [strongSelf getColumnArr:tableName];
                for (NSString *key in parameters) {
                    if (![columnArr containsObject:key]) {
                        success = [db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", tableName, key, parameters[key]]];
                        if (!success) {
                            break;
                        }
                    }
                }
            } else {
                Class class = [parameters class];
                NSDictionary *modelDic = [strongSelf checkConvertModelToDictionary:class];
                NSArray *columnArr = [strongSelf getColumnArr:tableName];
                for (NSString *key in modelDic) {
                    if (![columnArr containsObject:key]) {
                        success = [db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", tableName, key, modelDic[key]]];
                        if (!success) {
                            break;
                        }
                    }
                }
            }
        }
        if (!success) {
            *rollback = YES;
            return ;
        }
    }];
    return success;
}

#pragma mark - 表升级

- (BOOL)checkDataBaseUpdateWithTableName:(NSString *)tableName
                              dicOrModel:(id)parameters {
    if (![parameters isKindOfClass:[NSObject class]] && ![parameters isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    BOOL success = NO;
    if (![self isExistTable:tableName]) {
        // 不存在表 需要创建
        success = [self createTable:tableName dicOrModel:parameters];
    } else {
        // 检测表更新 不需要更新的认为更新成功
        success = [self alterTable:tableName dicOrModel:parameters];
    }
    return success;
}
#pragma mark - sql语句
- (NSMutableString *)creatIndexSqlCodeInTable:(NSString *)tableName propertyName:(NSString *)propertyName {
    NSString *indexName = [propertyName stringByAppendingString:@"_index"];
    NSMutableString *sqlCode = [NSMutableString stringWithFormat:@"CREATE index %@ on %@(%@)", indexName, tableName, propertyName];
    return sqlCode;
}

- (NSMutableString *)countSqlCodeInTable:(NSString *)tableName {
    NSMutableString *sqlCode = [NSMutableString stringWithFormat:@"SELECT count(*) as 'count' FROM %@", tableName];
    return sqlCode;
}

- (NSMutableString *)creatSqlCodeWithTableName:(NSString *)tableName {
    NSMutableString *sqlCode = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (pkid  INTEGER PRIMARY KEY,", tableName];
    return sqlCode;
}

- (NSMutableString *)convertModelToCreateTableSqlCode:(NSString *)tableName dicOrModel:(id)parameters {
    NSMutableDictionary *dic;
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        dic = [NSMutableDictionary dictionaryWithDictionary:parameters];
    } else {
        dic = [self checkConvertModelToDictionary:[parameters class]];
    }
    NSMutableString *sqlCode = [self creatSqlCodeWithTableName:tableName];
    /// 移除与主键重名的字段
    if ([dic.allKeys containsObject:@"pkid"]) {
        [dic removeObjectForKey:@"pkid"];
    }
    __block int keyCount = 0;
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        keyCount++;
        if (keyCount == dic.count) {
            [sqlCode appendFormat:@" %@ %@)", key, obj];
        } else {
            [sqlCode appendFormat:@" %@ %@,", key, obj];
        }
    }];
    return sqlCode;
}

- (NSMutableString *)convertModelToInsertSqlCode:(NSString *)tableName dicOrModel:(id)parameters {
    
    NSArray *columnArr = [self getColumnArr:tableName];
    NSDictionary *dic;
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        dic = parameters;
    } else {
        // 如果是对象 直接利用yymode转换,需要过滤的字段在对象中实现
        dic = [parameters yy_modelToJSONObject];
    }
    
    NSMutableString *finalStr = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (", tableName];
    NSMutableString *tempStr = [NSMutableString stringWithCapacity:0];
    
    __block int keyCount = 0;
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        // 过滤默认主键字段 pkid
        keyCount++;
        
        if ([columnArr containsObject:key] && ![key isEqualToString:@"pkid"]) {
            [finalStr appendFormat:@"%@,", key];
            if ([obj isKindOfClass:[NSString class]]) {
                [tempStr appendString:[NSString stringWithFormat:@"'%@',",obj ? obj : @""]];
            } else {
                [tempStr appendString:[NSString stringWithFormat:@"'%@',",obj ? obj : 0]];
            }
        }
    }];
    
    [finalStr deleteCharactersInRange:NSMakeRange(finalStr.length-1, 1)];
    if (tempStr.length)
        [tempStr deleteCharactersInRange:NSMakeRange(tempStr.length-1, 1)];
    
    [finalStr appendFormat:@") values (%@)", tempStr];
    
    return finalStr;
}

#pragma mark - privateMethod
- (NSMutableDictionary *)checkConvertModelToDictionary:(Class)cls {
    NSString *tableName = NSStringFromClass(cls);
    NSMutableDictionary *modelDic = [self.modelDictionary objectForKey:tableName];
    if (modelDic) {
        return modelDic;
    }
    NSMutableDictionary *dic = [self modelToDictionary:cls];
    [self.modelDictionary setValue:[dic copy] forKey:tableName];
    return dic;
}

- (NSMutableDictionary *)modelToDictionary:(Class)cls {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:0];
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    for (int i = 0; i < outCount; i++) {
        
        NSString *name = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
        NSString *type = [NSString stringWithCString:property_getAttributes(properties[i]) encoding:NSUTF8StringEncoding];
        
        id value = [LBaseDB propertTypeConvert:type];
        if (value) {
            [mDic setObject:value forKey:name];
        }
    }
    free(properties);
    return mDic;

}
/// 遍历父类属性获取model的key和value
- (NSDictionary *)getModelPropertyKeyValue:(id)model clomnArr:(NSArray *)clomnArr
{
    NSDictionary *modelDic = [model yy_modelToJSONObject];
    NSMutableDictionary *totalDic = [NSMutableDictionary dictionaryWithDictionary:modelDic];
    
    [modelDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![clomnArr containsObject:key]) {
            [totalDic removeObjectForKey:key];
        }
    }];
    return totalDic;
}

+ (NSString *)propertTypeConvert:(NSString *)typeStr
{
    NSString *resultStr = nil;
    if ([typeStr hasPrefix:@"T@\"NSString\""]) {
        resultStr = SQL_TEXT;
    } else if ([typeStr hasPrefix:@"T@\"NSData\""]) {
        resultStr = SQL_BLOB;
    } else if ([typeStr hasPrefix:@"Ti"]||[typeStr hasPrefix:@"TI"]||[typeStr hasPrefix:@"Ts"]||[typeStr hasPrefix:@"TS"]||[typeStr hasPrefix:@"T@\"NSNumber\""]||[typeStr hasPrefix:@"TB"]||[typeStr hasPrefix:@"Tq"]||[typeStr hasPrefix:@"TQ"]) {
        resultStr = SQL_INTEGER;
    } else if ([typeStr hasPrefix:@"Tf"] || [typeStr hasPrefix:@"Td"]){
        resultStr= SQL_REAL;
    }
    
    return resultStr;
}

// 得到表里的字段名称
- (NSArray *)getColumnArr:(NSString *)tableName
{
    __block NSArray *columnList = [self.columnsDictionary objectForKey:tableName];
    if (!columnList) {
        NSMutableArray *mArr = [NSMutableArray arrayWithCapacity:0];
        FMResultSet *resultSet = [self.db getTableSchema:tableName];
        while ([resultSet next]) {
            [mArr addObject:[resultSet stringForColumn:@"name"]];
        }
        [resultSet close];
        [self.columnsDictionary setValue:mArr forKey:tableName];
        return mArr;
    }
    return columnList;
}


- (void)close
{
    [_db close];
}

- (void)open
{
    [_db open];
}

- (NSInteger)lastInsertPrimaryKeyId:(NSString *)tableName
{
    NSInteger pkid = 0;
    NSString *sqlstr = [NSString stringWithFormat:@"SELECT * FROM %@ where pkid = (SELECT max(pkid) FROM %@)", tableName, tableName];
    FMResultSet *resultSet = [self.db executeQuery:sqlstr];
    while ([resultSet next])
    {
        pkid = [resultSet longLongIntForColumn:@"pkid"];
        break;
    }
    [resultSet close];
    
    return pkid;
}


#pragma mark - setter/getter
- (NSMutableDictionary *)columnsDictionary {
    if (!_columnsDictionary) {
        _columnsDictionary = [[NSMutableDictionary alloc] init];
    }
    return _columnsDictionary;
}

- (NSMutableDictionary *)modelDictionary {
    if (!_modelDictionary) {
        _modelDictionary = [[NSMutableDictionary alloc] init];
    }
    return _modelDictionary;
}

@end
