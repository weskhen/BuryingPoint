//
//  UIControl+BuryingPoint.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "UIControl+BuryingPoint.h"
#import <objc/runtime.h>
#import "BuryingPointMonitor.h"
#import "BuryingPointEventModel.h"
#import "BuryingPointMacro.h"

static NSString * const KBuryingPointControlEventId = @"buryingPointControlEventId";
static NSString * const KBuryingPointControlCurrentPage = @"buryingPointControlCurrentPage";
static NSString * const KBuryingPointControlExtraInfo = @"buryingPointControlExtraInfo";

static void *const KBuryingPointControlQueueKey = (void *)&KBuryingPointControlQueueKey;

@implementation UIControl (BuryingPoint)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSel = @selector(sendAction:to:forEvent:);
        SEL swizzledSel = @selector(buryingPoint_sendAction:to:forEvent:);
        
        [MethodSwizzingPlugin swizzingForClass:[self class] originalSelector:originalSel swizzledSelector:swizzledSel];
    });
}

#pragma mark - privateMethod

- (void)buryingPoint_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    if (self.bp_eventId) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            /// 记录控件点击事件
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
    [self buryingPoint_sendAction:action to:target forEvent:event];
}

#pragma mark - setter/getter
- (void)setBp_eventId:(NSString *)bp_eventId {
    objc_setAssociatedObject(self, &KBuryingPointControlEventId, bp_eventId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bp_eventId {
    return objc_getAssociatedObject(self, &KBuryingPointControlEventId);
}

- (void)setBp_currentPage:(NSString *)bp_currentPage {
    objc_setAssociatedObject(self, &KBuryingPointControlCurrentPage, bp_currentPage, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bp_currentPage {
    return objc_getAssociatedObject(self, &KBuryingPointControlCurrentPage);
}

- (void)setBp_extraInfo:(NSDictionary *)bp_extraInfo {
    objc_setAssociatedObject(self, &KBuryingPointControlExtraInfo, bp_extraInfo, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)bp_extraInfo {
    return objc_getAssociatedObject(self, &KBuryingPointControlExtraInfo);
}
@end
