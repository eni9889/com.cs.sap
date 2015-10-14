/*
 
 MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */


#import "PureLayout.h"
#import "EditVideoController.h"
#import "CTAssetScrollView2.h"
#import "NSBundle+CTAssetsPickerController.h"
#import "PHAsset+CTAssetsPickerController.h"
#import "SAVideoRangeSlider.h"

#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "UsersViewController.h"
#import "CTAssetItemViewController.h"
#import "MyNavigationController.h"

@interface EditVideoController ()<SAVideoRangeSliderDelegate>
{
    id playEndObserver;
}
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) PHImageManager *exportManager;
@property (nonatomic, strong) PHImageManager *imageManager2;
@property (nonatomic, assign) PHImageRequestID imageRequestID2;
@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, assign) PHImageRequestID playerItemRequestID;
@property (nonatomic, strong) CTAssetScrollView2 *scrollView;

@property (nonatomic, assign) BOOL didSetupConstraints;
@property (nonatomic, strong)UIBarButtonItem *playButton;
@property (nonatomic, strong)SAVideoRangeSlider *videoRangeSlider;

@property (nonatomic, strong)UIToolbar *toolbar;

@end


@implementation EditVideoController

+ (EditVideoController *)assetItemViewControllerForAsset:(PHAsset *)asset
{
    return [[self alloc] initWithAsset:asset];
}

- (instancetype)initWithAsset:(PHAsset *)asset
{
    if (self = [super init])
    {
        _imageManager = [PHImageManager defaultManager];
        _imageManager2 = [PHImageManager defaultManager];
        _exportManager = [PHImageManager defaultManager];
        self.asset = asset;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
   
    [self setupViews];
    [self requestAssetImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self pauseAsset:self.view];
    [self cancelRequestAsset];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView updateConstraintsIfNeeded];
}

#pragma mark - Setup

- (void)setupViews
{
    CTAssetScrollView2 *scrollView = [CTAssetScrollView2 newAutoLayoutView];
    self.scrollView = scrollView;
    [self.view addSubview:self.scrollView];

    self.toolbar = [UIToolbar newAutoLayoutView];
    [self.view addSubview:self.toolbar];
    self.toolbar.tintColor = [UIColor whiteColor];
    self.toolbar.barTintColor = [UIColor grayColor];
    [self.toolbar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.toolbar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.toolbar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                              style:UIBarButtonItemStylePlain
                                                            target:self action:@selector(cancelPlay:)];
    self.playButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"VideoEdit_PlayButtonNormal"] style:UIBarButtonItemStylePlain target:self action:@selector(playAsset:)];
    
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithTitle:@"Choose"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self action:@selector(chooseVideo:)];
    [item3 setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont systemFontOfSize:20.0]} forState:UIControlStateNormal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont systemFontOfSize:20.0]} forState:UIControlStateNormal];
    self.toolbar.items = @[[self flexiSpace],item, [self flexiSpace], self.playButton, [self flexiSpace], item3, [self flexiSpace]];
    PHVideoRequestOptions *options = [self videoRequestOptions];
    self.imageRequestID2 = [self.imageManager2 requestAVAssetForVideo:self.asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info){
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSError *error = [info objectForKey:PHImageErrorKey];
            
            if (error == nil)
            {
                AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
                self.videoRangeSlider = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(0, 0, app.window.bounds.size.width, 49) videoUrl:asset];
                self.videoRangeSlider.delegate = self;
                self.videoRangeSlider.maxGap = 10.0;
                [self.view addSubview:self.videoRangeSlider];
            }
        });
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(assetPlayerWillPlay:)
                   name:CTAssetScrollViewPlayerWillPlayNotification2
                 object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(assetPlayerWillPause:)
                   name:CTAssetScrollViewPlayerWillPauseNotification2
                 object:nil];
    [self addPlayEndNotify];
    

    [self.view layoutIfNeeded];
}

- (void)addPlayEndNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)playEnd:(NSNotification *)notification
{
    [self.scrollView playerDidPause:nil];
}

