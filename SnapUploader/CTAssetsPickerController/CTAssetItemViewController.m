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
#import "CTAssetItemViewController.h"
#import "CTAssetScrollView.h"
#import "NSBundle+CTAssetsPickerController.h"
#import "PHAsset+CTAssetsPickerController.h"
#import "SAVideoRangeSlider.h"

#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "UsersViewController.h"
#import "UIView+Animation.h"
#import "UIImage+Extension.h"
#import "UIColor+HexColor.h"

#define CTScreenSize [[UIScreen mainScreen] bounds].size
#define CTScreenHeight MAX(CTScreenSize.width, CTScreenSize.height)
#define CTIPhone6 (CTScreenHeight == 667)
#define CTIPhone6Plus (CTScreenHeight == 736)
#define kMaxImageWidth  ((CTIPhone6Plus) ? 298 : ( (CTIPhone6) ? 270.0f : 230.0f ))
#define kMaxImageHeight ((CTIPhone6Plus) ? 194.0f : ( (CTIPhone6) ? 175.0f : 150.0f ))

@interface CTAssetItemViewController ()<AdobeUXImageEditorViewControllerDelegate, SAVideoRangeSliderDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
    CGFloat keyboardY;
    BOOL keyboardShow;
    BOOL pickerDidShow;
    int selectedTime;
}
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, assign) PHImageRequestID playerItemRequestID;
@property (nonatomic, strong) CTAssetScrollView *scrollView;

@property (nonatomic, assign) BOOL didSetupConstraints;
@property (nonatomic, strong)UIBarButtonItem *playButton;
@property (nonatomic, strong)UIButton *closeButton;
@property (nonatomic, strong)UIButton *zoomButton;
@property (nonatomic, strong)UIButton *editButton;
@property (nonatomic, strong)UIButton *secondButton;
@property (nonatomic, strong)UIButton *saveButton;
@property (nonatomic, strong)UIButton *sendButton;
@property (nonatomic, strong)UIImageView *arrowImageView;
@property (nonatomic, strong)SAVideoRangeSlider *videoRangeSlider;

@property (nonatomic, strong)UIToolbar *toolbar;


@property (nonatomic, copy)NSString *videoPath;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) NSLayoutConstraint *centerLayoutConstraints;
@property (nonatomic, strong) NSArray *onKeyLayoutConstraints;

@property (nonatomic, strong)NSMutableArray *secondStrings;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong)NSLayoutConstraint *topConstraint;

@end


@implementation CTAssetItemViewController

+ (CTAssetItemViewController *)assetItemViewControllerForAsset:(PHAsset *)asset
{
    return [[self alloc] initWithAsset:asset];
}

+ (CTAssetItemViewController *)assetItemViewControllerForFile:(NSString *)path asset:(PHAsset *)asset
{
    return [[self alloc] initWithVideoPath:path asset:asset];
}

- (instancetype)initWithAsset:(PHAsset *)asset
{
    if (self = [super init])
    {
        _imageManager = [PHImageManager defaultManager];
        self.asset = asset;
    }
    
    return self;
}

- (instancetype)initWithVideoPath:(NSString *)path asset:(PHAsset *)asset
{
    if (self = [super init])
    {
        self.videoPath = path;
        self.asset = asset;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    selectedTime = 3;
    keyboardShow = NO;
    self.secondStrings = [[NSMutableArray alloc] init];
    for (int i=1; i<11; i++)
    {
        [self.secondStrings addObject:[NSString stringWithFormat:@"%d", i]];
    }
    
    [self setupViews];
    if (self.videoPath != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

        self.scrollView.useSize = YES;
        self.scrollView.metaSize = CGSizeMake(self.asset.pixelWidth, self.asset.pixelHeight);
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:self.videoPath]];
        [self.scrollView setNeedsUpdateConstraints];
        [self.scrollView updateConstraintsIfNeeded];
        [self.scrollView bind:item requestInfo:nil];
    }
    else
    {
        [self requestAssetImage];
    }
}

