//
//  AVCaptureViewController.m
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/15.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "AVCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HTWCaptureVideoPreviewView.h"
#import "HTWSampleBufferDisplayView.h"
#import "HTWAVCaptureObject.h"
//h264加密
#import "H264Encode.h"
//檔案
#import "HTWFile.h"

@interface AVCaptureViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,UIPickerViewDataSource,UIPickerViewDelegate,H264HwEncoderDelegate>
//HTWAVCaptureObject
@property (nonatomic,strong) HTWAVCaptureObject *captureObject;
//加密264
@property (nonatomic,strong) H264Encode *h264Encode;

//視訊截取連線
@property (nonatomic, weak) AVCaptureConnection *videoConnection;
//視訊品質
@property (nonatomic) NSString *captureSessionPreset;
//picker資料
@property (nonatomic,strong) NSArray<NSString *> *pickerData;

//功能鈕
@property (weak, nonatomic) IBOutlet UIButton *videoDeviceButton;
@property (weak, nonatomic) IBOutlet UIButton *audioDeviceButton;
@property (weak, nonatomic) IBOutlet UIButton *capturePresetButton;
@property (weak, nonatomic) IBOutlet UISwitch *videoOutputSwith;
@property (weak, nonatomic) IBOutlet UISwitch *fileOutputSwith;

//視訊畫面
@property (weak, nonatomic) IBOutlet HTWCaptureVideoPreviewView *videoView;
//工具頁狀態鈕
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;
//工具頁
@property (weak, nonatomic) IBOutlet UIVisualEffectView *toolsView;
//工具頁是否隱藏
@property (nonatomic) BOOL isToolsViewHidden;
@property (weak, nonatomic) IBOutlet HTWSampleBufferDisplayView *videoBufferView;


//檔案
@property (nonatomic,strong) NSString *filePath;
@property (nonatomic,strong) NSFileHandle *fileHandle;

@end

@implementation AVCaptureViewController

#pragma mark - 生命週期相關

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /////////////
    //step 1 :建立截取的session
    self.captureObject = [[HTWAVCaptureObject alloc] init];
    //step 2 :建立輸入
    //設定使用的視訊裝置
    for (AVCaptureDevice *device in [HTWAVCaptureObject vedioDevices]) {
        //設定裝置會將輸入加至session
        self.videoDevice = device;
        break;
    }
    //設定使用的聲音裝置
    for (AVCaptureDevice *device in [HTWAVCaptureObject audioDevices]) {
        //設定裝置會將輸入加至session
        self.audioDevice = device;
        break;
    }
    //step 3:開始執行
    [self.captureObject startRunning];
    /////////////
    [self checkCaptureSessionPreset];
    [self checkToolsView];
    [self checkVideoOutputSwith];
    [self checkFileOutputSwith];
    [self outPutToVideoView];

}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.captureObject checkDeviceOrientation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    }];
}

-(void)dealloc
{
    [self.h264Encode end];
}

#pragma mark - 檢查相關

-(void)checkToolsView
{
    NSString *rightButtonTitle = self.isToolsViewHidden?@"顯示":@"隱藏";
    self.rightButton.title = rightButtonTitle;
}

-(void)checkCaptureSessionPreset
{
    NSString *temp = [self.captureSessionPreset stringByReplacingOccurrencesOfString:@"AVCaptureSessionPreset" withString:@""];
    [self.capturePresetButton setTitle:temp forState:UIControlStateNormal];
}

-(void)checkVideoOutputSwith
{
    self.videoOutputSwith.on = (self.captureObject.sampleBufferDelegate != nil);
    self.videoBufferView.hidden = (self.captureObject.sampleBufferDelegate == nil);
}

-(void)checkFileOutputSwith
{
    self.fileOutputSwith.on = (self.fileHandle != nil);
}

#pragma mark - 取得相關

-(BOOL)isToolsViewHidden
{
    return self.toolsView.hidden;
}

-(NSString *)captureSessionPreset
{
    return self.captureObject.captureSessionPreset;
}

-(NSArray<NSString *> *)captureSessionPresets
{
    return self.captureObject.captureSessionPresets;
}

-(AVCaptureConnection *)videoConnection
{
    return self.captureObject.videoConnection;
}

#pragma mark - 設定相關

-(void)setVideoDevice:(AVCaptureDevice *)videoDevice
{
    self.captureObject.videoDevice = videoDevice;
    [self.videoDeviceButton setTitle:videoDevice.localizedName forState:UIControlStateNormal];
}

-(void)setAudioDevice:(AVCaptureDevice *)audioDevice
{
    self.captureObject.audioDevice = audioDevice;
    [self.audioDeviceButton setTitle:audioDevice.localizedName forState:UIControlStateNormal];
}

-(void)setIsToolsViewHidden:(BOOL)isToolsViewHidden
{
    self.toolsView.hidden = isToolsViewHidden;
}

-(void)setCaptureSessionPreset:(NSString *)captureSessionPreset
{
    self.captureObject.captureSessionPreset = captureSessionPreset;
    [self checkCaptureSessionPreset];
}

#pragma mark - 截取影音

//輸出視訊至AVCaptureVideoPreviewLayer
-(void)outPutToVideoView
{
    if (self.captureObject.captureSession) {
        self.videoView.session = self.captureObject.captureSession;
    }
}

-(void)createFile
{
    self.filePath = [HTWFile createFileName:@"test.h264"];
}

#pragma mark - 功能相關

