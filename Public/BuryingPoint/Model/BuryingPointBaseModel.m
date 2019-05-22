//
//  BuryingPointBaseModel.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "BuryingPointBaseModel.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "BuryingPointAliLogConst.h"

static NSString *KBuryingPointCarrierName = nil;
static NSString *KBuryingPointAppVersion = nil;
static NSString *KBuryingPointBuildVersion = nil;
static NSString *KBuryingPointOSVersion = nil;
static NSString *KBuryingPointSDKVersion = nil;
static NSString *KBuryingPointSystemLanguage = nil;
static NSString *KBuryingPointDeviceModel = nil;

@interface BuryingPointBaseModel ()

/// 格式上报存储对象 临时变量
@property (nonatomic, strong) NSMutableDictionary<NSString*,NSObject*>  *contentMap;

@end
@implementation BuryingPointBaseModel

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        KBuryingPointAppVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        KBuryingPointBuildVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
//        KBuryingPointCarrierName = [self currentCarrierName];
        KBuryingPointSystemLanguage = [[NSLocale preferredLanguages] firstObject];
        KBuryingPointOSVersion = [[UIDevice currentDevice] systemVersion];
        KBuryingPointDeviceModel = @"";
        KBuryingPointSDKVersion = @"v1.0";
    });

}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _version = KBuryingPointAppVersion;
        _buildVersion = KBuryingPointBuildVersion;
        _osVersion = KBuryingPointOSVersion;
        _carrierName = KBuryingPointCarrierName;
        _language = KBuryingPointSystemLanguage;
        _channel = @"APPStore";
        _deviceModel = KBuryingPointDeviceModel;
        _brand = @"APPLE";
        _logId = [self getRandomId];
        _sdkVersion = KBuryingPointSDKVersion;
        _logState = 0;
        
        _contentMap = [[NSMutableDictionary alloc] init];
        self.timestamp = [[[NSDate alloc] init] timeIntervalSince1970];
    }
    return self;
}

///// 获取运营商类型
//+ (NSString *)currentCarrierName{
//    CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        if (@available(iOS 12.0, *)) {
//            if ([telephonyInfo respondsToSelector:@selector(serviceSubscriberCellularProvidersDidUpdateNotifier)])
//            {
//                telephonyInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = ^(NSString *name) {
//                    NSLog(@"ios12 carrier changed：%@", name);
//                    dispatch_async(dispatch_get_main_queue(), ^{
//
//                    });
//                };
//            }
//        }
//    });
//
////    if (@available(iOS 12.0, *)) {
////        NSDictionary *dic = telephonyInfo.serviceSubscriberCellularProviders;
////        if (dic.count == 2) { //双卡
////            UIApplication *app = [UIApplication sharedApplication];
////            id statusBar = [app valueForKeyPath:@"statusBar"];
////            
////            if ([statusBar isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
////                id currentString = [statusBar valueForKeyPath:@"statusBar.currentData.cellularEntry.string"];
////                return currentString;
////            }else{
////                return @"";
////            }
////        }
////    }
//    
//    CTCarrier *carrier = telephonyInfo.subscriberCellularProvider;
//    if (!carrier.isoCountryCode) {
//        // 没有sim卡
//        return @"";
//    } else {
//        return carrier.carrierName;
//    }
//}

- (UInt64)getRandomId {
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    srand((unsigned)time(0)); //不加这句每次产生的随机数不变
    UInt64 time = (100000 + (arc4random() % (999999 - 100000 + 1)));
    return recordTime*100000+time;
}

#pragma mark - YYModel

+ (NSArray<NSString *> *)modelPropertyBlacklist {
    return @[@"contentMap",@"hash"];
}

#pragma mark - SQL
- (NSString *)createSqlIndexString {
    return nil;
}

#pragma mark - publicMethod
+ (NSString *)modelDBVersion {
    return @"1.1";
}

- (void)converModelToMap {
    [self.contentMap setValue:[NSNumber numberWithLong:self.timestamp/1000] forKey:KEY_TIME];
    // 有需要过滤或修改的字段在model中实现
    NSDictionary *dic = [self yy_modelToJSONObject];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj && [obj isKindOfClass:[NSString class]] && key && ![key isEqualToString: @""]) {
            if (![obj isEqualToString:@""]) {
                [self.contentMap setValue:obj forKey:key];
            }
        } else if ((obj && [obj isKindOfClass:[NSNumber class]] && key && ![key isEqualToString: @""])) {
            [self.contentMap setValue:[obj stringValue] forKey:key];
        } else if ((obj && key && ![key isEqualToString: @""])) {
            /// 其他有效类型 直接转化为jsonsString
            [self.contentMap setValue:[obj yy_modelToJSONString] forKey:key];
        }
    }];
}

- (NSDictionary<NSString*,NSObject*> *)aliLogContent {
    if (_contentMap.count == 0) {
        [self converModelToMap];
    }
    return _contentMap;
}

+ (NSString *)getAliLogTopic {
    return NSStringFromClass([self class]);
}

+ (NSString *)getAliLogSource {
    return nil;
}

+ (NSString *)getAliLogAccessKeySecret {
    return nil;
}

+ (NSString *)getAliLogAccessKeyID {
    return nil;
}

+ (NSString *)getAliLogEndPoint {
    return nil;
}

+ (NSString *)getAliLogProject {
    return nil;
}

+ (NSString *)getAliLogAccessToken {
    return nil;
}

+ (NSString *)getAliLogLogstores {
    return nil;
}
@end
