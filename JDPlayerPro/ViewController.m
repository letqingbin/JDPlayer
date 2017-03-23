//
//  ViewController.m
//  JDPlayerPro
//
//  Created by depa on 2017/3/23.
//  Copyright © 2017年 depa. All rights reserved.
//

#import "ViewController.h"
#import "JDViewController.h"
#import "Masonry.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"click";

    UILabel* label = [UILabel new];
    label.text = @"click me";
    label.textColor = [UIColor blackColor];
    label.font = [UIFont boldSystemFontOfSize:30.0f];
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    JDViewController* jdVC = [[JDViewController alloc]init];
    [self.navigationController pushViewController:jdVC animated:YES];
}

@end