- (void)assetPlayerWillPlay:(NSNotification *)notification
{
    self.playButton.image = [UIImage imageNamed:@"VideoEdit_PauseButtonNormal.png"];
}

- (void)assetPlayerWillPause:(NSNotification *)notification
{
   self.playButton.image = [UIImage imageNamed:@"VideoEdit_PlayButtonNormal.png"];
    
}

- (void)videoRange:(SAVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition
{
    [self.scrollView pauseVideo];
    [self.scrollView.player seekToTime:CMTimeMakeWithSeconds((int)leftPosition, 1)];
}

- (void)videoRange:(SAVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition
{
    [self.scrollView pauseVideo];
    [self.scrollView.player seekToTime:CMTimeMakeWithSeconds((int)leftPosition, 1)];
}

- (void)videoRange:(SAVideoRangeSlider *)videoRange didChangeRightPosition:(CGFloat)rightPosition
{
    [self.scrollView pauseVideo];
    [self.scrollView.player seekToTime:CMTimeMakeWithSeconds((int)rightPosition, 1)];
}

- (void)closeView:(id)sender
{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.window.rootViewController = app.loginViewController.myTabBarController;
}

- (IBAction)chooseVideo:(id)sender
{
    CMTime startTm = CMTimeMake((int)self.videoRangeSlider.leftPosition, 1.0);
    CMTime duration = CMTimeMake((int)self.videoRangeSlider.rightPosition - (int)self.videoRangeSlider.leftPosition, 1.0);
    
    [self.scrollView pauseVideo];
    [SVProgressHUD showWithStatus:@"Processing..."];
    _exportManager = [[PHImageManager alloc] init];
    [_exportManager requestExportSessionForVideo:self.asset options:[self videoRequestOptions] exportPreset:AVAssetExportPreset640x480 resultHandler:^(AVAssetExportSession *exportSession, NSDictionary *info){
        NSString *destinationPath = [NSString stringWithFormat:@"%@/videoExport.mp4", NSTemporaryDirectory()];
        BOOL dir = NO;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&dir];
        if (isExist)
        {
            [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
        }
        exportSession.outputURL = [NSURL fileURLWithPath:destinationPath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.timeRange = CMTimeRangeMake(startTm, duration);
        [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
            if (exportSession.status == AVAssetExportSessionStatusCompleted)
            {
                NSLog(@"success");
                dispatch_async(dispatch_get_main_queue(), ^{

                    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
                    CTAssetItemViewController *itemView = [CTAssetItemViewController assetItemViewControllerForFile:destinationPath asset:self.asset];
                    MyNavigationController *nav = [[MyNavigationController alloc] initWithRootViewController:itemView];
                    app.window.rootViewController = nav;
                });
            }
            else
            {
                NSLog(@"error: %@", [exportSession error]);
            }
        }];
        
    }];
}

- (IBAction)cancelPlay:(id)sender
{
    [self closeView:nil];
}

#pragma mark - Cancel request

- (void)cancelRequestAsset
{
    [self cancelRequestImage];
    [self cancelRequestPlayerItem];
}

- (void)cancelRequestImage
{
    if (self.imageRequestID)
    {
        [self.scrollView setProgress:1];
        [self.imageManager cancelImageRequest:self.imageRequestID];
    }
    
    if (self.imageRequestID2)
    {
        [self.imageManager2 cancelImageRequest:self.imageRequestID2];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)cancelRequestPlayerItem
{
    if (self.playerItemRequestID)
    {
        [self.scrollView stopActivityAnimating];
        [self.imageManager cancelImageRequest:self.playerItemRequestID];
    }
    
    if (self.imageRequestID2)
    {
        [self.imageManager2 cancelImageRequest:self.imageRequestID2];
    }
}

#pragma mark - Request image

- (void)requestAssetImage
{
    [self.scrollView setProgress:0];
    
    CGSize targetSize = [self targetImageSize];
    PHImageRequestOptions *options = [self imageRequestOptions];
    
    self.imageRequestID =
    [self.imageManager requestImageForAsset:self.asset
                                 targetSize:targetSize
                                contentMode:PHImageContentModeAspectFit
                                    options:options
                              resultHandler:^(UIImage *image, NSDictionary *info) {

                                  // this image is set for transition animation
                                  self.image = image;
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                  
                                      NSError *error = [info objectForKey:PHImageErrorKey];
                                      
                                      if (error)
                                          [self showRequestImageError:error title:nil];
                                      else
                                      {
                                          [self.scrollView bind:self.asset image:image requestInfo:info];
                                          [self requestAssetPlayerItem:nil];
                                      }
                                  });
                              }];
}

- (CGSize)targetImageSize
{
    UIScreen *screen    = UIScreen.mainScreen;
    CGFloat scale       = screen.scale;
    return CGSizeMake(CGRectGetWidth(screen.bounds) * scale, CGRectGetHeight(screen.bounds) * scale);
}

- (PHImageRequestOptions *)imageRequestOptions
{
    PHImageRequestOptions *options  = [PHImageRequestOptions new];
    options.networkAccessAllowed    = YES;
    options.progressHandler         = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //XXX never get called
            [self.scrollView setProgress:progress];
        });
    };
    
    return options;
}

