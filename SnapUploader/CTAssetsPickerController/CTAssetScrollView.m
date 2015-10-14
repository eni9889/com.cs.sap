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
#import "CTAssetScrollView.h"
#import "CTAssetPlayButton.h"
#import "PHAsset+CTAssetsPickerController.h"
#import "NSBundle+CTAssetsPickerController.h"
#import "UIImage+CTAssetsPickerController.h"


NSString * const CTAssetScrollViewDidTapNotification = @"CTAssetScrollViewDidTapNotification";
NSString * const CTAssetScrollViewPlayerWillPlayNotification = @"CTAssetScrollViewPlayerWillPlayNotification";
NSString * const CTAssetScrollViewPlayerWillPauseNotification = @"CTAssetScrollViewPlayerWillPauseNotification";




@interface CTAssetScrollView ()
<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, assign) BOOL didLoadPlayerItem;

@property (nonatomic, assign) CGFloat perspectiveZoomScale;


@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) CTAssetPlayButton *playButton;

@property (nonatomic, assign) BOOL shouldUpdateConstraints;
@property (nonatomic, assign) BOOL didSetupConstraints;


@end





@implementation CTAssetScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        _shouldUpdateConstraints            = YES;
        self.showsVerticalScrollIndicator   = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom                    = NO;
        self.decelerationRate               = UIScrollViewDecelerationRateFast;
        self.delegate                       = self;
        
        [self setupViews];
    }
    
    return self;
}

- (void)dealloc
{
    [self removePlayerNotificationObserver];
    [self removePlayerLoadedTimeRangesObserver];
    [self removePlayerStatusObserver];
}

#pragma mark - Setup

- (void)setupViews
{
    UIImageView *imageView = [UIImageView new];
    imageView.isAccessibilityElement    = YES;
    imageView.accessibilityTraits       = UIAccessibilityTraitImage;
    self.imageView = imageView;
    
    [self addSubview:self.imageView];
    
//    UIProgressView *progressView =
//    [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
//    self.progressView = progressView;
//    
//    [self addSubview:self.progressView];
    
    UIActivityIndicatorView *activityView =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    self.activityView = activityView;
    
    [self addSubview:self.activityView];
}


#pragma mark - Update auto layout constraints

- (void)updateConstraints
{
    if (!self.didSetupConstraints)
    {
        [self autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self updateProgressConstraints];
        [self updateActivityConstraints];
        
        self.didSetupConstraints = YES;
    }

    [self updateContentFrame];
    [super updateConstraints];
}

- (void)updateProgressConstraints
{
    [UIView autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.progressView autoConstrainAttribute:ALAttributeLeading toAttribute:ALAttributeLeading ofView:self.superview withMultiplier:1 relation:NSLayoutRelationEqual];
        [self.progressView autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeTrailing ofView:self.superview withMultiplier:1 relation:NSLayoutRelationEqual];
        [self.progressView autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeBottom ofView:self.superview withMultiplier:1 relation:NSLayoutRelationEqual];
    }];
    
    [UIView autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        [self.progressView autoConstrainAttribute:ALAttributeLeading toAttribute:ALAttributeLeading ofView:self.imageView withMultiplier:1 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.progressView autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeTrailing ofView:self.imageView withMultiplier:1 relation:NSLayoutRelationLessThanOrEqual];
        [self.progressView autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeBottom ofView:self.imageView withMultiplier:1 relation:NSLayoutRelationLessThanOrEqual];
    }];
}

- (void)updateActivityConstraints
{
    [self.activityView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.superview];
    [self.activityView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.superview];
}

- (void)updateContentFrame
{
    CGSize boundsSize = self.bounds.size;
    
//    CGFloat w = self.zoomScale * self.asset.pixelWidth;
//    CGFloat h = self.zoomScale * self.asset.pixelHeight;
//
//    CGFloat dx = (boundsSize.width - w) / 2.0;
//    CGFloat dy = (boundsSize.height - h) / 2.0;
//
//    self.contentOffset = CGPointZero;
//    self.imageView.frame = CGRectMake(dx, dy, w, h);
    

    if (self.image)
    {
        self.contentOffset = CGPointZero;
        CGRect rect = [self scaleAndCropRectForSize:boundsSize image:self.image];
        self.imageView.frame = rect;
    }
    else
    {
        if (self.useSize)
        {
            self.contentOffset = CGPointZero;
            CGRect rect = [self bestFrameFor:self.metaSize targetSize:boundsSize];
            self.imageView.frame = rect;
        }
    }
}

