//
//  HTWCaptureVideoPreviewView.m
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/16.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "HTWCaptureVideoPreviewView.h"

@interface HTWCaptureVideoPreviewView()

@property(nonatomic,strong) AVCaptureVideoPreviewLayer *videoLayer;
@property(nonatomic) BOOL hasOrientationEvent;
@end

@implementation HTWCaptureVideoPreviewView

-(void)addOrientationEvent
{
    if (self.hasOrientationEvent) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    self.hasOrientationEvent = YES;
}

-(void)removeOrientationEvent
{
    if (!self.hasOrientationEvent) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    self.hasOrientationEvent = NO;
}

- (void)orientationChanged:(NSNotification *)notification{
    UIDevice *device = [notification object];
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
    if (_videoLayer) {
        _videoLayer.connection.videoOrientation = [self videoOrientationFromCurrentWithDeviceOrientation:orientation];
    }
}

-(void)dealloc
{
    [self removeOrientationEvent];
}

#pragma mark - 設定相關

-(void)setSession:(AVCaptureSession *)session
{
    _session = session;
    if (_videoLayer) {
        _videoLayer.session = session;
    }
    if (session) {
        [self addOrientationEvent];
        [self.layer insertSublayer:self.videoLayer atIndex:0];
    }else{
        [self removeOrientationEvent];
        [self.videoLayer removeFromSuperlayer];
        self.videoLayer = nil;
    }
}

-(void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    if (self.session) {
        self.videoLayer.frame = bounds;
    }
}

#pragma mark - 取得相關

-(AVCaptureVideoPreviewLayer *)videoLayer
{
    if (!_videoLayer) {
        if (self.session) {
            self.videoLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        }else{
            self.videoLayer = [[AVCaptureVideoPreviewLayer alloc] init];
        }
    }
    return _videoLayer;
}

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
