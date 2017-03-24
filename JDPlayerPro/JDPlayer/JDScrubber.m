//
//  JDScrubber.m
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import "JDScrubber.h"
#import "Masonry.h"
#import "ReactiveCocoa.h"

@implementation JDScrubber

- (instancetype)init
{
    self = [super init];

    if(self)
    {
        [self setThumbImage:[UIImage imageNamed:@"jd_scrubber_thumb"] forState:UIControlStateNormal];

        [self addSubview:self.cacheProgressView];
        [self sendSubviewToBack:self.cacheProgressView];

        [self.cacheProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(1.0f);
            make.left.equalTo(self).offset(2.0f);
            make.right.equalTo(self).offset(-2.0f);
            make.centerY.equalTo(self);
        }];

        [self addObserver];
        self.minimumTrackTintColor = [UIColor blueColor];
        self.maximumTrackTintColor = [UIColor clearColor];
    }

    return self;
}

- (void)addObserver
{
    @weakify(self)
    [[[self rac_signalForControlEvents:UIControlEventTouchDown]
      takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(id x) {
         @strongify(self)
         if([self.delegate respondsToSelector:@selector(scrubberDidBeginScrubbing:)])
         {
             [self.delegate scrubberDidBeginScrubbing:self];
         }
     }];

    [[[self rac_signalForControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel]
      takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(id x) {
         @strongify(self)
         if([self.delegate respondsToSelector:@selector(scrubberDidEndScrubbing:)])
         {
             [self.delegate scrubberDidEndScrubbing:self];
         }
     }];

    [[[self rac_signalForControlEvents:UIControlEventValueChanged]
      takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(id x) {
         @strongify(self)
         if([self.delegate respondsToSelector:@selector(scrubberValueDidChange:)])
         {
             [self.delegate scrubberValueDidChange:self];
         }
     }];

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(progressValueUpdated:) name:kJDProgressValueUpdatedNotification object:nil];
}

- (void)progressValueUpdated:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSNumber* progressValue = info[@"progressValue"];

    [self.cacheProgressView setProgress:progressValue.floatValue animated:YES];
}

- (void)setValue:(float)value animated:(BOOL)animated
{
    [super setValue:value animated:animated];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (UIProgressView *)cacheProgressView
{
    if(!_cacheProgressView)
    {
        _cacheProgressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        _cacheProgressView.trackTintColor    = [UIColor grayColor];
        _cacheProgressView.progressTintColor = [UIColor orangeColor];
        _cacheProgressView.userInteractionEnabled = NO;
    }
    
    return _cacheProgressView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