- (IBAction)doRightButton:(id)sender {
    self.isToolsViewHidden = !self.isToolsViewHidden;
    [self checkToolsView];
}

- (IBAction)doVideoDeviceButton:(id)sender {
    NSMutableArray *deviceNames = [NSMutableArray array];
    NSArray *devices = [HTWAVCaptureObject vedioDevices];
    for (AVCaptureDevice *device in devices) {
        [deviceNames addObject:device.localizedName];
    }
    [self showPickerSuorceView:sender dataSource:deviceNames handler:^(NSInteger row) {
        AVCaptureDevice *device = devices[row];
        self.videoDevice = device;
    }];
}

- (IBAction)doAudioDeviceButton:(id)sender {
    NSMutableArray *deviceNames = [NSMutableArray array];
    NSArray *devices = [HTWAVCaptureObject audioDevices];
    for (AVCaptureDevice *device in devices) {
        [deviceNames addObject:device.localizedName];
    }
    [self showPickerSuorceView:sender dataSource:deviceNames handler:^(NSInteger row) {
        AVCaptureDevice *device = devices[row];
        self.audioDevice = device;
    }];
}

- (IBAction)doCapturePresetButton:(id)sender {
    NSMutableArray *deviceNames = [NSMutableArray array];
    for (NSString *captureSessionPreset in self.captureSessionPresets) {
        NSString *temp = [captureSessionPreset stringByReplacingOccurrencesOfString:@"AVCaptureSessionPreset" withString:@""];
        [deviceNames addObject:temp];
    }
    [self showPickerSuorceView:sender dataSource:deviceNames handler:^(NSInteger row) {
        NSString *captureSessionPreset = self.captureSessionPresets[row];
        self.captureSessionPreset = captureSessionPreset;
    }];
}

- (IBAction)doVideoOutputSwith:(UISwitch *)sender {
    self.captureObject.sampleBufferDelegate = sender.on?self:nil;
    [self checkVideoOutputSwith];
//    self.videoBufferView.hidden = (self.captureObject.sampleBufferDelegate == nil);
    [self doFileOutputSwith:self.fileOutputSwith];
}

- (IBAction)doFileOutputSwith:(UISwitch *)sender {

    if (sender.on && self.videoOutputSwith.on) {
        [self createFile];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
        if (!self.h264Encode) {
            
            self.h264Encode = [[H264Encode alloc] init];
//            [self.h264Encode initEncode:1080 height:1920];
            [self.h264Encode initEncode:self.captureObject.outputSize.width height:self.captureObject.outputSize.height];
            self.h264Encode.delegate = self;
        }
    }else{
        
        if (self.h264Encode) {
            [self.h264Encode end];
            self.h264Encode.delegate = nil;
            
            self.h264Encode = nil;
        }
        if (self.fileHandle) {
            [self.fileHandle closeFile];
            self.fileHandle = nil;
        }
    }
    
    [self checkFileOutputSwith];
}

#pragma mark - PickerView

-(void)showPickerSuorceView:(id)sender dataSource:(NSArray<NSString *> *)dataSource handler:(void (^)(NSInteger row))block
{
    self.pickerData = dataSource;
    __weak AVCaptureViewController * weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n\n\n\n\n\n" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.delegate = self;
    picker.dataSource = self;
    [alertController.view addSubview:picker];
    [alertController addAction:({
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSInteger row = [picker selectedRowInComponent:0];
            weakSelf.pickerData = nil;
            if (block) {
                block(row);
            }
        }];
        action;
    })];
    UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
    popoverController.sourceView = sender;
    popoverController.sourceRect = [sender bounds];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return self.pickerData ? 1 : 0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.pickerData.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.pickerData objectAtIndex:row];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!self.captureObject.captureSession.isRunning) {
        return;
    }
    if (self.videoConnection == connection) {
        [self.videoBufferView enqueueSampleBuffer:sampleBuffer];
        [self.h264Encode encode:sampleBuffer];
    } else {
        NSLog(@"采集到音频数据");
    }
}

#pragma mark - H264HwEncoderImplDelegate delegate 解码代理
- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    NSLog(@"gotSpsPps %d %d", (int)[sps length], (int)[pps length]);
    //[sps writeToFile:h264FileSavePath atomically:YES];
    //[pps writeToFile:h264FileSavePath atomically:YES];
    // write(fd, [sps bytes], [sps length]);
    //write(fd, [pps bytes], [pps length]);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    [self.fileHandle writeData:ByteHeader];
    [self.fileHandle writeData:sps];
    [self.fileHandle writeData:ByteHeader];
    [self.fileHandle writeData:pps];
    
}
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"gotEncodedData %d", (int)[data length]);
    //    static int framecount = 1;
    
    // [data writeToFile:h264FileSavePath atomically:YES];
    //write(fd, [data bytes], [data length]);
    if (self.fileHandle != NULL)
    {
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        
        
        /*NSData *UnitHeader;
         if(isKeyFrame)
         {
         char header[2];
         header[0] = '\x65';
         UnitHeader = [NSData dataWithBytes:header length:1];
         framecount = 1;
         }
         else
         {
         char header[4];
         header[0] = '\x41';
         //header[1] = '\x9A';
         //header[2] = framecount;
         UnitHeader = [NSData dataWithBytes:header length:1];
         framecount++;
         }*/
        [self.fileHandle writeData:ByteHeader];
        //[fileHandle writeData:UnitHeader];
        [self.fileHandle writeData:data];
    }
}

@end