- (CGRect)scaleAndCropRectForSize:(CGSize)targetSize image:(UIImage *)sourceImage
{
    return [self bestFrameFor:sourceImage.size targetSize:targetSize];
}

- (CGRect)bestFrameFor:(CGSize)size targetSize:(CGSize)targetSize
{
    CGFloat width = size.width;
    CGFloat height = size.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = width;
    CGFloat scaledHeight = height;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(size, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
        {
            scaleFactor = heightFactor;
        }
        else
        {
            scaleFactor = widthFactor;
        }
        
        //if (scaleFactor <= 1)
        {
            scaledWidth  = ceil(width * scaleFactor);
            scaledHeight = ceil(height * scaleFactor);
        }
        
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
        {
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            }
        }
    }
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    return thumbnailRect;
}


#pragma mark - Start/stop loading animation

- (void)startActivityAnimating
{
    //[self.playButton setHidden:YES];
    [self.activityView startAnimating];
    [self postPlayerWillPlayNotification];
}

- (void)stopActivityAnimating
{
    //[self.playButton setHidden:NO];
    [self.activityView stopAnimating];
    [self postPlayerWillPauseNotification];
}


#pragma mark - Set progress

- (void)setProgress:(CGFloat)progress
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(progress < 1)];
    [self.progressView setProgress:progress animated:(progress < 1)];
    [self.progressView setHidden:(progress == 1)];
}

// To mimic image downloading progress
// as PHImageRequestOptions does not work as expected
- (void)mimicProgress
{
    CGFloat progress = self.progressView.progress;

    if (progress < 0.95)
    {
        int lowerbound = progress * 100 + 1;
        int upperbound = 95;
        
        int random = lowerbound + arc4random() % (upperbound - lowerbound);
        CGFloat randomProgress = random / 100.0f;

        [self setProgress:randomProgress];
        
        NSInteger randomDelay = 1 + arc4random() % (3 - 1);
        //[self performSelector:@selector(mimicProgress) withObject:nil afterDelay:randomDelay];
    }
}


#pragma mark - asset size

- (CGSize)assetSize
{
    return CGSizeMake(self.asset.pixelWidth, self.asset.pixelHeight);
}

#pragma mark - Bind asset image

- (void)bind:(PHAsset *)asset image:(UIImage *)image requestInfo:(NSDictionary *)info
{
    self.asset = asset;
    self.imageView.accessibilityLabel = asset.accessibilityLabel;    
    self.playButton.hidden = [asset ctassetsPickerIsPhoto];
    
    BOOL isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
    
    if (self.image == nil || !isDegraded)
    {
        BOOL zoom = (!self.image);
        self.image = image;
        self.imageView.image = image;

//        if (isDegraded)
//            [self mimicProgress];
//        else
//            [self setProgress:1];

        [self setNeedsUpdateConstraints];
        [self updateConstraintsIfNeeded];
    }
}

#pragma mark - Bind player item

- (void)bind:(AVPlayerItem *)playerItem requestInfo:(NSDictionary *)info
{
    [self unbindPlayerItem];
    
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;

    CALayer *layer = self.imageView.layer;
    [layer addSublayer:playerLayer];
    [playerLayer setFrame:layer.bounds];
    
    self.player = player;

    [self addPlayerNotificationObserver];
    [self addPlayerLoadedTimeRangesObserver];
    [self addPlayerStatusObserver];
}

- (void)unbindPlayerItem
{
    [self removePlayerNotificationObserver];
    [self removePlayerLoadedTimeRangesObserver];
    [self removePlayerStatusObserver];
    for (CALayer *layer in self.imageView.layer.sublayers)
        [layer removeFromSuperlayer];
    
    self.player = nil;
}

#pragma mark - Gesture recognizers

- (void)addGestureRecognizers
{
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapping:)];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapping:)];
    
    [doubleTap setNumberOfTapsRequired:2.0];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    [singleTap setDelegate:self];
    [doubleTap setDelegate:self];
    
    [self addGestureRecognizer:singleTap];
    [self addGestureRecognizer:doubleTap];
}


