//
//  JDVideoPlayLayerView.h
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayer;

@interface JDVideoPlayLayerView : UIView
@property (nonatomic, strong) AVPlayer* player;

- (void)setPlayer:(AVPlayer*)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
