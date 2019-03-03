# FLYVideoFarme
视频录制中取图进行人脸识别

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
 人脸识别 接入第三方图像匹配接口
 
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
    // 接入第三方图像匹配接口
}
