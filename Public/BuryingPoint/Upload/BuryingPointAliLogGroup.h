//
//  BuryingPointAliLogGroup.h
//  BuryingPoint
//
//  Created by wujian on 2019/5/15.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BuryingPointAliLogConst.h"

@class BuryingPointBaseModel;
@interface BuryingPointAliLogGroup : NSObject

/// 上传服务器的端点
@property (nonatomic, copy, readonly) NSString *endPoint;
/// 项目空间名
@property (nonatomic, copy, readonly) NSString *project;
@property (nonatomic, copy, readonly) NSString *accessKeyID;
@property (nonatomic, copy, readonly) NSString *accessKeySecret;
/// 可选参数
@property (nonatomic, copy, readonly) NSString *accessToken;
/// 日志组名
@property (nonatomic, copy, readonly) NSString *logstores;

/// 阿里云上传日志序列化方式 默认json
@property (nonatomic, assign, readonly) BuryingPointAliLogType logSerializeType;


- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 通过指定类来实例化对象
- (instancetype)initWithModelClass:(Class)modelClass logSerializeType:(BuryingPointAliLogType)logSerializeType;

/// 存放公共字段入tags 一些不会在app运行期间改变的参数 如 app版本号
+ (void)putCommonTagValue:(NSString *)value key:(NSString *)key;

/// 存单个log对象入group
- (void)putAliLogModel:(BuryingPointBaseModel *)model;

/// 上传Data
- (NSData *)packageData;

@end

