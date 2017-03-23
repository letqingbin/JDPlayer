//
//  JDVideoPlayLayerView.m
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import "JDVideoPlayLayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation JDVideoPlayLayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer*)player
{
    return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer*)player
{
    [(AVPlayerLayer*)[self layer] setPlayer:player];
}

/*
 Specifies how the video is displayed within a player layer’s bounds.
	(AVLayerVideoGravityResizeAspect is default)
 */
- (void)setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity   = fillMode;
}

@end
