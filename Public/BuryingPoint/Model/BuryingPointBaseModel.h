//
//  BuryingPointBaseModel.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>

typedef NS_ENUM(NSUInteger, BPLogType) {
    /// 普通日志
    BPLogTypeNone = 0,
    /// 页面日志
    BPLogTypePage,
    /// 按钮点击事件日志
    BPLogTypeClick,
    /// 网络请求
    BPLogTypeRequest,
};


@interface BuryingPointBaseModel : NSObject<YYModel>

/// 当前时间戳 默认当前时间 阿里云日志使用 保留字段
@property (nonatomic, assign) NSTimeInterval timestamp;

/// 默认主键id
@property (nonatomic, assign) NSInteger pkid;
/// app版本号
@property (nonatomic, copy, readonly) NSString *version;
/// app build版本号
@property (nonatomic, copy, readonly) NSString *buildVersion;

/// 系统版本号
@property (nonatomic, copy, readonly) NSString *osVersion;
/// 运营商
@property (nonatomic, copy, readonly) NSString *carrierName;
/// app当前环境语言
@property (nonatomic, copy, readonly) NSString *language;
/// 渠道
@property (nonatomic, copy, readonly) NSString *channel;
/// 设备型号
@property (nonatomic, copy, readonly) NSString *deviceModel;
/// 品牌
@property (nonatomic, copy, readonly) NSString *brand;
/// 记录的日志id
@property (nonatomic, assign, readonly) UInt64 logId;
/// 当前sdk版本号
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/// 当前日志类型
@property (nonatomic, assign) BPLogType logType;

/// 日志上传状态 默认0:未上传 1:上传中 2:上传成功
@property (nonatomic, assign) NSInteger logState;


/// model 版本记录 用于数据库校验表更新 子类需要实现该方法
+ (NSString *)modelDBVersion;
/// 获取需要上传阿里云的日志内容
- (NSDictionary<NSString*,NSObject*> *)aliLogContent;


#pragma mark - 阿里云日志内部字段 分类上传 不同的topic对应不同的Model (page事件、event事件) 一个topic对应一个model
/// 子类方法需要实现 不同的topic 可能存在不同的位置 这边默认取类名
+ (NSString *)getAliLogTopic;

+ (NSString *)getAliLogSource;

+ (NSString *)getAliLogAccessKeySecret;

+ (NSString *)getAliLogAccessKeyID;

+ (NSString *)getAliLogEndPoint;

+ (NSString *)getAliLogProject;

+ (NSString *)getAliLogAccessToken;

+ (NSString *)getAliLogLogstores;

@end

