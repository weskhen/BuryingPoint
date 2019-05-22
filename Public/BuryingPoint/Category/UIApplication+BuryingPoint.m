//
//  UIApplication+BuryingPoint.m
//  BuryingPoint
//
//  Created by wujian on 2019/4/18.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "UIApplication+BuryingPoint.h"
#import "BuryingPointMonitor.h"
#import "BuryingPointMacro.h"

@interface AppDelegateMonitor : NSObject

+ (void)exchangeWithDelegate:(id<UIApplicationDelegate>)delegate;

@end

@implementation AppDelegateMonitor

+ (void)exchangeWithDelegate:(id<UIApplicationDelegate>)delegate {
    SEL originalDidFinishSelector = @selector(application:didFinishLaunchingWithOptions:);
    SEL swizzledDidFinishSelector = @selector(buryingPoint_application:didFinishLaunchingWithOptions:);
    
    [MethodSwizzingPlugin swizzlingInClass:[delegate class] originalSelector:originalDidFinishSelector repelacedClass:[self class] replacedSelector:swizzledDidFinishSelector];
    
    SEL originalDidBackgroundSelector = @selector(applicationDidEnterBackground:);
    SEL swizzledDidBackgroundSelector = @selector(buryingPoint_applicationDidEnterBackground:);
    
    [MethodSwizzingPlugin swizzlingInClass:[delegate class] originalSelector:originalDidBackgroundSelector repelacedClass:[self class] replacedSelector:swizzledDidBackgroundSelector];
}

- (BOOL)buryingPoint_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"BuryingPoint start");
    /// 校验数据库升级及环境准备等 线程安全的情况下初始化数据
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [KBuryingPointInstance startPrepareDBEnv];
    });

    return [self buryingPoint_application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)buryingPoint_applicationDidEnterBackground:(UIApplication *)application {
    // 进入后台开启日志上传校验
    //    [KBuryingPointInstance ]
    [self buryingPoint_applicationDidEnterBackground:application];
}

@end

@implementation UIApplication (BuryingPoint)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(setDelegate:);
        SEL swizzledSelector = @selector(buryingPoint_setDelegate:);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalSelector swizzledSelector:swizzledSelector];
    });
}

- (void)buryingPoint_setDelegate:(id<UIApplicationDelegate>)delegate {
    [self buryingPoint_setDelegate:delegate];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AppDelegateMonitor exchangeWithDelegate:delegate];
    });
}

@end