#pragma mark - Handle tappings

- (void)handleTapping:(UITapGestureRecognizer *)recognizer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CTAssetScrollViewDidTapNotification object:recognizer];
    
    if (recognizer.numberOfTapsRequired == 2)
    {
        
    }
        //[self zoomWithGestureRecognizer:recognizer];
}


#pragma mark - Scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.shouldUpdateConstraints = YES;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self setScrollEnabled:(self.zoomScale != self.perspectiveZoomScale)];
    
    if (self.shouldUpdateConstraints)
    {
        [self setNeedsUpdateConstraints];
        [self updateConstraintsIfNeeded];
    }
}

#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![touch.view isDescendantOfView:self.playButton];
}


#pragma mark - Notification observer

- (void)addPlayerNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
}

- (void)removePlayerNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}



#pragma mark - Video player item key-value observer

- (void)addPlayerLoadedTimeRangesObserver
{
    [self.player addObserver:self
                  forKeyPath:@"currentItem.loadedTimeRanges"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)removePlayerLoadedTimeRangesObserver
{
    @try {
        [self.player removeObserver:self forKeyPath:@"currentItem.loadedTimeRanges"];
    }
    @catch (NSException *exception) {
        // do noting
    }
}

- (void)addPlayerStatusObserver
{
    [self.player addObserver:self
                  forKeyPath:@"currentItem.status"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)removePlayerStatusObserver
{
    @try {
        [self.player removeObserver:self forKeyPath:@"currentItem.status"];
    }
    @catch (NSException *exception) {
        // do noting
    }
}


#pragma mark - Video playback Key-Value changed

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.player && [keyPath isEqual:@"currentItem.loadedTimeRanges"])
    {
        NSArray *timeRanges = [change objectForKey:NSKeyValueChangeNewKey];

        if (timeRanges && [timeRanges count])
        {
            CMTimeRange timeRange = [timeRanges.firstObject CMTimeRangeValue];
            
            if (CMTIME_COMPARE_INLINE(timeRange.duration, ==, self.player.currentItem.duration))
                [self performSelector:@selector(playerDidLoadItem:) withObject:object];
        }
    }
    
    if (object == self.player && [keyPath isEqual:@"currentItem.status"])
    {
        if ([self.player.currentItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            
            [self performSelector:@selector(playerDidLoadItem:) withObject:object];
        }
        else if ([self.player.currentItem status] == AVPlayerStatusFailed)
        {
            NSLog(@"AVPlayerStatusFailed");
        }
    }
}

#pragma mark - Notifications

- (void)postPlayerWillPlayNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CTAssetScrollViewPlayerWillPlayNotification object:nil];
}

- (void)postPlayerWillPauseNotification
{
    self.isPlaying = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:CTAssetScrollViewPlayerWillPauseNotification object:nil];
}

#pragma mark - Playback events

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self pauseVideo];
}

- (void)playerDidPlay:(id)sender
{
    [self setProgress:1];
    [self.playButton setHidden:YES];
    [self.activityView stopAnimating];
}

- (void)playerDidPause:(id)sender
{
    [self.playButton setHidden:NO];
    [self postPlayerWillPauseNotification];
}

- (void)playerDidLoadItem:(id)sender
{
    if (!self.didLoadPlayerItem)
    {
        [self setDidLoadPlayerItem:YES];
        [self.activityView stopAnimating];
        
        CMTime start = self.player.currentTime;
        CMTimeValue value = CMTimeGetSeconds(self.player.currentItem.duration);
        CMTimeValue minVal = MIN(value, 10);
        CMTime end = CMTimeAdd(start, CMTimeMake(minVal * start.timescale, start.timescale));
        self.player.currentItem.forwardPlaybackEndTime = end;
        [self playVideo];
        [self playerDidPlay:nil];
    }
}

#pragma mark - Playback

- (void)playVideo
{
    if (self.didLoadPlayerItem)
    {
        [self postPlayerWillPlayNotification];
        [self.player play];
        self.isPlaying = YES;
    }
}

- (void)pauseVideo
{
    if (self.didLoadPlayerItem)
    {
        [self postPlayerWillPauseNotification];
        [self.player pause];
    }
    else
    {
        [self stopActivityAnimating];
        [self unbindPlayerItem];
    }
    
    self.isPlaying = NO;
}

@end
