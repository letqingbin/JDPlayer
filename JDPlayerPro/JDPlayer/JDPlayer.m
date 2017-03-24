//
//  JDPlayer.m
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import "JDPlayer.h"
#import "JDScrubber.h"
#import "JDPlayerView.h"
#import "JDVideoModel.h"
#import "JDVideoPlayLayerView.h"
#import "ReactiveCocoa.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

NSString *kTracksKey    = @"tracks";
NSString *kPlayableKey	= @"playable";
static const NSString *ItemStatusContext;
static NSString* kJDVideoPlayerItemReadyToPlay = @"kJDVideoPlayerItemReadyToPlay";

NSString* kJDProgressValueUpdatedNotification = @"kJDProgressValueUpdatedNotification";
NSString* kJDDurationDidLoadNotification = @"kJDDurationDidLoadNotification";
NSString* kJDScrubberValueUpdatedNotification = @"kJDScrubberValueUpdatedNotification";

@implementation AVPlayer (JDPlayer)

- (void)seekToTimeInSeconds:(float)time completionHandler:(void (^)(BOOL finished))completionHandler
{
    if ([self respondsToSelector:@selector(seekToTime:toleranceBefore:toleranceAfter:completionHandler:)])
    {
        [self seekToTime:CMTimeMakeWithSeconds(time, self.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
    }
    else
    {
        [self seekToTime:CMTimeMakeWithSeconds(time, self.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        completionHandler(YES);
    }
}

- (NSTimeInterval)currentItemDuration
{
    return CMTimeGetSeconds([self.currentItem duration]);
}

- (CMTime)currentCMTime
{
    return [self currentTime];
}

@end

@interface JDPlayer()<JDPlayerViewDelegate,JDScrubberDelegate>

@property (nonatomic, assign) NSTimeInterval previousPlaybackTime;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, assign) float seekTime;

@end

@implementation JDPlayer

- (instancetype)init
{
    self = [super init];

    if(self)
    {
        [self initProperties];
        [self addObservers];
    }

    return self;
}

- (id)initWithVideoPlayerView:(JDPlayerView*)videoPlayerView
{
    self = [super init];
    if (self)
    {
        self.jdView = videoPlayerView;
        [self initProperties];
        [self addObservers];
    }
    return self;
}

- (void)initProperties
{
    self.state = JDPlayerStateUnknown;
    self.scrubbing  = NO;
    self.seekTime   = 0.0f;
    self.previousPlaybackTime = 0;
}

- (void)addObservers
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(playerItemReadyToPlay) name:kJDVideoPlayerItemReadyToPlay object:nil];
}

- (void)playerItemReadyToPlay
{
    switch (self.state) {
        case JDPlayerStatePaused:
            break;
        case JDPlayerStateBufferEmpty:
        {
            self.state = JDPlayerStateKeepUp;
            break;
        }
        case JDPlayerStateLoading:
        case JDPlayerStateError:
        {
            [self pauseContent:NO completionHandler:^{

                if ([self.delegate respondsToSelector:@selector(videoPlayer:willStartVideo:)])
                {
                    [self.delegate videoPlayer:self willStartVideo:self.jdView.videoModel];
                }
                [self seekToLastWatchedDuration];
            }];

            break;
        }
        default:
            break;
    }
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];

    _playerItem = playerItem;
    if (!playerItem)
    {
        return;
    }

    [_playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)setAvPlayer:(AVPlayer *)avPlayer
{
    [_avPlayer removeTimeObserver:self.timeObserver];
    self.timeObserver = nil;

    [_avPlayer removeObserver:self forKeyPath:@"status"];
    _avPlayer = avPlayer;

    if (avPlayer)
    {
        [avPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
        @weakify(self)
        self.timeObserver = [avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time){
            @strongify(self)
            [self periodicTimeObserver:time];
        }];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.avPlayer)
    {
        if ([keyPath isEqualToString:@"status"])
        {
            switch ([self.avPlayer status])
            {
                case AVPlayerStatusReadyToPlay:

                    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kJDVideoPlayerItemReadyToPlay object:nil];
                    }
                    break;
                case AVPlayerStatusFailed:
                    [self handleErrorCode:kVideoPlayerErrorAVPlayerFail videoModel:self.jdView.videoModel];
                default:
                    break;
            }
        }
    }

    if (object == self.playerItem)
    {
        if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            if (self.playerItem.isPlaybackBufferEmpty && [self.delegate respondsToSelector:@selector(videoPlayer:isBuffering:)])
            {
                [self.delegate videoPlayer:self isBuffering:YES];
            }

            if (self.playerItem.isPlaybackBufferEmpty && [self currentTime] > 0 && [self currentTime] < [self.avPlayer currentItemDuration] - 1 && (self.state == JDPlayerStatePlaying || self.state == JDPlayerStateKeepUp))
            {
                //playbackBufferEmpty
                self.state = JDPlayerStateBufferEmpty;
            }
        }

        if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
        {
            if (self.playerItem.playbackLikelyToKeepUp && [self.delegate respondsToSelector:@selector(videoPlayer:isBuffering:)])
            {
                [self.delegate videoPlayer:self isBuffering:NO];
            }

            if (self.playerItem.playbackLikelyToKeepUp)
            {
                if (self.state == JDPlayerStateBufferEmpty && ![self isPlayingVideo])
                {
                    //playbackLikelyToKeepUp
                    self.state = JDPlayerStateKeepUp;
                }
            }
        }

        if ([keyPath isEqualToString:@"status"])
        {
            switch ([self.playerItem status])
            {
                case AVPlayerItemStatusReadyToPlay:
                    if ([self.avPlayer status] == AVPlayerStatusReadyToPlay)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kJDVideoPlayerItemReadyToPlay object:nil];
                    }
                    break;
                case AVPlayerItemStatusFailed:
                    [self handleErrorCode:kVideoPlayerErrorAVPlayerItemFail videoModel:self.jdView.videoModel];
                default:
                    break;
            }
        }

        if([keyPath isEqualToString:@"loadedTimeRanges"])
        {
            NSArray* array = [self.playerItem loadedTimeRanges];
            CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
            Float64 start         = CMTimeGetSeconds(timeRange.start);
            Float64 duration      = CMTimeGetSeconds(timeRange.duration);
            NSTimeInterval buffer = start + duration;
            float progress        = buffer / [self.avPlayer currentItemDuration];

            if(progress <= 0.0f) progress = 0.0f;
            if(progress >= 1.0f) progress = 1.0f;

            NSDictionary *info = [NSDictionary dictionaryWithObject:@(progress) forKey:@"progressValue"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kJDProgressValueUpdatedNotification object:self userInfo:info];
        }
    }
}

