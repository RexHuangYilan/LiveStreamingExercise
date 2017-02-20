//
//  HTWSampleBufferDisplayView.m
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/17.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "HTWSampleBufferDisplayView.h"

@interface HTWSampleBufferDisplayView()

@property(nonatomic,strong) AVSampleBufferDisplayLayer *videoLayer;

@end

@implementation HTWSampleBufferDisplayView

#pragma mark - 設定相關

-(void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.videoLayer.frame = bounds;
}

-(void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    if (hidden) {
        [self.videoLayer removeFromSuperlayer];
        self.videoLayer = nil;
    }else{
        self.videoLayer = [[AVSampleBufferDisplayLayer alloc] init];
        //呈現影片為填滿
        self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.layer insertSublayer:_videoLayer atIndex:0];
        self.videoLayer.frame = self.bounds;
    }
}

#pragma mark - 取得相關

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self.videoLayer enqueueSampleBuffer:sampleBuffer];
}

@end
