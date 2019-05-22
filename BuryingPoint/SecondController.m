//
//  SecondController.m
//  BuryingPoint
//
//  Created by wujian on 2019/4/4.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "SecondController.h"
#import "BuryingPointBaseModel.h"

@interface SecondController ()

@property (nonatomic, strong) UIButton  *testButton;
@end

@implementation SecondController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.testButton];
}

#pragma mark - buttonEvent
- (void)testButtonClicked:(id)sender {
//    BuryingPointBaseModel *baseModel = [self.secondArray firstObject];
//    baseModel.pkid = 1;
    [self.secondArray replaceObjectAtIndex:0 withObject:@"10"];
    if ([self.delegate respondsToSelector:@selector(requestTTT)]) {
        [self.delegate requestTTT];
    }

}

#pragma mark - setter/getter
- (UIButton *)testButton {
    if (!_testButton ) {
        _testButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 100, 50, 50)];
        _testButton.backgroundColor = [UIColor redColor];
        [_testButton addTarget:self action:@selector(testButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _testButton;
}

@end
