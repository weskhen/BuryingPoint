//
//  BuryingPointPageModel.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "BuryingPointBaseModel.h"


typedef NS_ENUM(NSUInteger, BPPageType) {
    BPPageTypeNone,
    BPPageTypeStart,
    BPPageTypeEnd,
};


@interface BuryingPointPageModel : BuryingPointBaseModel

/// 页面类型
@property (nonatomic, assign) BPPageType  pageType;
/// 当前页类名
@property (nonatomic, copy) NSString *currentPage;
/// 上一页类名
@property (nonatomic, copy) NSString *lastPage;

/// 页面停留时间
@property (nonatomic, assign) NSTimeInterval pageStayTime;

/// 额外信息
@property (nonatomic, copy) NSDictionary *extraInfo;

@end

