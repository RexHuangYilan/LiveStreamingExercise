//
//  HTWCaptureVideoPreviewView.h
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/16.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface HTWCaptureVideoPreviewView : UIView

@property (nonatomic, strong) AVCaptureSession *session;
@property(nonatomic) AVCaptureVideoOrientation videoOrientation;

@end
