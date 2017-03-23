//
//  JDPlayerView.m
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import "JDPlayerView.h"
#import "JDScrubber.h"
#import "JDVideoModel.h"
#import "JDVideoPlayLayerView.h"

#import "Masonry.h"
#import "ReactiveCocoa.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface JDPlayerView()
@property (nonatomic, strong) NSMutableArray* customControls;
@property (nonatomic, strong) NSMutableArray* portraitControls;
@property (nonatomic, strong) NSMutableArray* landscapeControls;

@property (nonatomic, strong) UIView* topOverlayView;
@property (nonatomic, strong) UIView* bottomOverlayView;

@property (nonatomic, strong) UIActivityIndicatorView* indicatorView;

@property (nonatomic, assign) BOOL isDirectionHorizontal;
@property (nonatomic, strong) UISlider* volumeViewSlider;
@property (nonatomic, assign) float seekTime;
@end

@implementation JDPlayerView

- (instancetype)init
{
    self = [super init];

    if(self)
    {
        [self initProperty];
        [self addChildSubviews];
        [self addChildConstraints];
        [self addObserver];
        [self addGesture];
        self.backgroundColor = [UIColor blackColor];
    }

    return self;
}

- (void)addChildSubviews
{
    if(self.fullscreenButton.isSelected)
    {
        // full screen
        self.playerLayerView.frame = self.landscapeFrame;
    }
    else
    {
        // small screen
        self.playerLayerView.frame = self.portraitFrame;
    }

    [self addSubview:self.playerLayerView];

    [self addSubviewForControl:self.topOverlayView];
    [self addSubviewForControl:self.bottomOverlayView];

    [self addSubviewForControl:self.doneButton toView:self.topOverlayView];
    [self addSubviewForControl:self.titleLabel toView:self.topOverlayView];
    [self addSubviewForControl:self.rewindButton toView:self.topOverlayView];
    [self addSubviewForControl:self.nextButton toView:self.topOverlayView];

    [self addSubviewForControl:self.playButton toView:self.bottomOverlayView];
    [self addSubviewForControl:self.currentTimeLabel toView:self.bottomOverlayView];
    [self addSubviewForControl:self.scrubber toView:self.bottomOverlayView];
    [self addSubviewForControl:self.totalTimeLabel toView:self.bottomOverlayView];
    [self addSubviewForControl:self.fullscreenButton toView:self.bottomOverlayView];

    [self addSubviewForControl:self.indicatorView];
    [self addSubviewForControl:self.seekTimeLabel];
}

- (void)addChildConstraints
{
    [self.topOverlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(44.0f);
    }];

    [self.bottomOverlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.equalTo(self);
        make.height.mas_equalTo(44.0f);
    }];

    [self.doneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topOverlayView);
        make.centerY.equalTo(self.topOverlayView);
        make.size.mas_equalTo(CGSizeMake(40.0f, 40.0f));
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.topOverlayView);
        make.left.equalTo(self.doneButton.mas_right);
    }];

    [self.rewindButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.nextButton.mas_left);
        make.centerY.equalTo(self.topOverlayView);
        make.size.mas_equalTo(CGSizeMake(40.0f, 40.0f));
    }];

    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topOverlayView);
        make.centerY.equalTo(self.topOverlayView);
        make.size.mas_equalTo(CGSizeMake(40.0f, 40.0f));
    }];

    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomOverlayView);
        make.centerY.equalTo(self.bottomOverlayView);
        make.size.mas_equalTo(CGSizeMake(40.0f, 40.0f));
    }];

    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playButton.mas_right);
        make.centerY.equalTo(self.bottomOverlayView);
    }];

    [self.scrubber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentTimeLabel.mas_right).offset(10.0f);
        make.centerY.equalTo(self.bottomOverlayView);
        make.right.equalTo(self.totalTimeLabel.mas_left).offset(-10.0f);
    }];

    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomOverlayView);
        make.right.equalTo(self.fullscreenButton.mas_left);
    }];

    [self.fullscreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomOverlayView);
        make.centerY.equalTo(self.bottomOverlayView);
        make.size.mas_equalTo(CGSizeMake(40.0f, 40.0f));
    }];

    [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self);
    }];

    [self.seekTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self);
    }];

    [self.currentTimeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.currentTimeLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    [self.scrubber setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.scrubber setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.totalTimeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.totalTimeLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)addObserver
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [defaultCenter addObserver:self selector:@selector(durationDidLoad:) name:kJDDurationDidLoadNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(scrubberValueUpdated:) name:kJDScrubberValueUpdatedNotification object:nil];
}