- (void)periodicTimeObserver:(CMTime)time
{
    NSTimeInterval timeInSeconds     = CMTimeGetSeconds(time);
    NSTimeInterval lastTimeInSeconds = _previousPlaybackTime;

    if (timeInSeconds <= 0)
    {
        return;
    }

    if ([self isPlayingVideo])
    {
        _previousPlaybackTime = timeInSeconds;
    }

    if ([self.avPlayer currentItemDuration] > 1)
    {
        NSDictionary *info = [NSDictionary dictionaryWithObject:@(timeInSeconds) forKey:@"scrubberValue"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kJDScrubberValueUpdatedNotification object:self userInfo:info];

        NSDictionary *durationInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @(self.jdView.videoModel.hasPrevious), @"hasPreviousVideo",
                                      @(self.jdView.videoModel.hasNext), @"hasNextVideo",
                                      @([self.avPlayer currentItemDuration]), @"duration",
                                      nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kJDDurationDidLoadNotification object:self userInfo:durationInfo];
    }

    [self.jdView hideControlsIfNecessary];  

    if ([self.delegate respondsToSelector:@selector(videoPlayer:didPlayFrame:time:lastTime:)]) {
        [self.delegate videoPlayer:self didPlayFrame:self.jdView.videoModel time:timeInSeconds lastTime:lastTimeInSeconds];
    }
}

- (void)playerDidPlayToEnd:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.jdView.videoModel.isPlayedToEnd = YES;
        [self pauseContent:NO completionHandler:^{
            if ([self.delegate respondsToSelector:@selector(videoPlayer:didPlayToEnd:)])
            {
                [self.delegate videoPlayer:self didPlayToEnd:self.jdView.videoModel];
            }
        }];
    });
}

