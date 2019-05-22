//
//  ViewController.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/25.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "ViewController.h"
#import "BuryingPointBaseModel.h"
#import "UIControl+BuryingPoint.h"
#import "UIViewController+BuryingPoint.h"
#import "BuryingPointMonitor.h"

@interface ViewController ()

@property (nonatomic, strong) BuryingPointBaseModel  *currentModel;
@property (nonatomic, strong) UIButton  *testButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.testButton];
    /// 验证数据的安全性
    [self checkDateSafely];
}

#pragma mark - privateMethod
- (void)checkDateSafely {
    dispatch_queue_t queueT = dispatch_queue_create("发送到", nil);
    // Do any additional setup after loading the view, typically from a nib.
    for (int i=0; i < 10; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            dispatch_async(queueT, ^{
                [self bp_executePageEvent];
            });
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self bp_executePageEvent];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self bp_executePageEvent];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self bp_executePageEvent];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self bp_executePageEvent];
        });
    }
}

static int countPPP = 0;
#pragma mark - buttonEvent
- (void)testButtonClicked {
    countPPP++;
    if (countPPP == 5) {
        [KBuryingPointInstance checkUploadBuryingPointImmediately];
    }
}

#pragma mark - setter/getter

- (UIButton *)testButton {
    if (!_testButton) {
        _testButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 50, 50)];
        [_testButton setTitle:@"test" forState:UIControlStateNormal];
        [_testButton setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
        [_testButton setBackgroundColor:[UIColor greenColor]];
        _testButton.bp_eventId = @"1.1000.1";
        _testButton.bp_currentPage = NSStringFromClass(self.class);
        [_testButton addTarget:self action:@selector(testButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _testButton;
}
@end