- (void)initProperty
{
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self.portraitFrame  = CGRectMake(0, 0, MIN(bounds.size.width, bounds.size.height), MAX(bounds.size.width, bounds.size.height));
    self.landscapeFrame = CGRectMake(0, 0, MAX(bounds.size.width, bounds.size.height), MIN(bounds.size.width, bounds.size.height));

    self.seekTime                    = 0.0f;
    self.countdownToHide             = 5;
    self.supportedOrientations       = UIInterfaceOrientationMaskAllButUpsideDown;
    self.visibleInterfaceOrientation = UIInterfaceOrientationPortrait;

    self.isFullScreen = NO;
    self.isControlsHidden  = NO;
    self.isControlsEnabled = YES;
    self.isDirectionHorizontal = NO;

    [self.scrubber setValue:0.0f animated:NO];
}

- (void)setIsFullScreen:(BOOL)isFullScreen
{
    _isFullScreen = isFullScreen;

    if(self.isFullScreen)
    {
        self.playerLayerView.frame = self.landscapeFrame;
        self.frame = self.landscapeFrame;
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];

        self.visibleInterfaceOrientation = UIInterfaceOrientationLandscapeRight;
        [self layoutForOrientation:UIInterfaceOrientationLandscapeRight];
    }
    else
    {
        self.playerLayerView.frame = self.portraitFrame;
        self.frame = self.portraitFrame;
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];

        self.visibleInterfaceOrientation = UIInterfaceOrientationPortrait;
        [self layoutForOrientation:UIInterfaceOrientationPortrait];
    }

    self.fullscreenButton.selected = NO;
}

- (void)addGesture
{
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]init];
    [self.playerLayerView addGestureRecognizer:tap];

    @weakify(self)
    [tap.rac_gestureSignal subscribeNext:^(id x) {
        @strongify(self)

        if(!self.isControlsEnabled) return;

        [self setControlsHidden:!self.isControlsHidden];
        if (!self.isControlsHidden)
        {
            self.countdownToHide = 5;
        }
    }];

    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc]init];
    pan.minimumNumberOfTouches = 1;
    pan.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:pan];

    [pan.rac_gestureSignal subscribeNext:^(UIPanGestureRecognizer* gesture) {
        @strongify(self)

        if(!self.isControlsEnabled
           || !self.videoModel.canSeekToTime) return;

        CGPoint velocityPt  = [gesture velocityInView:gesture.view];
        switch (gesture.state) {
            case UIGestureRecognizerStateBegan:
            {
                if(fabs(velocityPt.x) <= fabs(velocityPt.y))
                {
                    //vertical
                    self.isDirectionHorizontal = NO;
                }
                else
                {
                    //horizontal
                    self.isDirectionHorizontal = YES;
                    self.seekTimeLabel.hidden = NO;

                    if([self.delegate respondsToSelector:@selector(didBeginSwipeHorizontal)])
                    {
                        self.seekTime = [self.delegate didBeginSwipeHorizontal];
                    }
                }

                break;
            }

            case UIGestureRecognizerStateChanged:
            {
                if(!self.isDirectionHorizontal)
                {
                    //vertical
                    self.volumeViewSlider.value -= velocityPt.y / 10000.0f;
                }
                else
                {
                    //horizontal
                    self.seekTime += velocityPt.x / 300.0f;

                    if(self.seekTime <= 0.0f)
                    {
                        self.seekTime = 0.0f;
                    }
                    if(self.seekTime >= self.videoModel.totalVideoDuration.floatValue)
                    {
                        self.seekTime = self.videoModel.totalVideoDuration.floatValue;
                    }

                    self.seekTimeLabel.text = [NSString stringWithFormat:@"%@ / %@",[JDPlayerView timeStringFromSecondsValue:(int)self.seekTime],[JDPlayerView timeStringFromSecondsValue:self.videoModel.totalVideoDuration.intValue]];

                    if([self.delegate respondsToSelector:@selector(didSwipingHorizontal)])
                    {
                        [self.delegate didSwipingHorizontal];
                    }
                }

                break;
            }

            case UIGestureRecognizerStateEnded:
            {
                if(!self.isDirectionHorizontal)
                {
                    //vertical
                }
                else
                {
                    //horizontal
                    self.seekTimeLabel.hidden = YES;

                    if([self.delegate respondsToSelector:@selector(didEndSwipeHorizontal:)])
                    {
                        [self.delegate didEndSwipeHorizontal:self.seekTime];
                    }
                }

                break;
            }

            default:
                break;
        }
    }];
}

