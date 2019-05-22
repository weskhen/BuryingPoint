//
//  UIGestureRecognizer+BuryingPoint.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "UIGestureRecognizer+BuryingPoint.h"
#import <objc/runtime.h>
#import "BuryingPointMonitor.h"
#import "BuryingPointEventModel.h"
#import "BuryingPointMacro.h"

static NSString * const KBuryingPointGestureEventId = @"buryingPointGestureEventId";
static NSString * const KBuryingPointGestureCurrentPage = @"buryingPointGestureCurrentPage";
static NSString * const KBuryingPointGestureExtraInfo = @"buryingPointGestureExtraInfo";

@implementation UIGestureRecognizer (BuryingPoint)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalInitSelector = @selector(initWithTarget:action:);
        SEL swizzledInitSelector = @selector(buryingPoint_initWithTarget:action:);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalInitSelector swizzledSelector:swizzledInitSelector];
        
        SEL originalAddSelector = @selector(addTarget:action:);
        SEL swizzledAddSelector = @selector(buryingPoint_addTarget:action:);
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalAddSelector swizzledSelector:swizzledAddSelector];
    });
}

#pragma mark - privateMethod

- (instancetype)buryingPoint_initWithTarget:(nullable id)target action:(nullable SEL)action {
    id tag = [self buryingPoint_initWithTarget:target action:action];
    [self handleGestureWithTarget:target action:action];
    return tag;
}


- (void)buryingPoint_addTarget:(id)target action:(SEL)action {
    [self buryingPoint_addTarget:target action:action];
    [self handleGestureWithTarget:target action:action];
}

- (void)handleGestureWithTarget:(id)target action:(SEL)action{
    if (self.bp_eventId) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            /// 记录手势
            BuryingPointEventModel *model = [BuryingPointEventModel new];
            model.eventId = self.bp_eventId;
            model.currentPage = self.bp_currentPage;
            model.extraInfo = self.bp_extraInfo;
            model.method = NSStringFromSelector(action);
            model.timestamp = [KBPServerTimestamp currentTimeInMilliseconds];
            // 接口日志跟踪结束 存入数据库 不立即上报
            [KBuryingPointInstance handleEventLogWithModel:model strategy:BPLogUploadStrategyNone];
        });
    }
}

#pragma mark - setter/getter
- (void)setBp_eventId:(NSString *)bp_eventId {
    objc_setAssociatedObject(self, &KBuryingPointGestureEventId, bp_eventId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bp_eventId {
    return objc_getAssociatedObject(self, &KBuryingPointGestureEventId);
}

- (void)setBp_currentPage:(NSString *)bp_currentPage {
    objc_setAssociatedObject(self, &KBuryingPointGestureCurrentPage, bp_currentPage, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bp_currentPage {
    return objc_getAssociatedObject(self, &KBuryingPointGestureCurrentPage);
}

- (void)setBp_extraInfo:(NSDictionary *)bp_extraInfo {
    objc_setAssociatedObject(self, &KBuryingPointGestureExtraInfo, bp_extraInfo, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)bp_extraInfo {
    return objc_getAssociatedObject(self, &KBuryingPointGestureExtraInfo);
}

@end
