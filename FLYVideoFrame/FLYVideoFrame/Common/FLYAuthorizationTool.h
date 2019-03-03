//
//  FLYAuthorizationTool.h
//  FLYVideoFrame
//
//  Created by Fly on 2019/2/25.
//  Copyright © 2019 Fly. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FLYAuthorizationStatus) {
    FLYAuthorizationStatusAuthorized = 0,    // 已授权
    FLYAuthorizationStatusDenied,            // 拒绝
    FLYAuthorizationStatusRestricted,        // 应用没有相关权限，且当前用户无法改变这个权限，比如:家长控制
    FLYAuthorizationStatusNotSupport         // 硬件等不支持
};

@interface FLYAuthorizationTool : NSObject
/**
 *  请求相册访问权限
 *
 *  @param callback
 */
+ (void)requestImagePickerAuthorization:(void (^)(FLYAuthorizationStatus,NSString*))callback;

/**
 *  请求相机权限
 *
 *  @param callback
 */
+ (void)requestCameraAuthorization:(void (^)(FLYAuthorizationStatus,NSString*))callback;

/**
 *  请求麦克风权限
 *
 *  @param callback
 */
+ (void)requestAudioAuthorization:(void (^)(FLYAuthorizationStatus,NSString*))callback;

/**
 *  通讯录
 *
 *  @param callback
 */
+ (void)requestAddressBookAuthorization:(void (^)(FLYAuthorizationStatus,NSString*))callback;
@end
NS_ASSUME_NONNULL_END