#pragma mark -- state setter
- (void)setState:(JDPlayerState)newPlayerState
{
    if ([self.delegate respondsToSelector:@selector(shouldVideoPlayer:changeStateTo:)])
    {
        if (![self.delegate shouldVideoPlayer:self changeStateTo:newPlayerState])
        {
            return;
        }
    }

    if ([self.delegate respondsToSelector:@selector(videoPlayer:willChangeStateTo:)]) {
        [self.delegate videoPlayer:self willChangeStateTo:newPlayerState];
    }

    JDPlayerState oldPlayerState = self.state;
    if (oldPlayerState == newPlayerState) return;

    switch (oldPlayerState) {
        case JDPlayerStateLoading:
            [self.jdView stopLoading];
            break;
        case JDPlayerStatePlaying:
            break;
        case JDPlayerStatePaused:
            break;
        case JDPlayerStateError:
            break;
        case JDPlayerStateBufferEmpty:
            [self.jdView stopLoading];
            break;
        case JDPlayerStateKeepUp:
            break;
        case JDPlayerStateUnknown:
            break;
        default:
            break;
    }
    _state = newPlayerState;

    dispatch_async(dispatch_get_main_queue(), ^{

        switch (newPlayerState) {
            case JDPlayerStateUnknown:
                break;
            case JDPlayerStateLoading:
                [self.jdView startLoading];
                [self.jdView setControlsEnabled:NO];
                break;
            case JDPlayerStatePlaying:
                self.jdView.countdownToHide = 5;
                [self.jdView setControlsEnabled:YES];
                [self.jdView.playButton setSelected:NO];
                [self.avPlayer play];
                break;
            case JDPlayerStatePaused:
                [self.jdView setControlsEnabled:YES];
                [self.jdView.playButton setSelected:YES];
                self.jdView.videoModel.lastDurationWatchedInSeconds = (float)[self currentTime];
                [self.avPlayer pause];
                break;
            case JDPlayerStateError:
                [self.avPlayer pause];
                [self.jdView setControlsEnabled:YES];
                self.jdView.countdownToHide = -1;
                break;
            case JDPlayerStateBufferEmpty:
                [self.jdView startLoading];
                [self.jdView setControlsEnabled:NO];
                [self.jdView.playButton setSelected:YES];
                self.jdView.countdownToHide = -1;
                break;
            case JDPlayerStateKeepUp:
                _state = JDPlayerStatePlaying;
                self.jdView.countdownToHide = 5;
                [self.jdView setControlsEnabled:YES];
                [self.jdView.playButton setSelected:NO];
                [self.avPlayer play];
                break;
        }
    });

    if ([self.delegate respondsToSelector:@selector(videoPlayer:didChangeStateFrom:)]) {
        [self.delegate videoPlayer:self didChangeStateFrom:oldPlayerState];
    }
}

- (void)playContent
{
    if (self.state == JDPlayerStatePaused)
    {
        self.state = JDPlayerStatePlaying;
    }
}

- (void)pauseContent
{
    [self pauseContent:NO completionHandler:nil];
}

- (void)pauseContentWithCompletionHandler:(void (^)())completionHandler
{
    [self pauseContent:NO completionHandler:completionHandler];
}

- (void)pauseContent:(BOOL)isUserAction completionHandler:(void (^)())completionHandler
{
    switch ([self.playerItem status]) {
        case AVPlayerItemStatusFailed:
            self.state = JDPlayerStateError;
            return;
            break;
        case AVPlayerItemStatusUnknown:
            self.state = JDPlayerStateLoading;
            return;
            break;
        default:
            break;
    }

    switch ([self.avPlayer status]) {
        case AVPlayerStatusFailed:
            self.state = JDPlayerStateError;
            return;
            break;
        case AVPlayerStatusUnknown:
            self.state = JDPlayerStateLoading;
            return;
            break;
        default:
            break;
    }

    switch (self.state) {
        case JDPlayerStateLoading:
        case JDPlayerStatePlaying:
        case JDPlayerStatePaused:
        case JDPlayerStateError:
            self.state = JDPlayerStatePaused;
            if (completionHandler) completionHandler();
            break;
        default:
            break;
    }
}

- (void)loadVideoWithStreamURL:(NSURL*)streamURL
{
    JDVideoModel* videoModel = [[JDVideoModel alloc]init];
    videoModel.streamURL     = streamURL;
    [self loadVideoModel:videoModel];
}

