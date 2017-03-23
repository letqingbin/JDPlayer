//
//  JDVideoModel.m
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import "JDVideoModel.h"

@implementation JDVideoModel

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.hasNext = NO;
        self.hasPrevious = NO;
        self.canSeekToTime = YES;
        self.isPlayedToEnd = NO;
    }

    return self;
}

@end
