//
//  HTWAVCaptureObject.m
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/18.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTWAVCaptureObject.h"

@interface HTWAVCaptureObject()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

//截取session
@property (nonatomic,strong) AVCaptureSession *captureSession;
//視訊裝置輸入
@property (nonatomic,strong) AVCaptureDeviceInput *videoDeviceInput;
//聲音裝置輸入
@property (nonatomic,strong) AVCaptureDeviceInput *audioDeviceInput;
//視訊裝置輸出
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoOutput;
//聲音裝置輸出
@property (nonatomic,strong) AVCaptureAudioDataOutput *audioOutput;
//視訊截取連線
@property (nonatomic,strong) AVCaptureConnection *videoConnection;
//視訊品質列表
@property (nonatomic,strong) NSArray<NSString *> *captureSessionPresets;

@end

@implementation HTWAVCaptureObject

-(id)init
{
    self = [super init];
    if (self) {
        [self createSession];
    }
    return self;
}

-(void)dealloc
{
    [self.captureSession stopRunning];
    self.captureSession = nil;
}

#pragma mark - 截取影音

//建立截取session
-(void)createSession
{
    self.captureSession = [[AVCaptureSession alloc] init];
    [self createCaptureSessionPreset];
}

//建立可用拍攝模式
-(void)createCaptureSessionPreset
{
    if (!self.captureSession) {
        return;
    }
    NSMutableArray *sessions = [NSMutableArray array];
    NSArray *tempSessions = @[
                              AVCaptureSessionPresetPhoto,
                              AVCaptureSessionPresetHigh,
                              AVCaptureSessionPresetMedium,
                              AVCaptureSessionPresetLow,
                              AVCaptureSessionPreset352x288,
                              AVCaptureSessionPreset640x480,
                              AVCaptureSessionPreset1280x720,
                              AVCaptureSessionPreset1920x1080,
                              //                              AVCaptureSessionPreset3840x2160,
                              AVCaptureSessionPresetiFrame960x540,
                              AVCaptureSessionPresetiFrame1280x720,
                              AVCaptureSessionPresetInputPriority,
                              ];
    for (NSString *session in tempSessions) {
        if ([self.captureSession canSetSessionPreset:session]) {
            [sessions addObject:session];
        }
    }
    self.captureSessionPresets = [NSArray arrayWithArray:sessions];
}

//開始錄制
- (void)startRunning
{
    [self.captureSession startRunning];
}

#pragma mark - 取得相關

+(NSArray *)vedioDevices
{
    if (NSClassFromString(@"AVCaptureDeviceDiscoverySession")) {
        return [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera,AVCaptureDeviceTypeBuiltInTelephotoCamera,AVCaptureDeviceTypeBuiltInDualCamera,AVCaptureDeviceTypeBuiltInDuoCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified] devices];
    }else{
        return [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }
}

+(NSArray *)audioDevices
{
    if (NSClassFromString(@"AVCaptureDeviceDiscoverySession")) {
        return [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone] mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified] devices];
    }else{
        return [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    }
}

#pragma mark - 設定相關

-(void)setVideoDevice:(AVCaptureDevice *)videoDevice
{
    _videoDevice = videoDevice;
    //改變裝置時將裝置放到輸入
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
}

-(void)setAudioDevice:(AVCaptureDevice *)audioDevice
{
    _audioDevice = audioDevice;
    //改變裝置時將裝置放到輸入
    self.audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
}

-(void)setVideoDeviceInput:(AVCaptureDeviceInput *)videoDeviceInput
{
    [self.captureSession beginConfiguration];
    //若己有輸入則先刪除
    if (_videoDeviceInput) {
        [self.captureSession removeInput:_videoDeviceInput];
    }
    _videoDeviceInput = videoDeviceInput;
    //將輸入加進session
    if ([self.captureSession canAddInput:videoDeviceInput]) {
        [self.captureSession addInput:videoDeviceInput];
    }
    [self.captureSession commitConfiguration];
}

