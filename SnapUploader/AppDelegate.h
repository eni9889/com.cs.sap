//
//  AppDelegate.h
//  SnapUploader
//
//  Created by tsinglink on 15/9/9.
//  Copyright (c) 2015年 tsinglink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>
#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "MyNavigationController.h"

#define kCCSUploader 1

//#define kLoginToServerDidEnd @"LoginToServerDidEnd"
//#define kLoginToServerWillBegin @"LoginToServerWillBegin"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIViewController *curPopViewController;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic)LoginViewController *loginViewController;
@property (strong, nonatomic)MyNavigationController *rootNavViewController;
@property (nonatomic, retain) GADBannerView *adBanner;

- (void)showMainView;
+ (AppDelegate *)app;
@end

