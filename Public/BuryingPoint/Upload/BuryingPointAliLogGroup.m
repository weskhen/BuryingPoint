//
//  BuryingPointAliLogGroup.m
//  BuryingPoint
//
//  Created by wujian on 2019/5/15.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "BuryingPointAliLogGroup.h"
#import "BuryingPointBaseModel.h"
#import "Sls.pbobjc.h"
#import <YYModel/YYModel.h>

/// tags 存放公共字段
static NSMutableDictionary<NSString *,NSString*> *aliLogTags = nil;

@interface BuryingPointAliLogGroup ()

/// topic 可为空
@property (nonatomic, copy) NSString *topic;
/// source 可为空
@property (nonatomic, copy) NSString *source;

@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString*,NSObject*>*>  *mContent;

@end
@implementation BuryingPointAliLogGroup

- (instancetype)initWithModelClass:(Class)modelClass logSerializeType:(BuryingPointAliLogType)logSerializeType
{
    self = [super init];
    if (self) {
        _mContent = [[NSMutableArray alloc] init];
        if ([modelClass isSubclassOfClass:BuryingPointBaseModel.class]) {
            _topic = [modelClass performSelector:@selector(getAliLogTopic)];
            _source = [modelClass performSelector:@selector(getAliLogSource)];
            _endPoint = [modelClass performSelector:@selector(getAliLogEndPoint)]?:AliLogDefaultEndPoint;
            _project = [modelClass performSelector:@selector(getAliLogProject)]?:AliLogDefaultProject;
            _accessKeyID = [modelClass performSelector:@selector(getAliLogAccessKeyID)]?:AliLogDefaultAccessKeyID;
            _accessKeySecret = [modelClass performSelector:@selector(getAliLogAccessKeySecret)]?:AliLogDefaultAccessKeySecret;
            _logstores = [modelClass performSelector:@selector(getAliLogLogstores)]?:AliLogDefaultLogstores;
            _accessToken = [modelClass performSelector:@selector(getAliLogAccessToken)];
        } else {
            _topic = @"未知类型";
            _source = @"";
            _endPoint = AliLogDefaultEndPoint;
            _project = AliLogDefaultProject;
            _accessKeyID = AliLogDefaultAccessKeyID;
            _accessKeySecret = AliLogDefaultAccessKeySecret;
            _logstores = AliLogDefaultLogstores;
        }
        _logSerializeType = logSerializeType;
    }
    return self;
}

+ (void)putCommonTagValue:(NSString *)value key:(NSString *)key {
    if (aliLogTags == nil) {
        aliLogTags = [[NSMutableDictionary alloc] init];
    }
    [aliLogTags setValue:value forKey:key];
}

- (void)putAliLogModel:(BuryingPointBaseModel *)model {
    [_mContent addObject:[model aliLogContent]];
}

- (NSData *)packageData {
    if (_logSerializeType == BuryingPointAliLogProtocBuffer) {
        return [self protocBufferPackageData];
    }
    return [self jsonPackageData];
}

#pragma mark - privateMethod
/// pb格式上传阿里云
- (NSData *)protocBufferPackageData {
    LogGroup *logGroup = [[LogGroup alloc] init];
    [logGroup setTopic:_topic];
    [logGroup setSource:_source];
    
    NSMutableArray<Log *> *logs = [[NSMutableArray alloc] init];
    [_mContent enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSObject *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Log *log = [[Log alloc] init];
        [obj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSObject * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isEqualToString:KEY_TIME]) {
                // pb针对time需要单独处理 理论上我们在之前类中处理了,传入的是—number类型
                if ([obj isKindOfClass:[NSNumber class]]) {
                    [log setTime:[(NSNumber *)obj unsignedIntValue]];
                } else if ([obj isKindOfClass:[NSString class]]) {
                    // time区别
                    NSNumber *logTime = [NSNumber numberWithLongLong:[(NSString *)obj longLongValue]];
                    [log setTime:[logTime unsignedIntValue]];
                } else {
                    // 异常数据
                    NSTimeInterval epoch = [[[NSDate alloc] init] timeIntervalSince1970];
                    NSNumber *logTime = [[NSNumber alloc] initWithLong:epoch];
                    [log setTime:[logTime unsignedIntValue]];
                }
            } else {
                Log_Content *logContent = [[Log_Content alloc] init];
                [logContent setKey:key];
                if ([obj isKindOfClass:[NSString class]]) {
                    [logContent setValue:(NSString *)obj];
                } else {
                    [logContent setValue:[obj yy_modelToJSONString]];
                }
                [[log contentsArray] addObject:logContent];
            }
        }];
        [logs addObject:log];
    }];
    [logGroup setLogsArray:logs];
    
    if (aliLogTags && aliLogTags.count > 0) {
        NSMutableArray<LogTag *> *logTags = [[NSMutableArray alloc] init];
        [aliLogTags enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            LogTag *logTag = [[LogTag alloc] init];
            [logTag setKey:key];
            [logTag setValue:obj];
            [logTags addObject:logTag];
        }];
        [logGroup setLogTagsArray:logTags];
    }
    return [logGroup data];
}

/// json格式上传阿里云
- (NSData *)jsonPackageData {
    NSMutableDictionary<NSString *,NSObject*> *package = [[NSMutableDictionary alloc] init];
    [package setValue:_topic forKey:KEY_TOPIC];
    [package setValue:_source forKey:KEY_SOURCE];
    [package setValue:_mContent forKey:KEY_LOGS];
    if (aliLogTags && aliLogTags.count > 0) {
        [package setValue:aliLogTags forKey:KEY_TAGS];
    }
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:package options:NSJSONWritingPrettyPrinted error:&error];
    if (error) return [NSData data];
    return data;
}

@end
