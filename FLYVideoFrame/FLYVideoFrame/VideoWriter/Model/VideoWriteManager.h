//
//  VideoWriteManager.h
//  FLYVideoFrame
//
//  Created by Fly on 2019/1/13.
//  Copyright © 2019 Fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

#define RECORD_MAX_TIME 60.0            //最长录制时间
#define TIMER_INTERVAL 0.05             //计时器刷新频率
#define VIDEO_FOLDER @"videoFolder"     //视频录制存放文件夹

//录制状态，（这里把视频录制与写入合并成一个状态）
typedef NS_ENUM(NSInteger, AVRecordState) {
    AVRecordStateInit = 0,
    AVRecordStatePrepareRecording,
    AVRecordStateRecording,
    AVRecordStateFinish,
    AVRecordStateFail,
};

//录制视频的长宽比
typedef NS_ENUM(NSInteger, AVViewType) {
    Type1X1 = 0,
    Type4X3,
    TypeFullScreen,
    Type3X4
};

@protocol VideoWriteManagerDelegate <NSObject>

- (void)finishWriting;
- (void)updateWritingProgress:(CGFloat)progress;
- (void)updateWritingSampleBufferRef:(CMSampleBufferRef)sampleBuffer;

@end

@interface VideoWriteManager : NSObject

@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;

@property (nonatomic, assign) AVRecordState writeState;
@property (nonatomic, weak) id <VideoWriteManagerDelegate> delegate;
- (instancetype)initWithURL:(NSURL *)URL viewType:(AVViewType)type;

- (void)startWrite;
- (void)stopWrite;
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;
- (void)destroyWrite;

@end

NS_ASSUME_NONNULL_END
