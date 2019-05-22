//
//  SecondController.h
//  BuryingPoint
//
//  Created by wujian on 2019/4/4.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SecondControllerDelegate <NSObject>

- (void)requestTTT;
@end

@interface SecondController : UIViewController

@property (nonatomic, strong) NSMutableArray  *secondArray;

@property (nonatomic, weak) id <SecondControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
