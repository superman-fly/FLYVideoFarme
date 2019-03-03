//
//  VideoModel.h
//  FLYVideoFrame
//
//  Created by Fly on 2019/1/13.
//  Copyright © 2019 Fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VideoWriteManager.h"

NS_ASSUME_NONNULL_BEGIN

//闪光灯状态
typedef NS_ENUM(NSInteger, AVFlashState) {
    AVFlashClose = 0,
    AVFlashOpen,
    AVFlashAuto,
};

@protocol VideoModelDelegate <NSObject>

- (void)updateFlashState:(AVFlashState)state;
- (void)updateRecordingProgress:(CGFloat)progress;
- (void)updateRecordState:(AVRecordState)recordState;
- (void)updateRecordingSampleBufferRef:(CMSampleBufferRef)sampleBuffer;

@end

@interface VideoModel : NSObject

@property (nonatomic, weak) id <VideoModelDelegate> delegate;
@property (nonatomic, assign) AVRecordState recordState;
@property (nonatomic, strong, readonly) NSURL *videoUrl;

- (instancetype)initWithFMVideoViewType:(AVViewType)type superView:(UIView *)superView;
- (void)turnCameraAction;
- (void)switchflash;
- (void)startRecord;
- (void)stopRecord;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