- (void)playEnd:(NSNotification *)notification
{
    [self.scrollView.player seekToTime:kCMTimeZero];
    [self.scrollView playVideo];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self pauseAsset:self.view];
    [self cancelRequestAsset];
    self.navigationController.navigationBarHidden = NO;
    if ([self.asset ctassetsPickerIsPhoto])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    if ([self.asset ctassetsPickerIsPhoto])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    }
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
    CTAssetScrollView *scrollView = [CTAssetScrollView newAutoLayoutView];
    self.scrollView = scrollView;
    [self.view addSubview:self.scrollView];
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.closeButton];
    [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0.0];
    [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0.0];
    [self.closeButton autoSetDimension:ALDimensionWidth toSize:80.0];
    [self.closeButton autoSetDimension:ALDimensionHeight toSize:80.0];
    [self.closeButton setBackgroundImage:[UIImage imageNamed:@"x_button"] forState:UIControlStateNormal];
    [self.closeButton setBackgroundImage:[UIImage imageNamed:@"x_button_pressed"] forState:UIControlStateHighlighted];
    [self.closeButton addTarget:self action:@selector(closeView:) forControlEvents:UIControlEventTouchUpInside];
    self.secondButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secondButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.secondButton];
    [self.secondButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0.0];
    [self.secondButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0.0];
    [self.secondButton autoSetDimension:ALDimensionWidth toSize:80.0];
    [self.secondButton autoSetDimension:ALDimensionHeight toSize:80.0];
    [self.secondButton setBackgroundImage:[UIImage imageNamed:@"timer_button"] forState:UIControlStateNormal];
    [self.secondButton setBackgroundImage:[UIImage imageNamed:@"timer_button_pressed"] forState:UIControlStateHighlighted];
    [self.secondButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.secondButton addTarget:self action:@selector(settingTime:) forControlEvents:UIControlEventTouchUpInside];
    [self.secondButton setTitle:[NSString stringWithFormat:@"%d",selectedTime] forState:UIControlStateNormal];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.saveButton];
    [self.saveButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0.0];
    [self.saveButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:80.0];
    [self.saveButton autoSetDimension:ALDimensionWidth toSize:80.0];
    [self.saveButton autoSetDimension:ALDimensionHeight toSize:80.0];
    [self.saveButton setBackgroundImage:[UIImage imageNamed:@"save_button"] forState:UIControlStateNormal];
    [self.saveButton setBackgroundImage:[UIImage imageNamed:@"save_button_pressed"] forState:UIControlStateHighlighted];
    [self.saveButton addTarget:self action:@selector(saveAssets:) forControlEvents:UIControlEventTouchUpInside];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.sendButton];
    [self.sendButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0];
    [self.sendButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0.0];
    [self.sendButton autoSetDimension:ALDimensionWidth toSize:90.0];
    [self.sendButton autoSetDimension:ALDimensionHeight toSize:60.0];
    [self.sendButton setBackgroundImage:[UIImage imageNamed:@"send_button_pressed"] forState:UIControlStateHighlighted];
    [self.sendButton addTarget:self action:@selector(readyToSend:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton addTarget:self action:@selector(touchDownHandle:) forControlEvents:UIControlEventTouchDown];
    [self.sendButton addTarget:self action:@selector(touchOutHandle:) forControlEvents:UIControlEventTouchUpOutside];
    
    self.arrowImageView = [UIImageView newAutoLayoutView];
    [self.sendButton addSubview:self.arrowImageView];
    [self.arrowImageView autoCenterInSuperview];
    [self.arrowImageView autoSetDimension:ALDimensionWidth toSize:90.0];
    [self.arrowImageView autoSetDimension:ALDimensionHeight toSize:60.0];
    self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *image = [UIImage imageNamed:@"arrow0"];
    UIImage *image1 = [UIImage imageNamed:@"arrow1"];
    UIImage *image2 = [UIImage imageNamed:@"arrow2"];
    UIImage *image3 = [UIImage imageNamed:@"arrow3"];
    self.arrowImageView.animationImages = @[image, image1, image2, image3];
    self.arrowImageView.animationDuration = 2.0;
    [self.arrowImageView startAnimating];

    if ([self.asset ctassetsPickerIsPhoto])
    {
//        self.zoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        self.zoomButton.translatesAutoresizingMaskIntoConstraints = NO;
//        [self.view addSubview:self.zoomButton];
//        [self.zoomButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0.0];
//        [self.zoomButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:80.0];
//        [self.zoomButton autoSetDimension:ALDimensionWidth toSize:80.0];
//        [self.zoomButton autoSetDimension:ALDimensionHeight toSize:80.0];
//        [self.zoomButton setBackgroundImage:[UIImage imageNamed:@"zoomin"] forState:UIControlStateNormal];
//        [self.zoomButton addTarget:self action:@selector(zoomView:) forControlEvents:UIControlEventTouchUpInside];
        
        self.editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.editButton];
        [self.editButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0.0];
        [self.editButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0.0];
        [self.editButton autoSetDimension:ALDimensionWidth toSize:80.0];
        [self.editButton autoSetDimension:ALDimensionHeight toSize:80.0];
        [self.editButton setBackgroundImage:[UIImage imageNamed:@"pen_button"] forState:UIControlStateNormal];
        [self.editButton setBackgroundImage:[UIImage imageNamed:@"pen_button_pressed"] forState:UIControlStateHighlighted];
        [self.editButton addTarget:self action:@selector(editImage:) forControlEvents:UIControlEventTouchUpInside];
        
        self.textField = [UITextField newAutoLayoutView];
        [self.view addSubview:self.textField];
        self.textField.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
        self.textField.textColor = [UIColor whiteColor];
        self.textField.font = [UIFont systemFontOfSize:18];
        self.textField.returnKeyType = UIReturnKeyDone;
        self.textField.delegate = self;
        self.textField.borderStyle = UITextBorderStyleNone;
        [self.textField autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.textField autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        self.textField.alpha = 0.0;
        


        [self.textField autoSetDimension:ALDimensionHeight toSize:45.0];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                   selector:@selector(assetPlayerWillPlay:)
                       name:CTAssetScrollViewPlayerWillPlayNotification
                     object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                   selector:@selector(assetPlayerWillPause:)
                       name:CTAssetScrollViewPlayerWillPauseNotification
                     object:nil];
    }
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapAction:)];
    [self.scrollView addGestureRecognizer:tapGesture];
    
    self.picker = [UIPickerView newAutoLayoutView];
    [self.view addSubview:self.picker];
    [self.picker autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.picker autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.picker autoSetDimension:ALDimensionHeight toSize:250];
    self.topConstraint = [self.picker autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-250];
    self.picker.backgroundColor = [UIColor colorFromHex:0xe4e4e4];
    self.picker.delegate = self;
    self.picker.dataSource = self;

    [self.view layoutIfNeeded];
}

