//
//  HTWAVCaptureObject.h
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/18.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface HTWAVCaptureObject : NSObject

//截取session
@property (readonly) AVCaptureSession *captureSession;
//視訊裝置
@property (nonatomic,weak) AVCaptureDevice *videoDevice;
//聲音裝置
@property (nonatomic,weak) AVCaptureDevice *audioDevice;
//視訊品質
@property (nonatomic) NSString *captureSessionPreset;
//輸出sampleBuffer
@property (nonatomic,weak) id<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate> sampleBufferDelegate;
//視訊品質列表
@property (readonly) NSArray<NSString *> *captureSessionPresets;
//視訊截取連線
@property (readonly) AVCaptureConnection *videoConnection;

//所有視訊裝置
+(NSArray *)vedioDevices;
//所有麥克風
+(NSArray *)audioDevices;

//開始錄制
- (void)startRunning;
//檢查方向
-(void)checkDeviceOrientation;

@end
