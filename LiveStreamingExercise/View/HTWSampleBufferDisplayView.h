//
//  HTWSampleBufferDisplayView.h
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/17.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface HTWSampleBufferDisplayView : UIView

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
