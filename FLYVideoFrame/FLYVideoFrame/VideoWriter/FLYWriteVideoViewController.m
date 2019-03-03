//
//  FLYWriteVideoViewController.m
//  FLYVideoFrame
//
//  Created by Fly on 2019/2/25.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "FLYWriteVideoViewController.h"
#import "VideoView.h"
#import "FLYVideoPlayViewController.h"

#define RECORD_MIN_TIME 30           //最短录制时间
#define RECORD_MAX_REQUEST 10           //请求人脸识别最大次数

@interface FLYWriteVideoViewController()<VideoViewDelegate> {
    BOOL isGetImage;    //是否取帧
    NSInteger discernCount; //记录请求次数
    NSTimer  *discernTimer; //请求时间间隔
}
@property (nonatomic, strong) VideoView *videoView;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLabel;
@property (nonatomic, assign) BOOL isAuth;  //人脸识别是否成功
@property (nonatomic, assign) CGFloat timeCount;
@end

@implementation FLYWriteVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"录制";
    self.navigationController.navigationBarHidden = YES;
    _videoView  =[[VideoView alloc] initWithFMVideoViewType:Type3X4];
    _videoView.delegate = self;
    [self.view addSubview:_videoView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 保持常亮，不自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    // 禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    // 开启返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_videoView.fmodel.recordState == AVRecordStateFinish) {
        [self resetVideo];
    }
}

- (void)resetVideo {
    [_videoView.fmodel reset];
    self.isAuth = NO;
    discernCount = 0;
    self.timeCount = 0;
}

- (void)dismissVC
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)stopRecord {
    isGetImage = NO;
    [self deleteTimer];
}

- (void)startRecord {
    if (self.isNeedFace) {
        [self openTimer];
    }
}

-(void)recordFinishWithvideoUrl:(NSURL *)videoUrl
{
    FLYVideoPlayViewController *playVC = [[FLYVideoPlayViewController alloc] init];
    playVC.videoUrl = videoUrl;
    playVC.doneActionBlock = ^{
        [self dismissVC];
    };
    [self.navigationController pushViewController:playVC animated:YES];
}

- (void)updateRecordingTime:(CGFloat)time {
    self.timeCount = time;
}

- (void)recordingUpdateSampleBufferRef:(CMSampleBufferRef)sampleBuffer {
    if (!isGetImage) {
        return;
    }
    isGetImage = NO;
    [self setAccsaddas:sampleBuffer];
}

- (void)openTimer {
    discernTimer =  [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(discernImage) userInfo:nil repeats:NO];
}

- (void)discernImage {
    isGetImage = YES;
}

- (void)deleteTimer {
    [discernTimer invalidate];
    discernTimer = nil;
}

/**
 取帧
 
 @param sampleBuffer 缓冲
 */
- (void)setAccsaddas:(CMSampleBufferRef)sampleBuffer{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    
    CIImage *convertedImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    UIImage* image = [UIImage imageWithCIImage:convertedImage];
    dispatch_async(dispatch_get_main_queue()
                   , ^{
                       UIGraphicsBeginImageContext(image.size);
                       [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
                       UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                       UIGraphicsEndImageContext();
                       UIImage *newImages = [self imageRotation:newImage rotation:UIImageOrientationRight];
                       [self requestProtData:newImages];
                       [self deleteTimer];
                   });
}

/**
 人脸识别
 
 @param image 截图
 */
- (void)requestProtData:(UIImage*)image {
    if (!image) {
        return;
    }
    discernCount++;
    if (discernCount > RECORD_MAX_REQUEST) {
        return;
    }
    NSData *imageData = UIImageJPEGRepresentation(image,0.7);
}

//旋转图片
- (UIImage *)imageRotation:(UIImage *)image rotation:(UIImageOrientation)orientation
{
    long double rotate = 90.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}
@end


