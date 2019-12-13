//
//  ReplayViewController.m
//  AgoraEducation
//
//  Created by SRS on 2019/12/10.
//  Copyright © 2019 yangmoumou. All rights reserved.
//

#import "ReplayViewController.h"
#import <AVKit/AVKit.h>
#import <Whiteboard/Whiteboard.h>
#import "OTOTeacherView.h"
#import "ReplayControlView.h"

@interface ReplayViewController ()<WhiteCombineDelegate, WhiteCommonCallbackDelegate, WhitePlayerEventDelegate, ReplayControlViewDelegate>

//@property (nonatomic, strong)AVPlayerViewController *playerVC;
@property (nonatomic, strong) WhiteSDK *sdk;
@property (nonatomic, strong) WhitePlayer *player;
@property (nonatomic, strong) WhiteCombinePlayer *combinePlayer;

@property (weak, nonatomic) IBOutlet UIView *whiteboardBaseView;

@property (weak, nonatomic) IBOutlet ReplayControlView *controlView;

@property (weak, nonatomic) IBOutlet UIView *playBackgroundView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet UIView *teacherView;
@property (weak, nonatomic) IBOutlet UIImageView *defaultTeacherImage;

@end

@implementation ReplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.controlView.delegate = self;
    WhiteVideoView *videoView = [[WhiteVideoView alloc] initWithFrame:self.teacherView.bounds];
    videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.teacherView addSubview:videoView];
    
    WhiteBoardView *boardView = [[WhiteBoardView alloc] init];
    boardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.whiteboardBaseView insertSubview:boardView belowSubview:self.playBackgroundView];
    
    NSLayoutConstraint *boardViewTopConstraint = [NSLayoutConstraint constraintWithItem:boardView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.whiteboardBaseView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *boardViewLeftConstraint = [NSLayoutConstraint constraintWithItem:boardView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.whiteboardBaseView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    NSLayoutConstraint *boardViewRightConstraint = [NSLayoutConstraint constraintWithItem:boardView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.whiteboardBaseView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    NSLayoutConstraint *boardViewBottomConstraint = [NSLayoutConstraint constraintWithItem:boardView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.whiteboardBaseView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    [self.whiteboardBaseView addConstraints:@[boardViewTopConstraint, boardViewLeftConstraint, boardViewRightConstraint, boardViewBottomConstraint]];

    //配置 SDK 设置
    WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
    //通过实例化，并已经添加在视图栈中 Whiteboard，初始化 WhiteSDK。
    self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:boardView config:config commonCallbackDelegate:self];
    
    //初始化回放配置类
    WhitePlayerConfig *playerConfig = [[WhitePlayerConfig alloc] initWithRoom:@"" roomToken:@""];
    //创建 whitePlayer 实例，进行回放

    WEAK(self)
    [self.sdk createReplayerWithConfig:playerConfig callbacks:self completionHandler:^(BOOL success, WhitePlayer * _Nonnull player, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"创建回放房间失败 error:%@", [error localizedDescription]);
        } else {
            weakself.player = player;
            //TODO: 音视频的url
            self.combinePlayer = [[WhiteCombinePlayer alloc] initWithMediaUrl:[NSURL URLWithString:@""] whitePlayer:player];
            //TODO: 把视频 Player 显示在这里
            [videoView setAVPlayer:self.combinePlayer.nativePlayer];
            self.combinePlayer.delegate = self;
            [self.combinePlayer play];
            NSLog(@"创建回放房间成功，开始回放");
        }
    }];
}

- (IBAction)onPlayClick:(id)sender {
    
    self.playBackgroundView.hidden = YES;
    self.playButton.hidden = YES;
    self.controlView.playOrPauseBtn.selected = YES;
    self.defaultTeacherImage.hidden = YES;
    [self.player play];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    [self performSelector:@selector(hideControlView) withObject:nil afterDelay:3];
}

#pragma mark WhiteCommonCallbackDelegate
/** 当sdk出现未捕获的全局错误时，会在此处对抛出 NSError 对象 */
- (void)throwError:(NSError *)error {
    NSLog(@"创建白板信息==》%@", [error localizedDescription]);
}

#pragma mark WhiteCombineDelegate
- (void)combinePlayerStartBuffering
{
    NSLog(@"combinePlayerStartBuffering");
}

- (void)combinePlayerEndBuffering
{
    NSLog(@"combinePlayerEndBuffering");
}

