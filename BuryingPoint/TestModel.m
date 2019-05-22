//
//  TestModel.m
//  BuryingPoint
//
//  Created by wujian on 2019/4/15.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "TestModel.h"

@implementation TestModel

- (BOOL)isEqual:(id)object{
    TestModel *obj = (TestModel *)object;
    if ([self.testId isEqual:obj.testId]) {
        return YES;
    }
    return NO;
}
- (NSUInteger)hash{
    return [self.testId integerValue] * 1000;
}
@end