#pragma mark - Orientation
- (void)orientationChanged:(NSNotification *)note
{
    if(self.fullscreenButton.isSelected) return;

    UIDevice * device = note.object;

    UIInterfaceOrientation rotateToOrientation;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            rotateToOrientation = UIInterfaceOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotateToOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotateToOrientation = UIInterfaceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            rotateToOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        default:
            rotateToOrientation = self.visibleInterfaceOrientation;
            break;
    }

    if ((1 << rotateToOrientation) & self.supportedOrientations && rotateToOrientation != self.visibleInterfaceOrientation)
    {
        self.isFullScreen = UIInterfaceOrientationIsLandscape(rotateToOrientation);
    }
}

- (void)layoutForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        for (UIView *control in self.portraitControls)
        {
            control.hidden = self.isControlsHidden;
        }

        for (UIView *control in self.landscapeControls)
        {
            control.hidden = YES;
        }
    }
    else
    {
        for (UIView *control in self.portraitControls)
        {
            control.hidden = YES;
        }

        for (UIView *control in self.landscapeControls)
        {
            control.hidden = self.isControlsHidden;
        }
    }
}

- (void)durationDidLoad:(NSNotification *)notification
{
    //kJDDurationDidLoadNotification
    NSDictionary *info = [notification userInfo];
    NSNumber* duration = [info objectForKey:@"duration"];
    self.videoModel.totalVideoDuration = duration;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.scrubber.maximumValue = [duration floatValue];
        self.scrubber.hidden = NO;
    });
}

- (void)scrubberValueUpdated:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat currentTime = [[info objectForKey:@"scrubberValue"] floatValue];
        [self.scrubber setValue:currentTime animated:YES];
        self.currentTimeLabel.text = [JDPlayerView timeStringFromSecondsValue:(int)currentTime];
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[JDScrubber class]] ||
        [touch.view isKindOfClass:[UIButton class]])
    {
        // prevent recognizing touches on the slider
        return NO;
    }

    return YES;
}

- (void)hideControlsIfNecessary
{
    if (self.isControlsHidden) return;

    if (self.countdownToHide == -1)
    {
        [self setIsControlsHidden:NO];
    }
    else if (self.countdownToHide == 0)
    {
        [self setIsControlsHidden:YES];
    }
    else
    {
        self.countdownToHide--;
    }
}

- (void)setControlsHidden:(BOOL)hidden
{
    if (self.isControlsHidden != hidden)
    {
        self.isControlsHidden = hidden;

        if (UIInterfaceOrientationIsLandscape(self.visibleInterfaceOrientation))
        {
            for (UIView *control in self.landscapeControls)
            {
                control.hidden = hidden;
            }
        }

        if (UIInterfaceOrientationIsPortrait(self.visibleInterfaceOrientation))
        {
            for (UIView *control in self.portraitControls)
            {
                control.hidden = hidden;
            }
        }

        for (UIView *control in self.customControls)
        {
            if([control isEqual:self.indicatorView]
               || [control isEqual:self.seekTimeLabel]) continue;
            control.hidden = hidden;
        }
    }
}