- (void)loadVideoModel:(JDVideoModel *)videoModel
{
    self.jdView.videoModel = videoModel;
    [self clearPlayer];

    self.state = JDPlayerStateLoading;

    @weakify(self)
    void (^completionHandler)(void) = ^{
        @strongify(self)
        [self playVideo:self.jdView.videoModel];
    };

    switch (self.state) {
        case JDPlayerStateError:
        case JDPlayerStatePaused:
        case JDPlayerStateLoading:
            completionHandler();
            break;
        case JDPlayerStatePlaying:
            [self pauseContent:NO completionHandler:completionHandler];
            break;
        default:
            break;
    };
}

- (void)reloadCurrentVideoModel
{
    @weakify(self)
    void (^completionHandler)(void) = ^{
        @strongify(self)
        self.state = JDPlayerStateLoading;
        [self playVideo:self.jdView.videoModel];
    };

    switch (self.state) {
        case JDPlayerStateUnknown:
        case JDPlayerStateLoading:
        case JDPlayerStatePaused:
        case JDPlayerStateError:
            completionHandler();
            break;
        case JDPlayerStatePlaying:
            [self pauseContent:NO completionHandler:completionHandler];
            break;
        default:
            break;
    }
}

- (void)clearPlayer
{
    self.playerItem = nil;
    self.avPlayer   = nil;
}

- (void)playVideo:(JDVideoModel *)videoModel
{
    if ([self.delegate respondsToSelector:@selector(shouldVideoPlayer:startVideo:)])
    {
        if (![self.delegate shouldVideoPlayer:self startVideo:videoModel])
        {
            return;
        }
    }

    [self clearPlayer];

    if (!videoModel.streamURL)
    {
        return;
    }

    [self playOnAVPlayer:videoModel.streamURL playerLayerView:self.jdView.playerLayerView videoModel:videoModel];
}

- (void)playOnAVPlayer:(NSURL*)streamURL playerLayerView:(JDVideoPlayLayerView *)playLayer videoModel:(JDVideoModel *)videoModel
{
    NSArray* requestedKeys = @[kTracksKey, kPlayableKey];
    AVURLAsset* asset = [[AVURLAsset alloc] initWithURL:streamURL options:@{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES }];

    @weakify(self)
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        @strongify(self)

        // IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem.
        dispatch_async(dispatch_get_main_queue(), ^{

            for (NSString *thisKey in requestedKeys)
            {
                NSError *error = nil;
                AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
                if (keyStatus == AVKeyValueStatusFailed)
                {
                    [self handleErrorCode:kVideoPlayerAVKeyValueStatusFailed videoModel:videoModel];
                    return;
                }
            }

            NSError *error = nil;
            AVKeyValueStatus status = [asset statusOfValueForKey:kTracksKey error:&error];

            if (status == AVKeyValueStatusLoaded)
            {
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                self.avPlayer   = [AVPlayer playerWithPlayerItem:self.playerItem];

                [playLayer setPlayer:self.avPlayer];
            }
            else
            {
                // You should deal with the error appropriately.
                [self handleErrorCode:kVideoPlayerErrorAssetLoadError videoModel:videoModel];
                NSLog(@"The asset's tracks were not loaded:\n%@", error);
            }
        });
    }];
}

- (void)seekToLastWatchedDuration
{
    dispatch_async(dispatch_get_main_queue(), ^{

        self.jdView.playButton.enabled = NO;

        CGFloat lastWatchedTime = self.jdView.videoModel.lastDurationWatchedInSeconds;
        if (lastWatchedTime > 5) lastWatchedTime -= 5;

        NSLog(@"Seeking to last watched duration: %f", lastWatchedTime);
        [self.jdView.scrubber setValue:([self.avPlayer currentItemDuration] > 0) ? lastWatchedTime / [self.avPlayer currentItemDuration] : 0.0f animated:NO];

        [self.avPlayer seekToTimeInSeconds:lastWatchedTime completionHandler:^(BOOL finished)
         {
             if (finished)
             {
                 [self playContent];
             }

             self.jdView.playButton.enabled = YES;

             if ([self.delegate respondsToSelector:@selector(videoPlayer:didStartVideo:)])
             {
                 [self.delegate videoPlayer:self didStartVideo:self.jdView.videoModel];
             }
         }];
    });
}

- (void)scrubbingBegin
{
    self.scrubbing = YES;

    @weakify(self)
    [self pauseContent:NO completionHandler:^{
        @strongify(self)
        self.jdView.countdownToHide = -1;
    }];
}

