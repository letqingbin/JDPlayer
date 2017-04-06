//
//  JDPlayer.h
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVPlayer.h>
#import <Foundation/Foundation.h>
#import "Reachability.h"

@class JDPlayer;
@class JDVideoModel;
@class JDPlayerView;

typedef NS_ENUM(NSInteger,JDPlayerErrorCode)
{
    //AVKeyValueStatusFailed
    kVideoPlayerAVKeyValueStatusFailed,

    // There was an error loading the video as an asset.
    kVideoPlayerErrorAssetLoadError,

    // AVPlayer failed to load the asset.
    kVideoPlayerErrorAVPlayerFail,

    // AVPlayerItem failed to load the asset.
    kVideoPlayerErrorAVPlayerItemFail,
};

typedef NS_ENUM(NSInteger,JDPlayerState)
{
    JDPlayerStateUnknown,           //unknown
    JDPlayerStateLoading,           //loading
    JDPlayerStatePlaying,           //plalying
    JDPlayerStatePaused,            //paused
    JDPlayerStateError,             //error
    JDPlayerStateKeepUp,            //keep up
    JDPlayerStateBufferEmpty        //buffer empty
};

@protocol JDPlayerDelegate <NSObject>
@optional
- (BOOL)shouldVideoPlayer:(JDPlayer*)videoPlayer changeStateTo:(JDPlayerState)toState;
- (void)videoPlayer:(JDPlayer*)videoPlayer willChangeStateTo:(JDPlayerState)toState;
- (void)videoPlayer:(JDPlayer*)videoPlayer didChangeStateFrom:(JDPlayerState)fromState;
- (BOOL)shouldVideoPlayer:(JDPlayer*)videoPlayer startVideo:(JDVideoModel *)videoModel;
- (void)videoPlayer:(JDPlayer*)videoPlayer willStartVideo:(JDVideoModel *)videoModel;
- (void)videoPlayer:(JDPlayer*)videoPlayer didStartVideo:(JDVideoModel *)videoModel;

- (void)videoPlayer:(JDPlayer *)videoPlayer isBuffering:(BOOL)buffering;

- (void)videoPlayer:(JDPlayer*)videoPlayer didPlayFrame:(JDVideoModel *)videoModel time:(NSTimeInterval)time lastTime:(NSTimeInterval)lastTime;
- (void)videoPlayer:(JDPlayer*)videoPlayer didPlayToEnd:(JDVideoModel *)videoModel;
- (void)videoPlayer:(JDPlayer*)videoPlayer didNextVideoButtonPressed:(JDVideoModel *)videoModel;
- (void)videoPlayer:(JDPlayer*)videoPlayer didPreviousVideoButtonPressed:(JDVideoModel *)videoModel;

- (void)videoPlayer:(JDPlayer *)videoPlayer didVideoQualityButtonPressed:(JDVideoModel *)videoModel;
- (void)videoPlayer:(JDPlayer *)videoPlayer videoModel:(JDVideoModel *)videoModel reachabilityChanged:(NetworkStatus)status;

- (void)handleErrorCode:(JDPlayerErrorCode)errorCode videoModel:(JDVideoModel *)videoModel customMessage:(NSString*)customMessage;
@end

@interface AVPlayer (JDPlayer)
- (void)seekToTimeInSeconds:(float)time completionHandler:(void (^)(BOOL finished))completionHandler;
- (NSTimeInterval)currentItemDuration;
- (CMTime)currentCMTime;
@end

@interface JDPlayer : NSObject

@property (nonatomic, weak)   id<JDPlayerDelegate> delegate;
@property (nonatomic, assign) JDPlayerState state;
@property (nonatomic, strong) JDPlayerView *jdView;
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerItem* playerItem;

@property (nonatomic, strong, readonly) NSURL* streamURL;
@property (nonatomic, assign) BOOL scrubbing;

- (id)initWithVideoPlayerView:(JDPlayerView*)videoPlayerView;

- (BOOL)isPlayingVideo;
- (NSTimeInterval)currentTime;
- (void)seekToLastWatchedDuration;

#pragma mark - Resource
- (void)loadVideoModel:(JDVideoModel *) videoModel;
- (void)loadVideoWithStreamURL:(NSURL*)streamURL;
- (void)reloadCurrentVideoModel;

#pragma mark - Controls
- (void)playContent;
- (void)pauseContent;
- (void)pauseContentWithCompletionHandler:(void (^)())completionHandler;
- (void)pauseContent:(BOOL)isUserAction  recordCurrentTime:(BOOL)shouldRecord completionHandler:(void (^)())completionHandler;

@end
