//
//  JDPlayerView.h
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JDVideoModel;
@class JDScrubber;
@class JDVideoPlayLayerView;

extern NSString* kJDDurationDidLoadNotification;
extern NSString* kJDScrubberValueUpdatedNotification;

@protocol JDPlayerViewDelegate<NSObject>
@optional
- (void)didFullScreenButtonPressed;
- (void)didPlayButtonPressed;
- (void)didNextVideoButtonPressed;
- (void)didPreviousVideoButtonPressed;
- (void)didRewindButtonPressed;
- (void)didDoneButtonPressed;
- (void)didSwipingHorizontal;
- (void)didVideoQualityButtonPressed;

@required
- (float)didBeginSwipeHorizontal;
- (void)didEndSwipeHorizontal:(float)seekTime;
@end

@interface JDPlayerView : UIView

@property (nonatomic, strong) JDVideoModel* videoModel;
@property (nonatomic, assign) NSInteger countdownToHide;
@property (nonatomic, weak) id<JDPlayerViewDelegate> delegate;

@property (nonatomic, strong) UIButton* doneButton;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UIButton* rewindButton;
@property (nonatomic, strong) UIButton* nextButton;

@property (nonatomic, strong) UIButton* playButton;
@property (nonatomic, strong) UILabel* currentTimeLabel;
@property (nonatomic, strong) JDScrubber* scrubber;
@property (nonatomic, strong) UILabel* totalTimeLabel;
@property (nonatomic, strong) UIButton* fullscreenButton;
@property (nonatomic, strong) UILabel* seekTimeLabel;

@property (nonatomic, strong) JDVideoPlayLayerView* playerLayerView;

@property (nonatomic, assign) UIInterfaceOrientation visibleInterfaceOrientation;
@property (nonatomic, assign) UIInterfaceOrientationMask supportedOrientations;

@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) CGRect portraitFrame;
@property (nonatomic, assign) CGRect landscapeFrame;

@property (nonatomic, assign) BOOL isControlsEnabled;
@property (nonatomic, assign) BOOL isControlsHidden;

- (void)startLoading;
- (void)stopLoading;
- (void)reset;

- (void)setControlsEnabled:(BOOL)enabled;
- (void)setControlsHidden:(BOOL)hidden;
- (void)hideControlsIfNecessary;
- (void)layoutForOrientation:(UIInterfaceOrientation)interfaceOrientation;

- (void)addSubviewForControl:(UIView *)view;
- (void)addSubviewForControl:(UIView *)view toView:(UIView*)parentView;
- (void)addSubviewForControl:(UIView *)view toView:(UIView*)parentView forOrientation:(UIInterfaceOrientationMask)orientation;
- (void)removeControlView:(UIView*)view;
+ (NSString *)timeStringFromSecondsValue:(int)seconds;

@end