-(void)setVideoOutput:(AVCaptureVideoDataOutput *)videoOutput
{
    [self.captureSession beginConfiguration];
    //若己有輸出則先刪除
    if (_videoOutput) {
        [self.captureSession removeOutput:_videoOutput];
    }
    _videoOutput = videoOutput;
    
    if (videoOutput) {
        /*輸出有三個format
         kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
         kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
         kCVPixelFormatType_32BGRA.
        */
        NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
        NSNumber* val = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
        NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:val forKey:key];
        videoOutput.videoSettings = videoSettings;
        dispatch_queue_t videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
        [videoOutput setSampleBufferDelegate:self.sampleBufferDelegate queue:videoQueue];
        //將輸出加進session
        if ([self.captureSession canAddOutput:videoOutput]) {
            [self.captureSession addOutput:videoOutput];
        }
        self.videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
        [self checkDeviceOrientation];
    }
    [self.captureSession commitConfiguration];
}

-(void)setAudioDeviceInput:(AVCaptureDeviceInput *)audioDeviceInput
{
    [self.captureSession beginConfiguration];
    //若己有輸入則先刪除
    if (_audioDeviceInput) {
        [self.captureSession removeInput:_audioDeviceInput];
    }
    _audioDeviceInput = audioDeviceInput;
    //將輸入加進session
    if ([self.captureSession canAddInput:audioDeviceInput]) {
        [self.captureSession addInput:audioDeviceInput];
    }
    [self.captureSession commitConfiguration];
}

-(void)setAudioOutput:(AVCaptureAudioDataOutput *)audioOutput
{
    [self.captureSession beginConfiguration];
    //若己有輸出則先刪除
    if (_audioOutput) {
        [self.captureSession removeOutput:_audioOutput];
    }
    _audioOutput = audioOutput;
    if (audioOutput) {
        dispatch_queue_t audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
        [audioOutput setSampleBufferDelegate:self.sampleBufferDelegate queue:audioQueue];
        //將輸出加進session
        if ([self.captureSession canAddOutput:audioOutput]) {
            [self.captureSession addOutput:audioOutput];
        }
    }
    [self.captureSession commitConfiguration];
}

-(void)setCaptureSessionPreset:(NSString *)captureSessionPreset
{
    if (_captureSession) {
        [self.captureSession beginConfiguration];
        self.captureSession.sessionPreset = captureSessionPreset;
        [self.captureSession commitConfiguration];
    }
}

-(void)setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>)sampleBufferDelegate
{
    _sampleBufferDelegate = sampleBufferDelegate;
    if (sampleBufferDelegate) {
        self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];;
    }else{
        self.videoOutput = nil;
    }
}

#pragma mark - 檢查相關

-(void)checkDeviceOrientation
{
    UIDevice *device = [UIDevice currentDevice];
    UIDeviceOrientation orientation = device.orientation;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
        case UIDeviceOrientationPortraitUpsideDown:
            break;
        default:{
            return;
        }
    }
    if (self.videoConnection) {
        self.videoConnection.videoOrientation = [self videoOrientationFromCurrentWithDeviceOrientation:orientation];
    }
}

#pragma mark - 轉向相關

- (AVCaptureVideoOrientation) videoOrientationFromCurrentWithDeviceOrientation:(UIDeviceOrientation)orientation {
    switch (orientation) {
        case UIDeviceOrientationPortrait: {
            return AVCaptureVideoOrientationPortrait;
        }
        case UIDeviceOrientationLandscapeLeft: {
            return AVCaptureVideoOrientationLandscapeRight;
        }
        case UIDeviceOrientationLandscapeRight: {
            return AVCaptureVideoOrientationLandscapeLeft;
        }
        case UIDeviceOrientationPortraitUpsideDown: {
            return AVCaptureVideoOrientationPortraitUpsideDown;
        }
        default:{
            return AVCaptureVideoOrientationPortrait;
        }
    }
}


@end
