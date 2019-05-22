//
//  UINavigationController+BuryingPoint.m
//  BuryingPoint
//
//  Created by wujian on 2019/4/12.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "UINavigationController+BuryingPoint.h"
#import "BuryingPointMacro.h"
#import <objc/runtime.h>
#import "UIViewController+BuryingPoint.h"

@implementation UINavigationController (BuryingPoint)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalMethod1 = @selector(pushViewController:animated:);
        SEL swizzledMethod1 = @selector(buryingPoint_pushViewController:animated:);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalMethod1 swizzledSelector:swizzledMethod1];
        
        SEL originalMethod2 = @selector(initWithRootViewController:);
        SEL swizzledMethod2 = @selector(buryingPoint_initWithRootViewController:);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalMethod2 swizzledSelector:swizzledMethod2];
    });

}

- (void)buryingPoint_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.openBP = YES;
    [self buryingPoint_pushViewController:viewController animated:animated];
}

- (instancetype)buryingPoint_initWithRootViewController:(UIViewController *)rootViewController {
    rootViewController.openBP = YES;
    return [self buryingPoint_initWithRootViewController:rootViewController];
}

@end