#pragma mark - Request player item

- (void)requestAssetPlayerItem:(id)sender
{
    [self.scrollView startActivityAnimating];
    
    PHVideoRequestOptions *options = [self videoRequestOptions];
    
    self.playerItemRequestID =
    [self.imageManager requestPlayerItemForVideo:self.asset
                                         options:options
                                   resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           
                                           NSError *error   = [info objectForKey:PHImageErrorKey];
                                           NSString * title = CTAssetsPickerLocalizedString(@"Cannot Play Stream Video", nil);
                                           
                                           if (error)
                                               [self showRequestVideoError:error title:title];
                                           else
                                               [self.scrollView bind:playerItem requestInfo:info];
                                       });
                                   }];
}

- (PHVideoRequestOptions *)videoRequestOptions
{
    PHVideoRequestOptions *options  = [PHVideoRequestOptions new];
    options.networkAccessAllowed    = YES;
    options.progressHandler         = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //XXX never get called
        });
    };
    
    return options;
}

#pragma mark - Request error

- (void)showRequestImageError:(NSError *)error title:(NSString *)title
{
    [self.scrollView setProgress:1];
    [self showRequestError:error title:title];
}

- (void)showRequestVideoError:(NSError *)error title:(NSString *)title
{
    [self.scrollView stopActivityAnimating];
    [self showRequestError:error title:title];
}

- (void)showRequestError:(NSError *)error title:(NSString *)title
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:error.localizedDescription
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action =
    [UIAlertAction actionWithTitle:CTAssetsPickerLocalizedString(@"OK", nil)
                             style:UIAlertActionStyleDefault
                           handler:nil];
    
    [alert addAction:action];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Playback

- (void)playAsset:(id)sender
{
    if (!self.scrollView.player)
    {
        [self requestAssetPlayerItem:sender];
    }
    else
    {
        if (self.scrollView.isPlaying)
        {
            [self.scrollView pauseVideo];
        }
        else
        {
            CMTime start = self.scrollView.player.currentTime;
            int currentTime = CMTimeGetSeconds(start);
            int rightPos = (int)self.videoRangeSlider.rightPosition;
            if (currentTime >= rightPos)
            {
                [self.scrollView.player seekToTime:CMTimeMakeWithSeconds((int)self.videoRangeSlider.leftPosition, 1)];
                CMTimeValue value = CMTimeGetSeconds(self.scrollView.player.currentItem.duration);
                CMTimeValue minVal = MIN(value, 10);
                start = self.scrollView.player.currentTime;
                CMTime end = CMTimeAdd(start, CMTimeMake(minVal * start.timescale, start.timescale));
                self.scrollView.player.currentItem.forwardPlaybackEndTime = end;
            }
           
            [self.scrollView playVideo];
        }
    }
}

- (void)pauseAsset:(id)sender
{
    if (!self.scrollView.player)
        [self cancelRequestPlayerItem];
    else
        [self.scrollView pauseVideo];
}

- (UIBarButtonItem *)flexiSpace
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    return item;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
