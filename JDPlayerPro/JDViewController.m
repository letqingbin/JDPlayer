//
//  JDViewController.m
//  JDPlayerPro
//
//  Created by depa on 2017/3/23.
//  Copyright © 2017年 depa. All rights reserved.
//

#import "JDViewController.h"
#import "JDVideoModel.h"
#import "JDPlayerView.h"
#import "JDPlayer.h"

@interface JDViewController ()<JDPlayerDelegate>
@property(nonatomic,assign) BOOL applicationIdleTimerDisabled;
@property(nonatomic,strong) AVPlayer* avPlayer;

@property(nonatomic,strong) NSArray* testUrls;
@property(nonatomic,assign) NSInteger currentIndex;

@property(nonatomic,strong) JDPlayer* player;
@property(nonatomic,assign) BOOL shouldRotate;
@end

@implementation JDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.currentIndex = 0;
    self.testUrls = @[
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_856a6738eefc495bbd7b0ed59beaa9fe",
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_e05f72400bae4e0b8ae6825c5891af64",
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_f905cb3d6a1847afb071b3aeea42eb51",
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_57dad11ccfd3422cbe6f0b2674fa0ab1",
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_b5b00d7e77854a2ea478cd5dd648191d",
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_d7c0843949284cb79a8f4bed20111577",
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_34dd3f3f36974092876efbcac1d1160d",
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_42b791e5aed7463b865518378a78de6a",
                      @"http://7xs8ft.com2.z0.glb.qiniucdn.com/rcd_vid_03e0b80cc69b4f069af9b5ba88be6752",
                      @"http://7xjw4n.com2.z0.glb.qiniucdn.com/oPMsZg4gkav4-UZpazxeUmPMGd8=/lgcQ-ZTLn0Q96MOKhkXvI1PdALvJ",
                      @"http://zyvideo1.oss-cn-qingdao.aliyuncs.com/zyvd/7c/de/04ec95f4fd42d9d01f63b9683ad0"
                      ];


    self.shouldRotate = YES;
    [self playVideo];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.applicationIdleTimerDisabled = [UIApplication sharedApplication].isIdleTimerDisabled;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [UIApplication sharedApplication].idleTimerDisabled = self.applicationIdleTimerDisabled;
    [super viewWillDisappear:animated];

    self.navigationController.navigationBarHidden = NO;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

//- (UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}

- (void)playVideo
{
    JDVideoModel* videoModel = [[JDVideoModel alloc]init];
    videoModel.streamURL = [NSURL URLWithString:self.testUrls[self.currentIndex++]];

    [self.player loadVideoModel:videoModel];
}

#pragma mark - App States

- (void)applicationWillResignActive
{
    self.player.jdView.countdownToHide = -1;

    if (self.player.state == JDPlayerStatePlaying)
    {
        [self.player pauseContent:NO recordLastWatchedTime:NO completionHandler:nil];
    }
}

- (void)applicationDidBecomeActive
{
    self.player.jdView.countdownToHide = -1;
}

- (void)videoPlayer:(JDPlayer*)videoPlayer didPlayToEnd:(JDVideoModel *)videoModel
{
    if(self.currentIndex < self.testUrls.count)
    {
        JDVideoModel* nextTrack = [[JDVideoModel alloc]init];
        nextTrack.streamURL = [NSURL URLWithString:self.testUrls[self.currentIndex++]];

        if(self.currentIndex == self.testUrls.count - 1)
        {
            nextTrack.hasNext = NO;
        }
        else
        {
            nextTrack.hasNext = YES;
        }

        [self.player loadVideoModel:nextTrack];
    }
}

- (void) videoPlayer:(JDPlayer *)videoPlayer didNextVideoButtonPressed:(JDVideoModel *)videoModel
{
    [self videoPlayer:videoPlayer didPlayToEnd:videoModel];
}

- (void)handleErrorCode:(JDPlayerErrorCode)errorCode track:(JDVideoModel *)track customMessage:(NSString*)customMessage
{
    NSLog(@"errorCode : %ld,message : %@ , url : %@",(long)errorCode,customMessage,track.streamURL);
}

#pragma mark - Orientation
- (BOOL)shouldAutorotate
{
    return self.shouldRotate;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return self.shouldRotate;
}

- (JDPlayer *)player
{
    if(!_player)
    {
        _player = [[JDPlayer alloc] init];
        _player.delegate = self;
        [self.view addSubview:_player.jdView];
        _player.jdView.frame = self.view.bounds;
    }
    
    return _player;
}

@end
