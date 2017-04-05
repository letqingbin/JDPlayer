# JDPlayer
A video player for iOS based on AVFoundation,JDPlayer is powerful and easy to integrate in your project.


## Features

- orientation change support
- support change small screen to full screen or vice versa
- play local or remote media over HTTP
- easy to customizable UI and user interaction
- support horizontal slide and horizontal gesture to fast forward or backward the playing media
- support vertical slide to change the volume and brightness
- so many delegate callbacks
- pure objective-c code

## Quick Try
To run the Demo project; clone the repo,open JDPlayerPro.xcodeproj in Xcode to run Demo Application.

### Getting Start
```objective-c
JDVideoModel* videoModel = [[JDVideoModel alloc]init];
videoModel.streamURL = [NSURL URLWithString:@"assetUrl..."];
JDPlayer* player = [[JDPlayer alloc] init];
player.delegate = self;
[player loadVideoModel:videoModel];
```

## Customize
JDPlayer has simple way for customize your own controls.
```objective-c
- (void)addSubviewForControl:(UIView *)view;
- (void)addSubviewForControl:(UIView *)view toView:(UIView*)parentView;
- (void)addSubviewForControl:(UIView *)view toView:(UIView*)parentView forOrientation:(UIInterfaceOrientationMask)orientation;
```

## Callbacks
```objective-c
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
```

## How to change video quality?

### First
IN JDPlayerView, you should custom your own control(such as button),and invoke 
```
- (void)didVideoQualityButtonPressed;
```
in button's control events(such as UIControlEventTouchUpInside);

### Second
IN your own Controller,change video quality in delegate
```
- (void)videoPlayer:(JDPlayer *)videoPlayer didVideoQualityButtonPressed:(JDVideoModel *)videoModel;
```

## License

JDPlayer is released under the MIT license. See LICENSE for details.

