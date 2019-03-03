//
//  VideoView.m
//  FLYVideoFrame
//
//  Created by Fly on 2019/1/13.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "VideoView.h"
#import "RecordProgressView.h"

@interface VideoView ()<VideoModelDelegate>

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIView *timeView;
@property (nonatomic, strong) UILabel *timelabel;
@property (nonatomic, strong) UIButton *turnCamera;
@property (nonatomic, strong) UIButton *flashBtn;
@property (nonatomic, strong) RecordProgressView *progressView;
@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic, assign) CGFloat recordTime;

@property (nonatomic, strong, readwrite) VideoModel *fmodel;

@end

@implementation VideoView

-(instancetype)initWithFMVideoViewType:(AVViewType)type
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        [self BuildUIWithType:type];
    }
    return self;
}

#pragma mark - view
- (void)BuildUIWithType:(AVViewType)type
{
    self.fmodel = [[VideoModel alloc] initWithFMVideoViewType:type superView:self];
    self.fmodel.delegate = self;
    
    UIView *statusView = [[UIView alloc] init];
    statusView.backgroundColor = [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.5f];
    statusView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_STATUS_HEIGHT);
    [self addSubview:statusView];
    
    self.topView = [[UIView alloc] init];
    self.topView.backgroundColor = [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.5f];
    self.topView.frame = CGRectMake(0, SCREEN_STATUS_HEIGHT, SCREEN_WIDTH, 44);
    [self addSubview:self.topView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, SCREEN_STATUS_HEIGHT+44, SCREEN_WIDTH, SCREEN_WIDTH/3*4)];
    imageView.image = [UIImage imageNamed:@"icon-video-face"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:imageView];
    
    self.timeView = [[UIView alloc] init];
    self.timeView.hidden = YES;
    self.timeView.frame = CGRectMake((SCREEN_WIDTH - 100)/2, 5+SCREEN_STATUS_HEIGHT, 100, 34);
    self.timeView.backgroundColor = [UIColor grayColor];//[UIColor colorWithRGB:0x333333 alpha:1];
    self.timeView.layer.cornerRadius = 4;
    self.timeView.layer.masksToBounds = YES;
    [self addSubview:self.timeView];
    
    
    UIView *redPoint = [[UIView alloc] init];
    redPoint.frame = CGRectMake(0, 0, 6, 6);
    redPoint.layer.cornerRadius = 3;
    redPoint.layer.masksToBounds = YES;
    redPoint.center = CGPointMake(25, 17);
    redPoint.backgroundColor = [UIColor redColor];
    [self.timeView addSubview:redPoint];
    
    self.timelabel =[[UILabel alloc] init];
    self.timelabel.font = [UIFont systemFontOfSize:15];
    self.timelabel.textColor = [UIColor whiteColor];
    self.timelabel.frame = CGRectMake(40, 8, 40, 28);
    [self.timeView addSubview:self.timelabel];
    
    
    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.frame = CGRectMake(15, 14, 16, 16);
    [self.cancelBtn setImage:[UIImage imageNamed:@"icon-video-cancel"] forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.cancelBtn];
    
    
    self.turnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    self.turnCamera.frame = CGRectMake(SCREEN_WIDTH - 60 - 28, 11, 28, 22);
    [self.turnCamera setImage:[UIImage imageNamed:@"icon-listing_camera_lens"] forState:UIControlStateNormal];
    [self.turnCamera addTarget:self action:@selector(turnCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self.turnCamera sizeToFit];
    [self.topView addSubview:self.turnCamera];


    self.flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flashBtn.frame = CGRectMake(SCREEN_WIDTH - 22 - 15, 11, 22, 22);
    [self.flashBtn setImage:[UIImage imageNamed:@"icon-listing_flash_off"] forState:UIControlStateNormal];
    [self.flashBtn addTarget:self action:@selector(flashAction) forControlEvents:UIControlEventTouchUpInside];
    [self.flashBtn sizeToFit];
    [self.topView addSubview:self.flashBtn];
    
    
    self.progressView = [[RecordProgressView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 62)/2, self.bounds.size.height - 32 - 62, 62, 62)];
    self.progressView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.progressView];
    self.recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.recordBtn addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchUpInside];
    self.recordBtn.frame = CGRectMake(5, 5, 52, 52);
    self.recordBtn.backgroundColor = [UIColor redColor];
    self.recordBtn.layer.cornerRadius = 26;
    self.recordBtn.layer.masksToBounds = YES;
    [self.progressView addSubview:self.recordBtn];
    [self.progressView resetProgress];
}

