//
//  BuryingPointConfigure.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/26.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "BuryingPointConfigure.h"

@implementation BuryingPointConfigure

- (instancetype)init
{
    self = [super init];
    if (self) {
        _blackNameList = [NSArray new];
        _maxLogUploadNum = 100;
        _timerUploadTime = 5.f;
        _isOpenLog = NO;
//        _isSaveUploadData = YES;
        _logLimitTime = 60 * 60 * 24 * 3;
        _logSerializeType = BuryingPointAliLogProtocBuffer;
    }
    return self;
}

- (NSUInteger)maxLogUploadNum {
    if (_maxLogUploadNum == 0) {
        return 100;
    }
    return _maxLogUploadNum;
}
@end