- (void)updateViewConstraints
{
    if (keyboardShow)
    {
        [self.centerLayoutConstraints autoRemove];
        self.centerLayoutConstraints = [self.textField autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:(keyboardY - 45.0)];
    }
    else
    {
        [self.centerLayoutConstraints autoRemove];
        self.centerLayoutConstraints = [self.textField autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.view];
    }

    if (pickerDidShow)
    {
        self.topConstraint.constant = 0;
    }
    else
    {
        self.topConstraint.constant = 250;
    }
    [super updateViewConstraints];
}

- (IBAction)settingTime:(id)sender
{
    pickerDidShow = !pickerDidShow;
    [self.picker selectRow:(selectedTime - 1) inComponent:0 animated:NO];
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    [UIView animateWithDuration:0.25
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                        
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         
                     }];

}

- (void)handleTapAction:(UITapGestureRecognizer *)gesture
{
    if (pickerDidShow)
    {
        [self settingTime:nil];
    }
    else
    {
        [self.textField becomeFirstResponder];
    }
    
}

- (void)handleWillShowKeyboard:(NSNotification *)notification
{
    
    keyboardShow = YES;
    [self keyboardWillShowHide:notification];
}

- (void)handleWillHideKeyboard:(NSNotification *)notification
{
    keyboardShow = NO;
    [self keyboardWillShowHide:notification];
}

