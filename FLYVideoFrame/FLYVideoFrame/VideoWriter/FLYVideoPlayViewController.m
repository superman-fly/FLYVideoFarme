//
//  FLYVideoPlayViewController.m
//  FLYVideoFrame
//
//  Created by Fly on 2019/2/26.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "FLYVideoPlayViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define PHOTOCACHEPATH [NSTemporaryDirectory() stringByAppendingPathComponent:@"photoCache"]
#define VIDEOCACHEPATH [NSTemporaryDirectory() stringByAppendingPathComponent:@"videoCache"]

@interface FLYVideoPlayViewController ()
@property (nonatomic, strong) MPMoviePlayerController *videoPlayer;
@property (nonatomic, strong) NSString *from;

@property (nonatomic, strong) UIImage *videoCover;
@property (nonatomic, assign) NSTimeInterval enterTime;
@property (nonatomic, assign) BOOL hasRecordEvent;
@end

@implementation FLYVideoPlayViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.videoPlayer = [[MPMoviePlayerController alloc] init];
    [self.videoPlayer.view setFrame:self.view.bounds];
    self.videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.videoPlayer.view];
    [self.videoPlayer prepareToPlay];
    self.videoPlayer.controlStyle = MPMovieControlStyleNone;
    self.videoPlayer.shouldAutoplay = YES;
    self.videoPlayer.repeatMode = MPMovieRepeatModeOne;
    self.title = NSLocalizedString(@"PreView", nil);
    
    
    self.videoPlayer.contentURL = self.videoUrl;
    [self.videoPlayer play];
    
    [self buildNavUI];
    _enterTime = [[NSDate date] timeIntervalSince1970];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureFinished:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChanged) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.videoPlayer];
}

- (void)buildNavUI
{
    UIView *statusView = [[UIView alloc] init];
    statusView.backgroundColor = [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.5f];
    statusView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_STATUS_HEIGHT);
    [self.view addSubview:statusView];
    
    UIView *topView = [[UIView alloc] init];
    topView.backgroundColor = [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.5f];
    topView.frame = CGRectMake(0, SCREEN_STATUS_HEIGHT, SCREEN_WIDTH, 44);
    [self.view addSubview:topView];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn addTarget:self action:@selector(dismissAction) forControlEvents:UIControlEventTouchUpInside];
    [cancelBtn setImage:[UIImage imageNamed:@"icon-video-cancel"] forState:UIControlStateNormal];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [topView addSubview:cancelBtn];
    
    UIButton *Done = [UIButton buttonWithType:UIButtonTypeCustom];
    [Done addTarget:self action:@selector(DoneAction) forControlEvents:UIControlEventTouchUpInside];
    [Done setTitle:@"完成" forState:UIControlStateNormal];
    Done.frame = CGRectMake(SCREEN_WIDTH - 70, 0, 50, 44);
    [topView addSubview:Done];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 开启返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    [self.videoPlayer stop];
    self.videoPlayer = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)commit
{
    
}

#pragma mark - notification
#pragma state
- (void)stateChanged
{
    switch (self.videoPlayer.playbackState) {
        case MPMoviePlaybackStatePlaying:
            [self trackPreloadingTime];
            break;
        case MPMoviePlaybackStatePaused:
            break;
        case MPMoviePlaybackStateStopped:
            break;
        default:
            break;
    }
}

-(void)videoFinished:(NSNotification*)aNotification{
    int value = [[aNotification.userInfo valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (value == MPMovieFinishReasonPlaybackEnded) {   // 视频播放结束
    }
}

- (void)trackPreloadingTime
{
    
}

- (void)dismissAction
{
    [self.videoPlayer stop];
    self.videoPlayer = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)DoneAction
{
    [self.videoPlayer stop];
    self.videoPlayer = nil;
    if (self.doneActionBlock) {
        self.doneActionBlock();
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)captureImageAtTime:(float)time
{
    [self.videoPlayer requestThumbnailImagesAtTimes:@[@(time)] timeOption:MPMovieTimeOptionNearestKeyFrame];
}

- (void)captureFinished:(NSNotification *)notification
{
    self.videoCover = notification.userInfo[MPMoviePlayerThumbnailImageKey];
    if (self.videoCover == nil) {
        self.videoCover = [self coverIamgeAtTime:1];
    }
}


- (UIImage*)coverIamgeAtTime:(NSTimeInterval)time {
    
    
    [self.videoPlayer requestThumbnailImagesAtTimes:@[@(time)] timeOption:MPMovieTimeOptionNearestKeyFrame];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    UIImage*thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage: thumbnailImageRef] : [UIImage new];
    
    return thumbnailImage;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
