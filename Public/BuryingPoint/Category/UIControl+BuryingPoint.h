//
//  UIControl+BuryingPoint.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <UIKit/UIKit.h>

/// UIControl及其子类(UIButton、UIPageControl、UISegmentedControl等等)的相应事件
@interface UIControl (BuryingPoint)

/// 事件id
@property (nonatomic, copy) NSString *bp_eventId;
/// 控件所属的页面类名
@property (nonatomic, copy) NSString  *bp_currentPage;
/// 额外信息
@property (nonatomic, copy) NSDictionary  *bp_extraInfo;

@end

