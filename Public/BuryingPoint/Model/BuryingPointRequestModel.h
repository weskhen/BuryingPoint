//
//  BuryingPointRequestModel.h
//  BuryingPoint
//
//  Created by wujian on 2019/4/11.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "BuryingPointBaseModel.h"


/// 接口响应(成功率)埋点 (业务接口)
@interface BuryingPointRequestModel : BuryingPointBaseModel

/// 请求Id 不能为空!(对应于请求的唯一标识,用以区分每个请求,需要自己设计)
@property (nonatomic, strong) NSNumber *reqId;
/// 请求地址
@property (nonatomic, copy) NSString *reqUrl;
/// 请求参数
@property (nonatomic, strong) NSString  *reqJsonString;
/// 请求发起的时间戳
@property (nonatomic, assign) NSTimeInterval reqTime;
/// 请求响应的时间戳
@property (nonatomic, assign) NSTimeInterval respTime;
/// 请求失败记录
@property (nonatomic, strong) NSString  *failReason;

/// 是否丢弃数据,丢弃的数据不作处理. 默认为NO,不丢弃.  
@property (nonatomic, assign) BOOL discard;


/// 通过request实例化对象
- (instancetype)initWithRequestModel:(id)requestModel;

@end

