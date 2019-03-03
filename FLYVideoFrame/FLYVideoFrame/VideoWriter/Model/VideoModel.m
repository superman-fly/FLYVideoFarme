//
//  VideoModel.m
//  FLYVideoFrame
//
//  Created by Fly on 2019/1/13.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "VideoModel.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "FileManager.h"
#import "VideoWriteManager.h"

@interface VideoModel ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, VideoWriteManagerDelegate>

@property (nonatomic, weak) UIView *superView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewlayer;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

@property (nonatomic, strong, readwrite) NSURL *videoUrl;

@property (nonatomic, strong) VideoWriteManager *writeManager;
@property (nonatomic, assign) AVFlashState flashState;
@property (nonatomic, assign) AVViewType viewType;

@end

@implementation VideoModel

- (instancetype)initWithFMVideoViewType:(AVViewType)type superView:(UIView *)superView
{
    self = [super init];
    if (self) {
        _superView = superView;
        _viewType = type;
        [self setUpWithType:type];
    }
    return self;
}

#pragma mark - lazy load
- (AVCaptureSession *)session
{
    // 录制5秒钟视频 高画质10M,压缩成中画质 0.5M
    // 录制5秒钟视频 中画质0.5M,压缩成中画质 0.5M
    // 录制5秒钟视频 低画质0.1M,压缩成中画质 0.1M
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {//设置分辨率
            _session.sessionPreset=AVCaptureSessionPresetMedium;
        }
    }
    return _session;
}

- (dispatch_queue_t)videoQueue
{
    if (!_videoQueue) {
        _videoQueue = dispatch_queue_create("com.5miles", DISPATCH_QUEUE_SERIAL);
    }
    return _videoQueue;
}
- (AVCaptureVideoPreviewLayer *)previewlayer
{
    if (!_previewlayer) {
        _previewlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewlayer;
}

- (void)setRecordState:(AVRecordState)recordState
{
    if (_recordState != recordState) {
        _recordState = recordState;
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordState:)]) {
            [self.delegate updateRecordState:_recordState];
        }
    }
}


#pragma mark - setup
- (void)setUpWithType:(AVViewType )type
{
    ///1. 初始化捕捉会话，数据的采集都在会话中处理
    [self setUpInit];
    ///2. 设置视频的输入输出
    [self setUpVideo];
    
    ///3. 设置音频的输入输出
    [self setUpAudio];
    
    ///4. 视频的预览层
    [self setUpPreviewLayerWithType:type];
    
    ///5. 开始采集画面
    [self.session startRunning];
    
    /// 6. 初始化writer， 用writer 把数据写入文件
    [self setUpWriter];
    
}

- (void)setUpVideo {
    // 2.1 获取视频输入设备(摄像头)
    AVCaptureDevice *videoCaptureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];//取得前置摄像头
    // 2.2 创建视频输入源
    NSError *error=nil;
    self.videoInput= [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
    // 2.3 将视频输入源添加到会话
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    
}

- (void)setUpAudio {
    // 2.2 获取音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    NSError *error=nil;
    // 2.4 创建音频输入源
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    // 2.6 将音频输入源添加到会话
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    
}

- (void)setUpPreviewLayerWithType:(AVViewType )type {
    CGRect rect = CGRectZero;
    switch (type) {
        case Type1X1:
            rect = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
            break;
        case Type4X3:
            rect = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH*4/3);
            break;
        case TypeFullScreen:
            rect = [UIScreen mainScreen].bounds;
            break;
        case Type3X4:
            rect = CGRectMake(0, SCREEN_STATUS_HEIGHT+44, SCREEN_WIDTH, SCREEN_WIDTH/3*4);
            break;
        default:
            rect = [UIScreen mainScreen].bounds;
            break;
    }
    
    self.previewlayer.frame = rect;
    [_superView.layer insertSublayer:self.previewlayer atIndex:0];
}

- (void)setUpWriter {
    self.videoUrl = [[NSURL alloc] initFileURLWithPath:[self createVideoFilePath]];
    self.writeManager = [[VideoWriteManager alloc] initWithURL:self.videoUrl viewType:_viewType];
    self.writeManager.delegate = self;
    
}


