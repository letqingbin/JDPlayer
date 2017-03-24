//
//  JDVideoModel.h
//  JDVideoPro
//
//  Created by depa on 2017/3/22.
//  Copyright © 2017年 depa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JDVideoModel : NSObject

@property(nonatomic, copy) NSString* title;

@property(nonatomic, assign) BOOL hasNext;
@property(nonatomic, assign) BOOL hasPrevious;
@property(nonatomic, assign) BOOL isPlayedToEnd;
@property(nonatomic, assign) BOOL canSeekToTime;

@property(nonatomic, strong) NSURL* streamURL;
@property(nonatomic, assign) float totalVideoDuration;
@property(nonatomic, assign) float lastDurationWatchedInSeconds;

@end