#pragma mark WhitePlayerEventDelegate
/** 播放状态切换回调 */
- (void)phaseChanged:(WhitePlayerPhase)phase {
    if(phase == WhitePlayerPhaseEnded) {
        [self.player seekToScheduleTime:0];
        [self.player pause];
        
        self.playBackgroundView.hidden = NO;
        self.playButton.hidden = NO;
        self.controlView.playOrPauseBtn.selected = NO;
        self.defaultTeacherImage.hidden = NO;
        
        self.controlView.sliderView.value = 0;
        NSString *totleTimeStr = [self convertTimeSecond: self.player.timeInfo.timeDuration];
        NSString *currentTimeStr = [self convertTimeSecond: 0];
        NSString *timeStr = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totleTimeStr];
        self.controlView.timeLabel.text = timeStr;
    }
}
/** 首帧加载回调 */
- (void)loadFirstFrame {
    
}
///** 播放中，状态出现变化的回调 */
//- (void)playerStateChanged:(WhitePlayerState *)modifyState {
//
//}
/** 出错暂停 */
- (void)stoppedWithError:(NSError *)error {
    
}
/** 进度时间变化 */
- (void)scheduleTimeChanged:(NSTimeInterval)time {
    
    if(self.controlView.sliderView.isdragging){
        return;
    }
    
    if(self.player.timeInfo.timeDuration > 0){
        float value = time / self.player.timeInfo.timeDuration;
        self.controlView.sliderView.value = value;
        NSString *totleTimeStr = [self convertTimeSecond: self.player.timeInfo.timeDuration];
        NSString *currentTimeStr = [self convertTimeSecond: time];
        NSString *timeStr = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totleTimeStr];
        self.controlView.timeLabel.text = timeStr;
    }
}
/** 添加帧出错 */
- (void)errorWhenAppendFrame:(NSError *)error {
    
}
/** 渲染时，出错 */
- (void)errorWhenRender:(NSError *)error {
    
}

#pragma mark ReplayControlViewDelegate
// 滑块滑动开始
- (void)sliderTouchBegan:(float)value {
    self.controlView.sliderView.isdragging = YES;
}
// 滑块滑动中
- (void)sliderValueChanged:(float)value {
    if (self.player.timeInfo.timeDuration > 0) {
        [self.player seekToScheduleTime:self.player.timeInfo.timeDuration * value];
    }
}
// 滑块滑动结束
- (void)sliderTouchEnded:(float)value {
    
    if (self.player.timeInfo.timeDuration == 0) {
        self.controlView.sliderView.value = 0;
        return;
    }
    self.controlView.sliderView.value = value;
    float currentTime = self.player.timeInfo.timeDuration * value;
    [self.player seekToScheduleTime:currentTime];
    NSString *currentTimeStr = [self convertTimeSecond: currentTime];
    NSString *totleTimeStr = [self convertTimeSecond: self.player.timeInfo.timeDuration];
    NSString *timeStr = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totleTimeStr];
    self.controlView.timeLabel.text = timeStr;
    
    self.controlView.sliderView.isdragging = NO;
}

- (NSString *)convertTimeSecond:(NSInteger)timeSecond {
    NSString *theLastTime = nil;
    long second = timeSecond;
    if (timeSecond < 60) {
        theLastTime = [NSString stringWithFormat:@"00:%02zd", second];
    } else if(timeSecond >= 60 && timeSecond < 3600){
        theLastTime = [NSString stringWithFormat:@"%02zd:%02zd", second/60, second%60];
    } else if(timeSecond >= 3600){
        theLastTime = [NSString stringWithFormat:@"%02zd:%02zd:%02zd", second/3600, second%3600/60, second%60];
    }
    return theLastTime;
}

// 滑杆点击
- (void)sliderTapped:(float)value {
    self.controlView.sliderView.isdragging = YES;
    
    if(self.player.timeInfo.timeDuration > 0) {
        float currentTime = self.player.timeInfo.timeDuration * value;
        [self.player seekToScheduleTime:currentTime];
        NSString *currentTimeStr = [self convertTimeSecond: currentTime];
        NSString *totleTimeStr = [self convertTimeSecond: self.player.timeInfo.timeDuration];
        NSString *timeStr = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totleTimeStr];
        self.controlView.timeLabel.text = timeStr;
    } else {
        self.controlView.sliderView.value = 0;
    }
    
    self.controlView.sliderView.isdragging = NO;
}
// 播放暂停按钮点击
- (void)playPauseButtonClicked:(BOOL)play {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    
    if(play) {
        self.playBackgroundView.hidden = YES;
        self.playButton.hidden = YES;
        [self.player play];
        self.defaultTeacherImage.hidden = YES;
        [self performSelector:@selector(hideControlView) withObject:nil afterDelay:3];
        
    } else {
        self.playBackgroundView.hidden = NO;
        self.playButton.hidden = NO;
        [self.player pause];
    }
}

-(void)hideControlView {
    self.controlView.hidden = YES;
}
- (IBAction)onWhiteBoardClick:(id)sender {
    self.controlView.hidden = NO;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    [self performSelector:@selector(hideControlView) withObject:nil afterDelay:3];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
@end