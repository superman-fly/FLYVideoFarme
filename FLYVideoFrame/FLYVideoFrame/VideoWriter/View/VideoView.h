//
//  VideoView.h
//  FLYVideoFrame
//
//  Created by Fly on 2019/1/13.
//  Copyright © 2019 Fly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VideoViewDelegate <NSObject>

- (void)dismissVC;
- (void)recordFinishWithvideoUrl:(NSURL *)videoUrl;
- (void)recordingUpdateSampleBufferRef:(CMSampleBufferRef)sampleBuffer;
- (void)updateRecordingTime:(CGFloat)time;
- (void)startRecord;
- (void)stopRecord;

@end

@interface VideoView : UIView

@property (nonatomic, assign) AVViewType viewType;
@property (nonatomic, strong, readonly) VideoModel *fmodel;
@property (nonatomic, weak) id <VideoViewDelegate> delegate;

-(instancetype)initWithFMVideoViewType:(AVViewType)type;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
