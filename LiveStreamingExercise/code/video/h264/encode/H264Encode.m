//
//  H264Encode.m
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/20.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "H264Encode.h"



@interface H264Encode()
{
    NSString *error;
    VTCompressionSessionRef encodeSession;
    dispatch_queue_t encodeQueue;
    CMFormatDescriptionRef format;
    BOOL initialized;
    int frameCount;
    NSData *sps;
    NSData *pps;
}

@property(nonatomic) BOOL isInit;

@end

@implementation H264Encode

void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,CMSampleBufferRef sampleBuffer )
{
    if (status != 0) {
        assert(status == 0);
        return;
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"didCompressH264 data is not ready");
        return;
    }
    
    H264Encode *THIS = (__bridge H264Encode*)outputCallbackRefCon;
    
    //Check if we have got a key frame first
    bool keyframe = !CFDictionaryContainsKey((CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    if (keyframe) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,0,&sparameterSet,&sparameterSetSize,&sparameterSetCount, 0);
        
        if (statusCode == noErr) {
            assert(status == 0);
            // Found sps and now check the pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,1,&pparameterSet,&pparameterSetSize,&pparameterSetCount, 0);
            
            if (statusCode == noErr) {
                assert(status == 0);
                // Found pps
                THIS->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                THIS->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                
                if (THIS->_delegate) {
                    [THIS->_delegate gotSpsPps:THIS->sps pps:THIS->pps];
                }
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        assert(statusCodeRet == 0);
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            // Read the NAL unit length
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            // Convert the length value from Big-endian to Little-endian
            // After converting the length value, the start 4 byte will present the NALUnitLength
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            NSData *data = [[NSData alloc]initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            
            if (THIS->_delegate) {
                [THIS->_delegate gotEncodedData:data isKeyFrame:keyframe];
            }
            
            // Move to the next NAL unit in the block buffer
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}

- (id)init
{
    self = [super init];
    if(self) {
        [self initVariables];
    }
    return self;
}

- (void)initVariables
{
    encodeSession = nil;
    initialized = true;
    encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    frameCount = 0;
    sps = NULL;
    pps = NULL;
}

- (void)initEncode:(int)width height:(int)height
{
    dispatch_sync(encodeQueue, ^{
        // Create the compression session
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)(self), &encodeSession);
        NSLog(@"H264: VTCompressionSessionCreate %d", (int)status);
        
        if (status != 0) {
            NSLog(@"H264: Unable to create H264 session");
            error = @"H264: Unable to create H264 session";
            
            return;
        }
        
        // Set the properties
        //設定為即時
        status = VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        NSLog(@"set realtime  return: %d", (int)status);
        
        //h264 profile, 直播一般使用baseline，可减少由于b幀带来的延遲
        status = VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        NSLog(@"set profile  return: %d", (int)status);
        
        //設定bitrate
        int bt = width*height*1;
        status = VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFNumberRef)@(bt));
        status += VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bt / 8), @1]); // Bps
        NSLog(@"set bitrate  return: %d", (int)status);
        
        //設定key frame 間隔，即gop size
        int fps = 25;
        status = VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFNumberRef)@(fps*2)); // change the frame number between 2 I frame
        
        status = VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(fps));
        
        // 关闭重排Frame，因为有了B帧（双向预测帧，根据前后的图像计算出本帧）后，编码顺序可能跟显示顺序不同。此参数可以关闭B帧。
        VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        
        NSLog(@"set framerate return: %d", (int)status);
        
        
        
        // Tell the encoder to start encoding
        VTCompressionSessionPrepareToEncodeFrames(encodeSession);
        self.isInit = YES;
    });
}

- (void)encode:(CMSampleBufferRef)sampleBuffer
{
    if (!self.isInit) {
        return;
    }
    dispatch_sync(encodeQueue, ^{
        frameCount++;
        // Get the CV Image buffer
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        // Create properties
        CMTime presentationTimeStamp = CMTimeMake(frameCount, 1000);
        //CMTime duration = CMTimeMake(1, DURATION);
        VTEncodeInfoFlags flags;
        // Pass it to the encoder
        OSStatus statusCode = VTCompressionSessionEncodeFrame(encodeSession,
                                                              imageBuffer,
                                                              presentationTimeStamp,
                                                              kCMTimeInvalid,
                                                              NULL, NULL, &flags);
        // Check for error
        if (statusCode != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
            error = @"H264: VTCompressionSessionEncodeFrame failed ";
            
            // End the session
            VTCompressionSessionInvalidate(encodeSession);
            if (encodeSession) {
                CFRelease(encodeSession);
                encodeSession = NULL;
            }
            error = NULL;
            
            return;
        }
        
        NSLog(@"H264: VTCompressionSessionEncodeFrame Success");
    });
}

- (void)end
{
    if (!encodeSession) {
        return;
    }
    // Mark the completion
    VTCompressionSessionCompleteFrames(encodeSession, kCMTimeInvalid);
    
    // End the session
    VTCompressionSessionInvalidate(encodeSession);
    if (encodeSession) {
        CFRelease(encodeSession);
        encodeSession = NULL;
    }
    error = NULL;
    
}

@end
