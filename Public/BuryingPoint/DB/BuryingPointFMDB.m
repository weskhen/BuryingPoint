//
//  BuryingPointFMDB.m
//  BuryingPoint
//
//  Created by wujian on 2019/4/4.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "BuryingPointFMDB.h"
#import <objc/runtime.h>
#import "BuryingPointBaseModel.h"



@interface BuryingPointFMDB ()

@end

@implementation BuryingPointFMDB
#pragma mark - 删除表的某条数据
- (BOOL)deleteTableWithModel:(BuryingPointBaseModel *)model {
    NSString *tableName = NSStringFromClass([model class]);
    NSMutableString *sqlCode = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE  pkid = '%ld';",tableName,(long)model.pkid];
   return [self deleteTableItem:tableName sqlCode:sqlCode];
}

- (NSArray *)deleteTableWithModelList:(NSArray<BuryingPointBaseModel *> *)modelList {
    NSMutableArray *failList = [NSMutableArray array];
    [modelList enumerateObjectsUsingBlock:^(BuryingPointBaseModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL success = [self deleteTableWithModel:obj];
        if (!success) {
            [failList addObject:obj];
        }
    }];
    return failList;
}

// override  重写原先的model转Dictionary方法
- (NSMutableDictionary *)modelToDictionary:(Class)cls {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:0];
    while(cls && [cls isSubclassOfClass:BuryingPointBaseModel.class]) {
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
        cls = class_getSuperclass(cls);
    }
    return mDic;
}

@end
