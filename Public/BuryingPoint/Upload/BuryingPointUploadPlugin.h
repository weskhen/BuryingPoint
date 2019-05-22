//
//  BuryingPointUploadPlugin.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/30.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BuryingPointBaseModel;
typedef void (^BPUploadFailedBlock)(NSError *error);
typedef void (^BPUploadSuccessBlock)(void);

@interface BuryingPointUploadPlugin : NSObject

/// 上传自定义的服务器
+ (void)uploadJsonMap:(NSDictionary *)uploadDic
            uploadUrl:(NSString *)uploadUrl
         successBlock:(BPUploadSuccessBlock)successBlock
           faildBlock:(BPUploadFailedBlock)failBlock;


/// 上传阿里云
+ (void)uploadAliLogWithList:(NSArray<BuryingPointBaseModel *> *)modelList
                  modelClass:(Class)modelClass
            logSerializeType:(NSUInteger)logSerializeType
                successBlock:(BPUploadSuccessBlock)successBlock
                  faildBlock:(BPUploadFailedBlock)failBlock;

@end

