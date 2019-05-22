//
//  UIViewController+BuryingPoint.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "UIViewController+BuryingPoint.h"
#import <objc/runtime.h>
#import "BuryingPointMonitor.h"
#import "BuryingPointPageModel.h"
#import "BuryingPointMacro.h"

static NSString * const KBuryingPointOpenBP = @"buryingPointOpenBP";
static NSString * const KBuryingPointIsWebVC = @"buryingPointIsWebVC";
static NSString * const KBuryingPointIsDisAppear = @"buryingPointIsDisAppear";


@implementation UIViewController (BuryingPoint)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // viewDidLoad
        SEL originalDidLoadSelector = @selector(viewDidLoad);
        SEL swizzingDidLoadSelector = @selector(buryingPoint_viewDidLoad);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalDidLoadSelector swizzledSelector:swizzingDidLoadSelector];
        
#pragma mark - viewDidAppear和viewWillDisappear 用于统计页面
        //viewDidAppear
        SEL originalDidAppearSelector = @selector(viewDidAppear:);
        SEL swizzingDidAppearSelector = @selector(buryingPoint_viewDidAppear:);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalDidAppearSelector swizzledSelector:swizzingDidAppearSelector];
        // viewWillDisappear
        SEL originalWillDisappearSelector = @selector(viewWillDisappear:);
        SEL swizzingWillDisappearSelector = @selector(buryingPoint_viewWillDisappear:);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalWillDisappearSelector swizzledSelector:swizzingWillDisappearSelector];

        //presentViewController:animated:completion:
        SEL originalPresentControllerSelector = @selector(presentViewController:animated:completion:);
        SEL swizzingPresentControllerSelector = @selector(buryingPoint_presentViewController:animated:completion:);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalPresentControllerSelector swizzledSelector:swizzingPresentControllerSelector];
        
    });
}

- (void)buryingPoint_viewDidLoad {
    [self buryingPoint_viewDidLoad];
}


- (void)buryingPoint_viewDidAppear:(BOOL)animated {
    [self buryingPoint_viewDidAppear:animated];
    
    if (![self bp_isOpenUploadLog]) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bp_startUploadLog:) name:KBuryingPointWillUploadLogNotification object:nil];

    KBuryingPointInstance.currentPage = NSStringFromClass([self class]);
}

- (void)buryingPoint_viewWillDisappear:(BOOL)animated {
    [self buryingPoint_viewWillDisappear:animated];
   
    if (![self bp_isOpenUploadLog]) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KBuryingPointWillUploadLogNotification object:nil];
    self.isDisAppear = YES;
}

- (void)buryingPoint_presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion {
    viewControllerToPresent.openBP = YES;
    [self buryingPoint_presentViewController:viewControllerToPresent animated:flag completion:completion];
}

/// 是否上报埋点
- (BOOL)bp_isOpenUploadLog {
    if (!self.openBP) return NO;
    
    // UITabBarController/UINavigationController/UIAlertController 这几个类默认不上报
    if ([self isKindOfClass:[UITabBarController class]] || [self isKindOfClass:[UINavigationController class]] || [self isKindOfClass:[UIAlertController class]]) return NO;
    
    // 黑名单列表
    if ([self bp_isInBlackNameList]) return NO;
    
    return YES;
}

///是否在黑名单中
- (BOOL)bp_isInBlackNameList {
    __block BOOL isBlackName = NO;
    [KBuryingPointInstance.configure.blackNameList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *className = NSStringFromClass([self class]);
        if ([className isEqualToString:obj]) {
            isBlackName = YES;
            *stop = YES;
        }
    }];
    
    return isBlackName;
}

#pragma mark - NSNotification
- (void)bp_startUploadLog:(NSNotification *)notif {
    // 当前类没有打开上报的功能
    if (![self bp_isOpenUploadLog]) {
        return;
    }
    // 直接根据页面打一个page事件
    [self bp_executePageEvent];
}

#pragma mark - publicMethod
- (void)bp_executePageEvent {
    NSString *currentPage = NSStringFromClass([self class]);
    BuryingPointPageModel *model = [BuryingPointPageModel new];
    model.pageType = BPPageTypeNone;
    model.currentPage = currentPage;
    model.lastPage = KBuryingPointInstance.lastPage;
    if (self.isDisAppear) {
        KBuryingPointInstance.lastPage = currentPage;
    }
    model.pageStayTime = KBuryingPointInstance.stopTime > KBuryingPointInstance.startTime?(KBuryingPointInstance.stopTime > KBuryingPointInstance.startTime):0;
    model.timestamp = [KBPServerTimestamp currentTimeInMilliseconds];
    NSDictionary *extraInfo = [self getExtraInformation];
    if (!extraInfo || ![extraInfo isKindOfClass:[NSDictionary class]]) {
        extraInfo = @{};
    }
    model.extraInfo = extraInfo;
    // 页面日志跟踪 不立即上报
    [KBuryingPointInstance handleEventLogWithModel:model strategy:BPLogUploadStrategyNone];
}

- (void)setOpenBP:(BOOL)openBP {
    objc_setAssociatedObject(self, &KBuryingPointOpenBP, [NSNumber numberWithBool:openBP], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)openBP {
    NSNumber *number = objc_getAssociatedObject(self, &KBuryingPointOpenBP);
    return [number boolValue];
}

- (void)setIsWebVC:(BOOL)isWebVC {
    objc_setAssociatedObject(self, &KBuryingPointIsWebVC, [NSNumber numberWithBool:isWebVC], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isWebVC {
    NSNumber *number = objc_getAssociatedObject(self, &KBuryingPointIsWebVC);
    return [number boolValue];
}

- (void)setIsDisAppear:(BOOL)isDisAppear {
    objc_setAssociatedObject(self, &KBuryingPointIsDisAppear, [NSNumber numberWithBool:isDisAppear], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDisAppear {
    NSNumber *number = objc_getAssociatedObject(self, &KBuryingPointIsDisAppear);
    return [number boolValue];
}


- (NSArray *)getExpData {
    return [NSArray new];
}

- (NSDictionary *)getExtraInformation {
    return [NSDictionary new];
}

@end