- (void)setControlsEnabled:(BOOL)enabled
{
    self.scrubber.enabled     = enabled && self.videoModel.canSeekToTime;
    self.playButton.enabled   = enabled;
    self.nextButton.enabled   = enabled && self.videoModel.hasNext;
    self.rewindButton.enabled = enabled;
    self.fullscreenButton.enabled = enabled;

    self.isControlsEnabled = enabled;

    NSMutableArray *controlList = self.customControls.mutableCopy;
    [controlList addObjectsFromArray:self.portraitControls];
    [controlList addObjectsFromArray:self.landscapeControls];

    for (UIView *control in controlList)
    {
        if ([control isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton*)control;
            button.enabled = enabled;
        }
    }
}

- (void)setcountdownToHide:(NSInteger)countdownToHide
{
    _countdownToHide = countdownToHide;
    if (countdownToHide == 0)
    {
        //if countdownToHide = 0,then hide all controls
        [self setControlsHidden:YES];
    }
    else
    {
        //if countdownToHide != 0,then show all controls
        [self setControlsHidden:NO];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addSubviewForControl:(UIView *)view
{
    [self addSubviewForControl:view toView:self];
}

- (void)addSubviewForControl:(UIView *)view toView:(UIView*)parentView
{
    [self addSubviewForControl:view toView:parentView forOrientation:UIInterfaceOrientationMaskAll];
}

- (void)addSubviewForControl:(UIView *)view toView:(UIView*)parentView forOrientation:(UIInterfaceOrientationMask)orientation
{
    if([view isEqual:self.indicatorView] || [view isEqual:self.seekTimeLabel])
    {
    }
    else
    {
        view.hidden = self.isControlsHidden;
    }

    if (orientation == UIInterfaceOrientationMaskAll)
    {
        [self.customControls addObject:view];
    }
    else if (orientation == UIInterfaceOrientationMaskPortrait)
    {
        [self.portraitControls addObject:view];
    }
    else if (orientation == UIInterfaceOrientationMaskLandscape)
    {
        [self.landscapeControls addObject:view];
    }

    [parentView addSubview:view];
}

- (void)removeControlView:(UIView*)view
{
    [view removeFromSuperview];
    [self.customControls removeObject:view];
    [self.landscapeControls removeObject:view];
    [self.portraitControls removeObject:view];
}

- (UIView *)topOverlayView
{
    if(!_topOverlayView)
    {
        _topOverlayView = [[UIView alloc]init];
        _topOverlayView.backgroundColor = [UIColor clearColor];
    }

    return _topOverlayView;
}

- (UIView *)bottomOverlayView
{
    if(!_bottomOverlayView)
    {
        _bottomOverlayView = [[UIView alloc]init];
        _bottomOverlayView.backgroundColor = [UIColor clearColor];
    }

    return _bottomOverlayView;
}

-(UIButton *)doneButton
{
    if(!_doneButton)
    {
        _doneButton = [[UIButton alloc]init];
        [_doneButton setImage:[UIImage imageNamed:@"jd_done_icon"] forState:UIControlStateNormal];

        @weakify(self)
        [[_doneButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
            @strongify(self)
            if([self.delegate respondsToSelector:@selector(didDoneButtonPressed)])
            {
                [self.delegate didDoneButtonPressed];
            }
        }];
    }

    return _doneButton;
}

-(UIButton *)rewindButton
{
    if(!_rewindButton)
    {
        _rewindButton = [[UIButton alloc]init];
        [_rewindButton setImage:[UIImage imageNamed:@"jd_rewind_icon"] forState:UIControlStateNormal];

        @weakify(self)
        [[_rewindButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
            @strongify(self)
            if([self.delegate respondsToSelector:@selector(didRewindButtonPressed)])
            {
                [self.delegate didRewindButtonPressed];
            }
        }];
    }

    return _rewindButton;
}

-(UIButton *)nextButton
{
    if(!_nextButton)
    {
        _nextButton = [[UIButton alloc]init];
        [_nextButton setImage:[UIImage imageNamed:@"jd_next_icon"] forState:UIControlStateNormal];

        @weakify(self)
        [[_nextButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
            @strongify(self)
            if([self.delegate respondsToSelector:@selector(didNextVideoButtonPressed)])
            {
                [self.delegate didNextVideoButtonPressed];
            }
        }];
    }

    return _nextButton;
}

-(UIButton *)playButton
{
    if(!_playButton)
    {
        _playButton = [[UIButton alloc]init];
        [_playButton setImage:[UIImage imageNamed:@"jd_play_icon"] forState:UIControlStateNormal];      //play  - no select
        [_playButton setImage:[UIImage imageNamed:@"jd_pause_icon"] forState:UIControlStateSelected];   //pause - selected

        @weakify(self)
        [[_playButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
            @strongify(self)
            if([self.delegate respondsToSelector:@selector(didPlayButtonPressed)])
            {
                [self.delegate didPlayButtonPressed];
            }
        }];
    }

    return _playButton;
}

-(UIButton *)fullscreenButton
{
    if(!_fullscreenButton)
    {
        _fullscreenButton = [[UIButton alloc]init];
        [_fullscreenButton setImage:[UIImage imageNamed:@"jd_fullscreen_icon"] forState:UIControlStateNormal];

        @weakify(self)
        [[_fullscreenButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
            @strongify(self)

            self.countdownToHide = -1;
            self.fullscreenButton.selected = YES;
            self.isFullScreen = !self.isFullScreen;
            self.countdownToHide = 5;

            if([self.delegate respondsToSelector:@selector(didFullScreenButtonPressed)])
            {
                [self.delegate didFullScreenButtonPressed];
            }
        }];
    }

    return _fullscreenButton;
}

- (JDScrubber *)scrubber
{
    if(!_scrubber)
    {
        _scrubber = [[JDScrubber alloc]init];
        _scrubber.enabled = self.videoModel.canSeekToTime;

        @weakify(self)
        [[[RACObserve(_scrubber,maximumValue) distinctUntilChanged]
         takeUntil:self.rac_willDeallocSignal]
         subscribeNext:^(id x) {
             @strongify(self)
             self.currentTimeLabel.text = [JDPlayerView timeStringFromSecondsValue:(int)self.scrubber.value];
             self.totalTimeLabel.text   = [JDPlayerView timeStringFromSecondsValue:(int)self.scrubber.maximumValue];
             self.seekTimeLabel.text    = [NSString stringWithFormat:@"%@ / %@",[JDPlayerView timeStringFromSecondsValue:self.seekTime],[JDPlayerView timeStringFromSecondsValue:(int)self.scrubber.maximumValue]];
         }];
    }

    return _scrubber;
}

- (UILabel *)titleLabel
{
    if(!_titleLabel)
    {
        _titleLabel = [JDPlayerView createLabelWithFrame:CGRectZero
                                                        title:@" "
                                                    textColor:[UIColor whiteColor]
                                                      bgColor:[UIColor clearColor]
                                                     fontSize:14.0f
                                                textAlignment:NSTextAlignmentLeft
                                                    addToView:nil
                                                        bBold:NO];
        _titleLabel.numberOfLines = 1;
    }

    return _titleLabel;
}

- (UILabel *)currentTimeLabel
{
    if(!_currentTimeLabel)
    {
        _currentTimeLabel = [JDPlayerView createLabelWithFrame:CGRectZero
                                                              title:[JDPlayerView timeStringFromSecondsValue:0]
                                                          textColor:[UIColor whiteColor]
                                                            bgColor:[UIColor clearColor]
                                                           fontSize:12.0f
                                                      textAlignment:NSTextAlignmentLeft
                                                          addToView:nil
                                                              bBold:NO];
        _currentTimeLabel.numberOfLines = 1;
    }

    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel
{
    if(!_totalTimeLabel)
    {
        _totalTimeLabel = [JDPlayerView createLabelWithFrame:CGRectZero
                                                            title:[JDPlayerView timeStringFromSecondsValue:0]
                                                        textColor:[UIColor whiteColor]
                                                          bgColor:[UIColor clearColor]
                                                         fontSize:12.0f
                                                    textAlignment:NSTextAlignmentLeft
                                                        addToView:nil
                                                            bBold:NO];
        _totalTimeLabel.numberOfLines = 1;
    }

    return _totalTimeLabel;
}

- (JDVideoPlayLayerView *)playerLayerView
{
    if(!_playerLayerView)
    {
        _playerLayerView = [[JDVideoPlayLayerView alloc]init];
        [_playerLayerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
    }

    return _playerLayerView;
}

- (UIActivityIndicatorView *)indicatorView
{
    if(!_indicatorView)
    {
        _indicatorView = [[UIActivityIndicatorView alloc]init];
        _indicatorView.hidden = YES;
    }

    return _indicatorView;
}

- (UISlider *)volumeViewSlider
{
    if(!_volumeViewSlider)
    {
        MPVolumeView* volumeView = [[MPVolumeView alloc] init];

        for (UIView *view in [volumeView subviews])
        {
            if ([view.class.description isEqualToString:@"MPVolumeSlider"])
            {
                _volumeViewSlider = (UISlider*)view;
                break;
            }
        }
    }

    return _volumeViewSlider;
}

- (UILabel *)seekTimeLabel
{
    if(!_seekTimeLabel)
    {
        _seekTimeLabel = [JDPlayerView createLabelWithFrame:CGRectZero
                                                           title:[NSString stringWithFormat:@"%@ / %@",[JDPlayerView timeStringFromSecondsValue:(int)self.seekTime],[JDPlayerView timeStringFromSecondsValue:self.videoModel.totalVideoDuration.intValue]]
                                                       textColor:[UIColor whiteColor]
                                                         bgColor:[UIColor clearColor]
                                                        fontSize:25.0f
                                                   textAlignment:NSTextAlignmentLeft
                                                       addToView:nil
                                                           bBold:NO];
        _seekTimeLabel.numberOfLines = 1;
        _seekTimeLabel.hidden = YES;
    }

    return _seekTimeLabel;
}

- (void) setVideoModel:(JDVideoModel *)videoModel
{
    _videoModel = videoModel;
    self.titleLabel.text    = videoModel.title;
    self.nextButton.enabled = videoModel.hasNext && self.isControlsEnabled;
}

- (NSMutableArray *)customControls
{
    if(!_customControls)
    {
        _customControls = [NSMutableArray array];
    }

    return _customControls;
}

- (NSMutableArray *)portraitControls
{
    if(!_portraitControls)
    {
        _portraitControls = [NSMutableArray array];
    }

    return _portraitControls;
}

- (NSMutableArray *)landscapeControls
{
    if(!_landscapeControls)
    {
        _landscapeControls = [NSMutableArray array];
    }

    return _landscapeControls;
}

- (void)startLoading
{
    [self.indicatorView startAnimating];
    self.indicatorView.hidden = NO;
}

- (void)stopLoading
{
    [self.indicatorView stopAnimating];
    self.indicatorView.hidden = YES;
}

+ (UILabel *)createLabelWithFrame:(CGRect)rect
                            title:(NSString *)title
                        textColor:(UIColor *)textColor
                          bgColor:(UIColor *)bgColor
                         fontSize:(CGFloat)fontSize
                    textAlignment:(NSTextAlignment)textAlignment
                        addToView:(UIView *)view
                            bBold:(BOOL)bBold
{
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    label.backgroundColor = bgColor;

    if (bBold)
    {
        label.font = [UIFont boldSystemFontOfSize:fontSize];
    }
    else
    {
        label.font = [UIFont systemFontOfSize:fontSize];
    }

    label.textColor = textColor;
    label.text = title;
    label.textAlignment = textAlignment;
    [view addSubview:label];
    
    if (CGRectEqualToRect(rect, CGRectZero) || CGRectEqualToRect(rect, CGRectNull))
    {
        [label sizeToFit];
    }
    
    return label;
}

+ (NSString *)timeStringFromSecondsValue:(int)seconds
{
    NSString *retVal;
    int hours = seconds / 3600;
    int minutes = (seconds / 60) % 60;
    int secs = seconds % 60;
    
    if (hours > 0)
    {
        retVal = [NSString stringWithFormat:@"%01d:%02d:%02d", hours, minutes, secs];
    }
    else
    {
        retVal = [NSString stringWithFormat:@"%02d:%02d", minutes, secs];
    }
    
    return retVal;
}

@end
