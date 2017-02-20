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

@interface AVCaptureViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
//HTWAVCaptureObject
@property (nonatomic,strong) HTWAVCaptureObject *captureObject;

//視訊截取連線
@property (nonatomic, weak) AVCaptureConnection *videoConnection;
//視訊品質
@property (nonatomic) NSString *captureSessionPreset;
//picker資料
@property (nonatomic,strong) NSArray<NSString *> *pickerData;

@property (weak, nonatomic) IBOutlet UIButton *videoDeviceButton;
@property (weak, nonatomic) IBOutlet UIButton *audioDeviceButton;
@property (weak, nonatomic) IBOutlet UIButton *capturePresetButton;
@property (weak, nonatomic) IBOutlet UISwitch *videoOutputSwith;


//視訊畫面
@property (weak, nonatomic) IBOutlet HTWCaptureVideoPreviewView *videoView;
//工具頁狀態鈕
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;
//工具頁
@property (weak, nonatomic) IBOutlet UIVisualEffectView *toolsView;
//工具頁是否隱藏
@property (nonatomic) BOOL isToolsViewHidden;
@property (weak, nonatomic) IBOutlet HTWSampleBufferDisplayView *videoBufferView;

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
    [self checkToolsView];
    [self checkVideoOutputSwith];
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
    NSString *temp = [captureSessionPreset stringByReplacingOccurrencesOfString:@"AVCaptureSessionPreset" withString:@""];
    [self.capturePresetButton setTitle:temp forState:UIControlStateNormal];
}

#pragma mark - 截取影音

//輸出視訊至AVCaptureVideoPreviewLayer
-(void)outPutToVideoView
{
    if (self.captureObject.captureSession) {
        self.videoView.session = self.captureObject.captureSession;
    }
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
    if (self.videoConnection == connection) {
        [self.videoBufferView enqueueSampleBuffer:sampleBuffer];
    } else {
        NSLog(@"采集到音频数据");
    }
}

@end
