//
//  AppDelegate.m
//  SnapUploader
//
//  Created by tsinglink on 15/9/9.
//  Copyright (c) 2015年 tsinglink. All rights reserved.
//

#import "AppDelegate.h"

#import "UIColor+HexColor.h"
#import "MyNavigationController.h"
#import "NSBundle+CTAssetsPickerController.h"
#import "SVProgressHUD.h"
#import "iRate.h"
#import "SKClient.h"

@interface AppDelegate ()
{
    
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [self showMainView];
    
    
    [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:@"16015d85dcc843eaa46f6db3a3675754" clientSecret:@"512c4633-c473-4318-9bfa-4c7d134bf88d" enableSignUp:NO];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorFromHex:0x2e926b]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    [[UITabBarItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, -10.0)];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor redColor], NSFontAttributeName:[UIFont systemFontOfSize:20.0]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont systemFontOfSize:20.0]} forState:UIControlStateSelected];
    
    UIImage *image = [self imageWithColor:[UIColor grayColor]];
    [[UITabBar appearance] setSelectionIndicatorImage:image];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [iRate sharedInstance].applicationBundleID = @"com.cs.snapuloader";
    [iRate sharedInstance].appStoreID = 1048460977;
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    [iRate sharedInstance].usesUntilPrompt = 3;
    [iRate sharedInstance].daysUntilPrompt = 0.5;

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    BOOL autoLogin = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLogin"] boolValue];
    if (autoLogin)
    {
        uint last = [[[NSUserDefaults standardUserDefaults] objectForKey:@"loginSuccessTime"] intValue];
        uint utc = [[NSDate date] timeIntervalSince1970];
        //if (utc - last >= 3000 || ![[SKClient sharedClient] isSignedIn])
        {
            [self.loginViewController startLogin:NO block:NO];
        }
//        else if ([[SKClient sharedClient] isSignedIn])
//        {
//            [self.loginViewController restoreSession];
//        }
    }
}

- (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, self.window.bounds.size.width / 2.0, 49.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)showMainView
{
    if (self.loginViewController == nil)
    {
        self.loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        self.rootNavViewController = [[MyNavigationController alloc] initWithRootViewController:self.loginViewController];
    }
    
    BOOL autoLogin = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLogin"] boolValue];
    if (autoLogin)
    {
        [self.loginViewController enterToMainView:self.window];
    }
    else
    {
        self.window.rootViewController = self.rootNavViewController;
    }
}

@end