- (void)scrubbingEnd
{
    float afterSeekTime = self.jdView.scrubber.value;
    @weakify(self)
    [self seekToTimeInSecond:afterSeekTime userAction:YES completionHandler:^(BOOL finished) {
        @strongify(self)
        self.scrubbing = NO;
        if (finished)
        {
            [self playContent];
        }
    }];
}

- (void)seekToTimeInSecond:(float)sec userAction:(BOOL)isUserAction completionHandler:(void (^)(BOOL finished))completionHandler
{
    [self.avPlayer seekToTimeInSeconds:sec completionHandler:completionHandler];
}

- (BOOL)isPlayingVideo
{
    return (self.avPlayer && self.avPlayer.rate != 0.0);
}

- (NSTimeInterval)currentTime
{
    return CMTimeGetSeconds([self.avPlayer currentCMTime]);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.avPlayer   = nil;
    self.playerItem = nil;
}

- (void)handleErrorCode:(JDPlayerErrorCode)errorCode videoModel:(JDVideoModel *)videoModel
{
    [self handleErrorCode:errorCode videoModel:videoModel customMessage:nil];
}

- (void)handleErrorCode:(JDPlayerErrorCode)errorCode videoModel:(JDVideoModel *)videoModel customMessage:(NSString *)customMessage
{
    self.state = JDPlayerStateError;

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(handleErrorCode:videoModel:customMessage:)])
        {
            [self.delegate handleErrorCode:errorCode videoModel:videoModel customMessage:customMessage];
        }
    });
}

- (JDPlayerView *)jdView
{
    if(!_jdView)
    {
        _jdView = [[JDPlayerView alloc]init];
        _jdView.delegate = self;
        _jdView.scrubber.delegate = self;
    }
    
    return _jdView;
}

#pragma mark -- JDPlayerView delegate
- (void)didFullScreenButtonPressed
{}

- (void)didPlayButtonPressed
{
    if(self.jdView.playButton.isSelected)
    {
        //last state is paused
        [self playContent];
    }
    else
    {
        //last state is play
        [self pauseContent];
    }
    [self.jdView.playButton setSelected:!self.jdView.playButton.isSelected];
}

- (void)didNextVideoButtonPressed
{
    if ([self.delegate respondsToSelector:@selector(videoPlayer:didNextVideoButtonPressed:)]) {
        [self.delegate videoPlayer:self didNextVideoButtonPressed:self.jdView.videoModel];
    }
}

- (void)didPreviousVideoButtonPressed
{
    if([self.delegate respondsToSelector:@selector(videoPlayer:didPreviousVideoButtonPressed:)])
    {
        [self.delegate videoPlayer:self didPreviousVideoButtonPressed:self.jdView.videoModel];
    }
}

- (void)didRewindButtonPressed
{
    if([self currentTime] >= 30.0f)
    {
        float afterSeekTime = [self currentTime] - 30.0f;

        if(isfinite(afterSeekTime))
        {
            @weakify(self)
            [self seekToTimeInSecond:afterSeekTime userAction:YES completionHandler:^(BOOL finished) {
                @strongify(self)
                if (finished)
                {
                    [self playContent];
                }
            }];
        }
    }
}

- (void)didDoneButtonPressed
{
    if(self.jdView.isFullScreen)
    {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    }
    else
    {
        UINavigationController* nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        [nav popViewControllerAnimated:YES];
    }
}

- (void)didSwipingHorizontal
{}

- (void)didEndSwipeHorizontal:(float)seekTime
{
    @weakify(self)
    [self seekToTimeInSecond:seekTime userAction:YES completionHandler:^(BOOL finished){
        @strongify(self)
        if (finished)
        {
            [self playContent];
        }
    }];
}

- (float)didBeginSwipeHorizontal
{
    self.jdView.countdownToHide = 0;
    [self pauseContent];

    return [self currentTime];
}

#pragma mark -- scrubber delegate
- (void)scrubberDidBeginScrubbing:(JDScrubber*)scrubber
{
    [self scrubbingBegin];
}

- (void)scrubberDidEndScrubbing:(JDScrubber*)scrubber
{
    [self scrubbingEnd];
}

- (void)scrubberValueDidChange:(JDScrubber*)scrubber
{
    if(self.scrubbing)
    {
        self.jdView.currentTimeLabel.text = [JDPlayerView timeStringFromSecondsValue:(int)scrubber.value];
    }
}

@end