#pragma mark - public method
//切换摄像头
- (void)turnCameraAction {
    [self.session stopRunning];
    // 1. 获取当前摄像头
    AVCaptureDevicePosition position = self.videoInput.device.position;
    
    //2. 获取当前需要展示的摄像头
    if (position == AVCaptureDevicePositionBack) {
        position = AVCaptureDevicePositionFront;
    } else {
        position = AVCaptureDevicePositionBack;
    }
    
    // 3. 根据当前摄像头创建新的device
    AVCaptureDevice *device = [self getCameraDeviceWithPosition:position];
    
    // 4. 根据新的device创建input
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //5. 在session中切换input
    [self.session beginConfiguration];
    [self.session removeInput:self.videoInput];
    [self.session addInput:newInput];
    [self.session commitConfiguration];
    self.videoInput = newInput;
    
    [self.session startRunning];
}

- (void)switchflash {
    if(_flashState == AVFlashClose){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOn];
            [self.videoInput.device unlockForConfiguration];
            _flashState = AVFlashOpen;
        }
    }else if(_flashState == AVFlashOpen){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeAuto];
            [self.videoInput.device unlockForConfiguration];
            _flashState = AVFlashAuto;
        }
    }else if(_flashState == AVFlashAuto){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOff];
            [self.videoInput.device unlockForConfiguration];
            _flashState = AVFlashClose;
        }
    };
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateFlashState:)]) {
        [self.delegate updateFlashState:_flashState];
    }
    
}

- (void)startRecord {
    if (self.recordState == AVRecordStateInit) {
        [self.writeManager startWrite];
        self.recordState = AVRecordStateRecording;
    }
}

- (void)stopRecord {
    
    [self.writeManager stopWrite];
    [self.session stopRunning];
    self.recordState = AVRecordStateFinish;
    
}

- (void)reset {
    self.recordState = AVRecordStateInit;
    [self.session startRunning];
    [self setUpWriter];
    
}


#pragma mark - private method
//初始化设置
- (void)setUpInit {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBack) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self clearFile];
    _recordState = AVRecordStateInit;
}

//存放视频的文件夹
- (NSString *)videoFolder {
    NSString *cacheDir = [FileManager cachesDir];
    NSString *direc = [cacheDir stringByAppendingPathComponent:VIDEO_FOLDER];
    if (![FileManager isExistsAtPath:direc]) {
        [FileManager createDirectoryAtPath:direc];
    }
    return direc;
}

//清空文件夹
- (void)clearFile {
    [FileManager removeItemAtPath:[self videoFolder]];
}

//写入的视频路径
- (NSString *)createVideoFilePath {
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *path = [[self videoFolder] stringByAppendingPathComponent:videoName];
    return path;
    
}


#pragma mark - 获取摄像头

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position {
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        
        //视频
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
            if (!self.writeManager.outputVideoFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.writeManager.outputVideoFormatDescription = formatDescription;
                }
            } else {
                @synchronized(self) {
                    if (self.writeManager.writeState == AVRecordStateRecording) {
                        [self.writeManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                    }
                    
                }
            }
            
            
        }
        
        //音频
        if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]) {
            if (!self.writeManager.outputAudioFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.writeManager.outputAudioFormatDescription = formatDescription;
                }
            }
            @synchronized(self) {
                
                if (self.writeManager.writeState == AVRecordStateRecording) {
                    [self.writeManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
                }
                
            }
            
        }
    }
    
}


#pragma mark - VideoWriteManagerDelegate

- (void)updateWritingProgress:(CGFloat)progress {
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordingProgress:)]) {
        [self.delegate updateRecordingProgress:progress];
    }
}

- (void)finishWriting {
    [self.session stopRunning];
    self.recordState = AVRecordStateFinish;
}

- (void)updateWritingSampleBufferRef:(CMSampleBufferRef)sampleBuffer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordingSampleBufferRef:)]) {
        [self.delegate updateRecordingSampleBufferRef:sampleBuffer];
    }
}


#pragma mark - notification

- (void)enterBack {
    self.videoUrl = nil;
    [self.session stopRunning];
    [self.writeManager destroyWrite];
    
}

- (void)becomeActive {
    [self reset];
}

- (void)destroy {
    [self.session stopRunning];
    self.session = nil;
    self.videoQueue = nil;
    self.videoOutput = nil;
    self.videoInput = nil;
    self.audioOutput = nil;
    self.audioInput = nil;
    [self.writeManager destroyWrite];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self destroy];
    
}

@end
