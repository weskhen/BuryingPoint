//
//  MethodSwizzingPlugin.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "MethodSwizzingPlugin.h"
#import <objc/runtime.h>

@implementation MethodSwizzingPlugin

+ (void)swizzingForClass:(Class)class
        originalSelector:(SEL)originalSelector
        swizzledSelector:(SEL)swizzledSelector
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL success = class_addMethod(class,
                                   originalSelector,
                                   method_getImplementation(swizzledMethod),
                                   method_getTypeEncoding(swizzledMethod));
    
    if (success) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    }else {
        method_exchangeImplementations(originalMethod,
                                       swizzledMethod);
    }
}

+ (void)swizzlingInClass:(Class)originalClass
        originalSelector:(SEL)originalSelector
          repelacedClass:(Class)replacedClass
        replacedSelector:(SEL)replacedSelector {
    // 原方法
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    //    assert(originalMethod);
    // 替换方法
    Method replacedMethod = class_getInstanceMethod(replacedClass, replacedSelector);
    //    assert(originalMethod);
    IMP replacedMethodIMP = method_getImplementation(replacedMethod);
    // 向实现delegate的类中添加新的方法
    BOOL didAddMethod = class_addMethod(originalClass, replacedSelector, replacedMethodIMP, "v@:@@");
    if (didAddMethod) { // 添加成功
//        NSLog(@"class_addMethod_success --> (%@)", NSStringFromSelector(replacedSelector));
    }
    // 重新拿到添加被添加的method,这部是关键(注意这里originalClass, 不replacedClass), 因为替换的方法已经添加到原类中了, 应该交换原类中的两个方法
    Method newMethod = class_getInstanceMethod(originalClass, replacedSelector);
    // 实现交换
    method_exchangeImplementations(originalMethod, newMethod);
}

@end
