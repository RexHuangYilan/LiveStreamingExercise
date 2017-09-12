//
//  H264Encode.h
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/20.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@protocol H264HwEncoderDelegate <NSObject>

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps;
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame;

@end

@interface H264Encode : NSObject

- (void)initEncode:(int)width  height:(int)height;
- (void)encode:(CMSampleBufferRef )sampleBuffer;
- (void)end;

@property (weak, nonatomic) id<H264HwEncoderDelegate> delegate;

@end
