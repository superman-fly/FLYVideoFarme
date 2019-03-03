//
//  ViewController.m
//  FLYVideoFrame
//
//  Created by Fly on 2018/12/23.
//  Copyright © 2018 Fly. All rights reserved.
//

#import "ViewController.h"
#import "FLYAuthorizationTool.h"
#import "FLYWriteVideoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)onAddVideoButtonClick:(id)sender {
    [self checkCameraStatus];
}

/**
 检查相机权限
 */
- (void)checkCameraStatus {
    [FLYAuthorizationTool requestCameraAuthorization:^(FLYAuthorizationStatus status, NSString *message) {
        if (FLYAuthorizationStatusAuthorized == status) {
            [self checkAudioStatus];
        }else {
            NSLog(@"去设置开启");
        }
    }];
}

/**
 检查麦克风权限
 */
- (void)checkAudioStatus {
    [FLYAuthorizationTool requestAudioAuthorization:^(FLYAuthorizationStatus status, NSString *message) {
        if (FLYAuthorizationStatusAuthorized == status) {
            
            FLYWriteVideoViewController *vc = [[FLYWriteVideoViewController alloc] init];
            vc.isNeedFace = YES;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:NULL];
        }else {
            NSLog(@"去设置开启");
        }
    }];
}

@end
