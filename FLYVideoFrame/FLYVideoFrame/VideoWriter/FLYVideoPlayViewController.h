//
//  FLYVideoPlayViewController.h
//  FLYVideoFrame
//
//  Created by Fly on 2019/2/26.
//  Copyright © 2019 Fly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLYVideoPlayViewController : UIViewController
@property (nonatomic, copy) void (^doneActionBlock)(void);
@property (nonatomic, strong) NSURL *videoUrl;
@end

NS_ASSUME_NONNULL_END
