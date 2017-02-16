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

@interface AVCaptureViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
//截取session
@property (nonatomic,strong) AVCaptureSession *captureSession;
//視訊裝置
@property (nonatomic,weak) AVCaptureDevice *videoDevice;
//聲音裝置
@property (nonatomic,weak) AVCaptureDevice *audioDevice;

//視訊裝置輸入
@property (nonatomic,strong) AVCaptureDeviceInput *videoDeviceInput;
//聲音裝置輸入
@property (nonatomic,strong) AVCaptureDeviceInput *audioDeviceInput;
//視訊品質
@property (nonatomic) NSString *captureSessionPreset;
//視訊品質列表
@property (nonatomic,strong) NSArray<NSString *> *captureSessionPresets;
//picker資料
@property (nonatomic,strong) NSArray<NSString *> *pickerData;

@property (weak, nonatomic) IBOutlet UIButton *videoDeviceButton;
@property (weak, nonatomic) IBOutlet UIButton *audioDeviceButton;
@property (weak, nonatomic) IBOutlet UIButton *capturePresetButton;


//視訊畫面
@property (weak, nonatomic) IBOutlet HTWCaptureVideoPreviewView *videoView;
//工具頁狀態鈕
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;
//工具頁
@property (weak, nonatomic) IBOutlet UIVisualEffectView *toolsView;
//工具頁是否隱藏
@property (nonatomic) BOOL isToolsViewHidden;

@end

@implementation AVCaptureViewController

#pragma mark - 生命週期相關

- (void)viewDidLoad {
    [super viewDidLoad];
    /////////////
    //step 1 :建立截取的session
    [self createSession];
    //step 2 :建立輸入
    //設定使用的視訊裝置
    for (AVCaptureDevice *device in [self vedioDevices]) {
        //設定裝置會將輸入加至session
        self.videoDevice = device;
        break;
    }
    //設定使用的聲音裝置
    for (AVCaptureDevice *device in [self audioDevices]) {
        //設定裝置會將輸入加至session
        self.audioDevice = device;
        break;
    }
    //step 3:開始執行
    [self.captureSession startRunning];
    /////////////
    [self checkToolsView];
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

#pragma mark - 取得相關

-(NSArray *)vedioDevices
{
    if (NSClassFromString(@"AVCaptureDeviceDiscoverySession")) {
        return [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera,AVCaptureDeviceTypeBuiltInTelephotoCamera,AVCaptureDeviceTypeBuiltInDualCamera,AVCaptureDeviceTypeBuiltInDuoCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified] devices];
    }else{
        return [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }
}

-(NSArray *)audioDevices
{
    if (NSClassFromString(@"AVCaptureDeviceDiscoverySession")) {
        return [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone] mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified] devices];
    }else{
        return [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    }
}

-(BOOL)isToolsViewHidden
{
    return self.toolsView.hidden;
}

-(NSString *)captureSessionPreset
{
    return self.captureSession.sessionPreset;
}

#pragma mark - 設定相關

-(void)setVideoDevice:(AVCaptureDevice *)videoDevice
{
    _videoDevice = videoDevice;
    [self.videoDeviceButton setTitle:videoDevice.localizedName forState:UIControlStateNormal];
    //改變裝置時將裝置放到輸入
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
}

-(void)setAudioDevice:(AVCaptureDevice *)audioDevice
{
    _audioDevice = audioDevice;
    [self.audioDeviceButton setTitle:audioDevice.localizedName forState:UIControlStateNormal];
    //改變裝置時將裝置放到輸入
    self.audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
}

-(void)setVideoDeviceInput:(AVCaptureDeviceInput *)videoDeviceInput
{
    //若己有輸入則先刪除
    if (_videoDeviceInput) {
        [self.captureSession removeInput:_videoDeviceInput];
    }
    _videoDeviceInput = videoDeviceInput;
    //將輸入加進session
    if ([self.captureSession canAddInput:videoDeviceInput]) {
        [self.captureSession addInput:videoDeviceInput];
    }
}

-(void)setCaptureSession:(AVCaptureSession *)captureSession
{
    _captureSession = captureSession;
    self.videoView.session = captureSession;
    [self checkCaptureSessionPreset];
}

-(void)setAudioDeviceInput:(AVCaptureDeviceInput *)audioDeviceInput
{
    //若己有輸入則先刪除
    if (_audioDeviceInput) {
        [self.captureSession removeInput:_audioDeviceInput];
    }
    _audioDeviceInput = audioDeviceInput;
    //將輸入加進session
    if ([self.captureSession canAddInput:audioDeviceInput]) {
        [self.captureSession addInput:audioDeviceInput];
    }
}

-(void)setIsToolsViewHidden:(BOOL)isToolsViewHidden
{
    self.toolsView.hidden = isToolsViewHidden;
}

-(void)setCaptureSessionPreset:(NSString *)captureSessionPreset
{
    if (_captureSession) {
        self.captureSession.sessionPreset = captureSessionPreset;
        NSString *temp = [captureSessionPreset stringByReplacingOccurrencesOfString:@"AVCaptureSessionPreset" withString:@""];
        [self.capturePresetButton setTitle:temp forState:UIControlStateNormal];
    }
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

#pragma mark - 功能相關

- (IBAction)doRightButton:(id)sender {
    self.isToolsViewHidden = !self.isToolsViewHidden;
    [self checkToolsView];
}

- (IBAction)doVideoDeviceButton:(id)sender {
    NSMutableArray *deviceNames = [NSMutableArray array];
    NSArray *devices = [self vedioDevices];
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
    NSArray *devices = [self audioDevices];
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

@end
