//
//  UIViewController+BuryingPoint.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <UIKit/UIKit.h>


/// VC埋点 页面跟踪 和数据上报 当前类是UITabBarController/UINavigationController/UIAlertController的子类 默认不上报;
@interface UIViewController (BuryingPoint)

/// 是否开启当前类埋点跟踪(在push present的场景下打开 是RootVC打开 其他的关闭)。
@property (nonatomic, assign) BOOL openBP;
/// 是否是web页面 默认不是
@property (nonatomic, assign) BOOL isWebVC;
/// “需要上报的页面”是否消失 用于跟踪页面状态
@property (nonatomic, assign) BOOL isDisAppear;

/// 上报一次page的埋点事件
- (void)bp_executePageEvent;
/// 获取列表曝光的数据 重写该方法 覆盖 默认空
- (NSArray *)getExpData;

/// 获取页面事件额外数据 重写该方法 覆盖 默认空
- (NSDictionary *)getExtraInformation;

@end

