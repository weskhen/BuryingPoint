//
//  MethodSwizzingPlugin.h
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MethodSwizzingPlugin : NSObject

+ (void)swizzingForClass:(Class)class
        originalSelector:(SEL)oriSelector
        swizzledSelector:(SEL)swizzledSelector;


+ (void)swizzlingInClass:(Class)originalClass
        originalSelector:(SEL)originalSelector
          repelacedClass:(Class)replacedClass
        replacedSelector:(SEL)replacedSelector;
@end

