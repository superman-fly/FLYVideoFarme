//
//  FLYAuthorizationTool.m
//  FLYVideoFrame
//
//  Created by Fly on 2019/2/25.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "FLYAuthorizationTool.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@implementation FLYAuthorizationTool

#pragma mark - 相册
+ (void)requestImagePickerAuthorization:(void(^)(FLYAuthorizationStatus,NSString*))callback {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ||
        [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
        if (authStatus == ALAuthorizationStatusNotDetermined) { // 未授权
            if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
                [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
            } else {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (status == PHAuthorizationStatusAuthorized) {
                        [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
                    } else if (status == PHAuthorizationStatusDenied) {
                        [self executeCallback:callback status:FLYAuthorizationStatusDenied message:@"拒绝"];
                    } else if (status == PHAuthorizationStatusRestricted) {
                        [self executeCallback:callback status:FLYAuthorizationStatusRestricted message:@"应用没有相关权限，且当前用户无法改变这个权限"];
                    }
                }];
            }
            
        } else if (authStatus == ALAuthorizationStatusAuthorized) {
            [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
        } else if (authStatus == ALAuthorizationStatusDenied) {
            [self executeCallback:callback status:FLYAuthorizationStatusDenied message:@"拒绝"];
        } else if (authStatus == ALAuthorizationStatusRestricted) {
            [self executeCallback:callback status:FLYAuthorizationStatusRestricted message:@"应用没有相关权限，且当前用户无法改变这个权限"];
        }
    } else {
        [self executeCallback:callback status:FLYAuthorizationStatusNotSupport message:@""];
    }
}

#pragma mark - 相机
+ (void)requestCameraAuthorization:(void (^)(FLYAuthorizationStatus,NSString*))callback {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
                } else {
                    [self executeCallback:callback status:FLYAuthorizationStatusDenied message:@"拒绝"];
                }
            }];
        } else if (authStatus == AVAuthorizationStatusAuthorized) {
            [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
        } else if (authStatus == AVAuthorizationStatusDenied) {
            [self executeCallback:callback status:FLYAuthorizationStatusDenied message:@"拒绝"];
        } else if (authStatus == AVAuthorizationStatusRestricted) {
            [self executeCallback:callback status:FLYAuthorizationStatusRestricted message:@"应用没有相关权限，且当前用户无法改变这个权限"];
        }
    } else {
        [self executeCallback:callback status:FLYAuthorizationStatusNotSupport message:@""];
    }
}

#pragma mark - 麦克风
+ (void)requestAudioAuthorization:(void (^)(FLYAuthorizationStatus,NSString*))callback {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
            } else {
                [self executeCallback:callback status:FLYAuthorizationStatusNotSupport message:@"拒绝"];
            }
        }];
    } else if (authStatus == AVAuthorizationStatusAuthorized) {
        [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
    } else if (authStatus == AVAuthorizationStatusDenied) {
        [self executeCallback:callback status:FLYAuthorizationStatusDenied message:@"拒绝"];
    } else if (authStatus == AVAuthorizationStatusRestricted) {
        [self executeCallback:callback status:FLYAuthorizationStatusRestricted message:@"应用没有相关权限，且当前用户无法改变这个权限"];
    }
}

#pragma mark - 通讯录
+ (void)requestAddressBookAuthorization:(void (^)(FLYAuthorizationStatus,NSString*))callback {
    ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
    if (authStatus == kABAuthorizationStatusNotDetermined) {
        __block ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (addressBook == NULL) {
            [self executeCallback:callback status:FLYAuthorizationStatusNotSupport message:@""];
            return;
        }
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
            } else {
                [self executeCallback:callback status:FLYAuthorizationStatusDenied message:@"拒绝"];
            }
            if (addressBook) {
                CFRelease(addressBook);
                addressBook = NULL;
            }
        });
        return;
    } else if (authStatus == kABAuthorizationStatusAuthorized) {
        [self executeCallback:callback status:FLYAuthorizationStatusAuthorized message:@"已授权"];
    } else if (authStatus == kABAuthorizationStatusDenied) {
        [self executeCallback:callback status:FLYAuthorizationStatusDenied message:@"拒绝"];
    } else if (authStatus == kABAuthorizationStatusRestricted) {
        [self executeCallback:callback status:FLYAuthorizationStatusRestricted message:@"应用没有相关权限，且当前用户无法改变这个权限"];
    }
}

#pragma mark - callback
+ (void)executeCallback:(void (^)(FLYAuthorizationStatus,NSString*))callback status:(FLYAuthorizationStatus)status message:(NSString*)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (callback) {
            callback(status,message);
        }
    });
}

@end
