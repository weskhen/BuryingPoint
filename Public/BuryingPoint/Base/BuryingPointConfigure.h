//
//  BuryingPointConfigure.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BuryingPointAliLogConst.h"

@interface BuryingPointConfigure : NSObject

/// 黑名单列表 (即不上报埋点的VC)
@property (nonatomic, strong) NSArray  *blackNameList;

/// 日志一次最大上传条数
@property (nonatomic, assign) NSUInteger maxLogUploadNum;

/// 计时器上传log的间隔时间
@property (nonatomic, assign) NSTimeInterval timerUploadTime;

/// 上传校验不通过失败的最大次数 超过这个次数取消计时器
@property (nonatomic, assign) NSInteger timerUploadCheckFailedMaxCount;


/// 是否打开log打印 默认Debug打印 Release不打印
@property (nonatomic, assign) BOOL isOpenLog;
/// 是否保存上传后的日志 默认不保存
@property (nonatomic, assign) BOOL isSaveUploadData;

/// 日志上报地址
@property (nonatomic, copy) NSString  *uploadUrl;

/// 日志有效时间 (过了有效时间自动丢弃) 默认3天有效
@property (nonatomic, assign) NSTimeInterval logLimitTime;

/// 上传日志序列化方式 默认json
@property (nonatomic, assign) BuryingPointAliLogType logSerializeType;

@end