- (void)updateViewWithRecording {
    self.timeView.hidden = NO;
    self.topView.hidden = YES;
    [self changeToRecordStyle];
}

- (void)updateViewWithStop {
    self.timeView.hidden = YES;
    self.topView.hidden = NO;
    [self changeToStopStyle];
}

- (void)changeToRecordStyle {
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint center = self.recordBtn.center;
        CGRect rect = self.recordBtn.frame;
        rect.size = CGSizeMake(28, 28);
        self.recordBtn.frame = rect;
        self.recordBtn.layer.cornerRadius = 4;
        self.recordBtn.center = center;
    }];
}

- (void)changeToStopStyle {
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint center = self.recordBtn.center;
        CGRect rect = self.recordBtn.frame;
        rect.size = CGSizeMake(52, 52);
        self.recordBtn.frame = rect;
        self.recordBtn.layer.cornerRadius = 26;
        self.recordBtn.center = center;
    }];
}


#pragma mark - action

- (void)dismissVC {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissVC)]) {
        [self.delegate dismissVC];
    }
}

- (void)turnCameraAction {
    [self.fmodel turnCameraAction];
}

- (void)flashAction {
    [self.fmodel switchflash];
}

- (void)startRecord {
    if (self.fmodel.recordState == AVRecordStateInit) {
        [self.fmodel startRecord];
        if (self.delegate && [self.delegate respondsToSelector:@selector(startRecord)]) {
            [self.delegate startRecord];
        }
    } else if (self.fmodel.recordState == AVRecordStateRecording) {
        [self.fmodel stopRecord];
        if (self.delegate && [self.delegate respondsToSelector:@selector(stopRecord)]) {
            [self.delegate stopRecord];
        }
    } else {
        [self.fmodel reset];
    }
}

- (void)stopRecord {
    [self.fmodel stopRecord];
}

- (void)reset {
    [self.fmodel reset];
}

#pragma mark - FMFModelDelegate

- (void)updateFlashState:(AVFlashState)state {
    if (state == AVFlashOpen) {
        [self.flashBtn setImage:[UIImage imageNamed:@"icon-listing_flash_on"] forState:UIControlStateNormal];
    }
    if (state == AVFlashClose) {
        [self.flashBtn setImage:[UIImage imageNamed:@"icon-listing_flash_off"] forState:UIControlStateNormal];
    }
    if (state == AVFlashAuto) {
        [self.flashBtn setImage:[UIImage imageNamed:@"icon-listing_flash_auto"] forState:UIControlStateNormal];
    }
}

- (void)updateRecordState:(AVRecordState)recordState {
    if (recordState == AVRecordStateInit) {
        [self updateViewWithStop];
        [self.progressView resetProgress];
    } else if (recordState == AVRecordStateRecording) {
        [self updateViewWithRecording];
    } else  if (recordState == AVRecordStateFinish) {
        [self updateViewWithStop];
        [self.progressView resetProgress];
        if (self.delegate && [self.delegate respondsToSelector:@selector(recordFinishWithvideoUrl:)]) {
            [self.delegate recordFinishWithvideoUrl:self.fmodel.videoUrl];
        }
    }
}

- (void)updateRecordingProgress:(CGFloat)progress {
    [self.progressView updateProgressWithValue:progress];
    self.timelabel.text = [self changeToVideotime:progress * RECORD_MAX_TIME];
    [self.timelabel sizeToFit];
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordingTime:)]) {
        [self.delegate updateRecordingTime:progress * RECORD_MAX_TIME];
    }
}

- (NSString *)changeToVideotime:(CGFloat)videocurrent {
    
    return [NSString stringWithFormat:@"%02li:%02li",lround(floor(videocurrent/60.f)),lround(floor(videocurrent/1.f))%60];
    
}

- (void)updateRecordingSampleBufferRef:(CMSampleBufferRef)sampleBuffer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordingUpdateSampleBufferRef:)]) {
        [self.delegate recordingUpdateSampleBufferRef:sampleBuffer];
    }
}

@end
