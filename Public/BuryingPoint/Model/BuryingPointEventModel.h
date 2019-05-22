//
//  BuryingPointEventModel.h
//  BuryingPoint
//
//  Created by wujian on 2019/4/11.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "BuryingPointBaseModel.h"

/// 时间上报PV/UV
@interface BuryingPointEventModel : BuryingPointBaseModel

/// 事件标记
@property (nonatomic, copy) NSString *eventId;
/// 事件方法
@property (nonatomic, copy) NSString *method;
/// 当前页类名
@property (nonatomic, copy) NSString *currentPage;

/// 额外信息
@property (nonatomic, copy) NSDictionary *extraInfo;

@end