- (void)keyboardWillShowHide:(NSNotification *)notification
{
    if (keyboardShow)
    {
        self.textField.textAlignment = NSTextAlignmentLeft;
        self.textField.alpha  = 1.0;
    }
    else
    {
        self.textField.textAlignment = NSTextAlignmentCenter;
        self.textField.alpha  = [self.textField.text length] > 0 ? 1.0 : 0.0;
    }
    NSLog(@"%@", self.textField.text);
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:[UIView animationOptionsForCurve:curve]
                     animations:^{

                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
 
                     }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.textField resignFirstResponder];
    NSLog(@"%@", self.textField.text);
    return YES;
}

- (void)assetPlayerWillPlay:(NSNotification *)notification
{
    
}

- (void)assetPlayerWillPause:(NSNotification *)notification
{
    [self.scrollView.player seekToTime:kCMTimeZero];
    [self.scrollView playVideo];
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
    self.navigationController.navigationBarHidden = NO;
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.window.rootViewController = app.loginViewController.myTabBarController;
}

- (IBAction)saveAssets:(id)sender
{
    if ([self.asset ctassetsPickerIsPhoto])
    {
        UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    }
    else
    {
        UISaveVideoAtPathToSavedPhotosAlbum(self.videoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    if(error != NULL)
    {
        [SVProgressHUD showErrorWithStatus:@"Faild"];
    }
    else
    {
        [SVProgressHUD showSuccessWithStatus:@"Success"];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    if(error != NULL)
    {
        [SVProgressHUD showErrorWithStatus:@"Faild"];
    }
    else
    {
        [SVProgressHUD showSuccessWithStatus:@"Success"];
    }
}

- (IBAction)editImage:(id)sender
{
    AdobeUXImageEditorViewController *editorController = [[AdobeUXImageEditorViewController alloc] initWithImage:self.scrollView.image];
    [editorController setDelegate:self];
    [self presentViewController:editorController animated:YES completion:nil];
}

- (void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image
{
    self.scrollView.image = image;
    self.scrollView.imageView.image = image;
    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView updateConstraintsIfNeeded];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)photoEditorCanceled:(AdobeUXImageEditorViewController *)editor
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)readyToSend:(id)sender
{
    [self.arrowImageView startAnimating];
    UsersViewController *userView = [[UsersViewController alloc] initWithNibName:@"UsersViewController" bundle:nil];
    if ([self.asset ctassetsPickerIsPhoto])
    {
        NSString *destinationPath = [NSString stringWithFormat:@"%@/snapExport.jpg", NSTemporaryDirectory()];
        BOOL dir = NO;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&dir];
        if (isExist)
        {
            [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
        }
        
        UIImage *scaledImage = [self.image addTextOnImage:CGSizeMake(kMaxImageWidth, kMaxImageWidth) text:self.textField.text];
        [UIImageJPEGRepresentation(scaledImage, 1.0) writeToFile:destinationPath atomically:YES];
        userView.filePath = destinationPath;
    }
    else
    {
        userView.filePath = self.videoPath;
    }
    userView.seconds = selectedTime;
    [self.navigationController pushViewController:userView animated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:18],
                                  NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName:[UIColor whiteColor]};
    CGRect textRect = [textField.text boundingRectWithSize:CGSizeMake(self.view.frame.size.width + 20, 45.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    if (textRect.size.width > self.view.frame.size.width && ![string isEqualToString:@""])
    {
        return NO;
    }
    
    return YES;
}

- (IBAction)touchDownHandle:(id)sender
{
    [self.arrowImageView stopAnimating];
}

- (IBAction)touchOutHandle:(id)sender
{
    [self.arrowImageView startAnimating];
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
                                          [self.scrollView bind:self.asset image:image requestInfo:info];
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
                CMTimeValue value = self.scrollView.player.currentItem.duration.value;
                CMTimeValue minVal = MIN(value, 10);
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

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
{
    if (component == 0)
    {
        return [self.secondStrings count];
    }
    return 1;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return 100.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 55.0;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0)
    {
        return [self.secondStrings objectAtIndex:row];
    }
    
    return @"seconds";
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component == 0)
    {
        selectedTime = [[self.secondStrings objectAtIndex:row] intValue];
        [self.secondButton setTitle:[NSString stringWithFormat:@"%d",selectedTime] forState:UIControlStateNormal];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
