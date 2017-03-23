//
//  JDScrubber.h
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JDScrubber;
@class JDVideoPlayLayerView;

extern NSString* kJDProgressValueUpdatedNotification;

@protocol JDScrubberDelegate <NSObject>
@optional
- (void)scrubberDidBeginScrubbing:(JDScrubber*)scrubber;
- (void)scrubberDidEndScrubbing:(JDScrubber*)scrubber;
- (void)scrubberValueDidChange:(JDScrubber*)scrubber;
@end

@interface JDScrubber : UISlider
@property (nonatomic, weak) id <JDScrubberDelegate> delegate;
@property (nonatomic, strong) UIProgressView* cacheProgressView;
@end
