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

#import "XGPush.h"
#import "XGSetting.h"

@interface AppDelegate ()
{
    
}
@property (nonatomic, copy)NSString *appURL;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [self showMainView];
    
//    [XGPush startApp:2200153612 appKey:@"I77MS112DAVZ"];
//    void (^successCallback)(void) = ^(void){
//        //如果变成需要注册状态
//        if(![XGPush isUnRegisterStatus])
//        {
//            //iOS8注册push方法
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
//            
//            float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
//            if(sysVer < 8){
//                [self registerPush];
//            }
//            else{
//                [self registerPushForIOS8];
//            }
//#else
//            //iOS8之前注册push方法
//            //注册Push服务，注册后才能收到推送
//            [self registerPush];
//#endif
//        }
//    };
//    [XGPush initForReregister:successCallback];
//    
//    //推送反馈回调版本示例
//    void (^successBlock)(void) = ^(void){
//        //成功之后的处理
//        NSLog(@"[XGPush]handleLaunching's successBlock");
//    };
//    
//    void (^errorBlock)(void) = ^(void){
//        //失败之后的处理
//        NSLog(@"[XGPush]handleLaunching's errorBlock");
//    };
//    
//    //角标清0
//    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
//    [XGPush handleLaunching:launchOptions successCallback:successBlock errorCallback:errorBlock];
//
//    if (launchOptions) {
//        NSDictionary* pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//        if (pushNotificationKey)
//        {
//            //这里定义自己的处理方式
//        }
//    }
    
    [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:@"16015d85dcc843eaa46f6db3a3675754" clientSecret:@"512c4633-c473-4318-9bfa-4c7d134bf88d" enableSignUp:NO];
#if kCCSUploader
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorFromHex:0x2e926b]];
#else
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorFromHex:0x2989dd]];

#endif
    
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    [[UITabBarItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, -10.0)];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor redColor], NSFontAttributeName:[UIFont systemFontOfSize:20.0]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont systemFontOfSize:20.0]} forState:UIControlStateSelected];
    
    UIImage *image = [self imageWithColor:[UIColor grayColor]];
    [[UITabBar appearance] setSelectionIndicatorImage:image];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
#if kCCSUploader
    [iRate sharedInstance].applicationBundleID = @"com.cs.snapuloader";
    [iRate sharedInstance].appStoreID = 1048460977;
#else
    [iRate sharedInstance].applicationBundleID = @"com.wq.snapupload";
    [iRate sharedInstance].appStoreID = 1050477919;
#endif
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    [iRate sharedInstance].usesUntilPrompt = 2;
    [iRate sharedInstance].daysUntilPrompt = 0.5;

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    BOOL autoLogin = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLogin"] boolValue];
    if (autoLogin)
    {
        [self.loginViewController startLogin:NO block:NO];
    }
}

+ (AppDelegate *)app
{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
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


//-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
//    //notification是发送推送时传入的字典信息
//    [XGPush localNotificationAtFrontEnd:notification userInfoKey:@"clockID" userInfoValue:@"myid"];
//    [XGPush delLocalNotification:notification];
//}
//
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_
//
////注册UserNotification成功的回调
//- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
//{
//    
//}
//
////按钮点击事件回调
//- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler{
//    if([identifier isEqualToString:@"ACCEPT_IDENTIFIER"]){
//        NSLog(@"ACCEPT_IDENTIFIER is clicked");
//    }
//    
//    completionHandler();
//}
//
//#endif
//
//- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
//
//    void (^successBlock)(void) = ^(void){
//        //成功之后的处理
//        NSLog(@"[XGPush Demo]register successBlock");
//    };
//    
//    void (^errorBlock)(void) = ^(void){
//        //失败之后的处理
//        NSLog(@"[XGPush Demo]register errorBlock");
//    };
//    
//    NSString * deviceTokenStr = [XGPush registerDevice:deviceToken successCallback:successBlock errorCallback:errorBlock];
//    
//    //如果不需要回调
//    //[XGPush registerDevice:deviceToken];
//    
//    //打印获取的deviceToken的字符串
//    NSLog(@"[XGPush Demo] deviceTokenStr is %@",deviceTokenStr);
//}
//
////如果deviceToken获取不到会进入此事件
//- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
//    
//    NSString *str = [NSString stringWithFormat: @"Error: %@",err];
//    
//    NSLog(@"[XGPush Demo]%@",str);
//}
//
//- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
//{
//    //推送反馈(app运行时)
//    [XGPush handleReceiveNotification:userInfo];
//    NSString *content = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
//    NSString *title = [userInfo objectForKey:@"title"];
//    self.appURL = [userInfo objectForKey:@"appURL"];
//    if (self.appURL != nil)
//    {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:content delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"Yes", nil];
//        [alertView show];
//    }
//}
//
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (self.appURL != nil)
//    {
//        if (buttonIndex == 1)
//        {
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.appURL]];
//        }
//        
//        self.appURL = nil;
//    }
//}
//
//- (void)registerPushForIOS8{
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
//    
//    //Types
//    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
//    
//    //Actions
//    UIMutableUserNotificationAction *acceptAction = [[UIMutableUserNotificationAction alloc] init];
//    
//    acceptAction.identifier = @"ACCEPT_IDENTIFIER";
//    acceptAction.title = @"Accept";
//    
//    acceptAction.activationMode = UIUserNotificationActivationModeForeground;
//    acceptAction.destructive = NO;
//    acceptAction.authenticationRequired = NO;
//    
//    UIMutableUserNotificationCategory *inviteCategory = [[UIMutableUserNotificationCategory alloc] init];
//    
//    inviteCategory.identifier = @"INVITE_CATEGORY";
//    
//    [inviteCategory setActions:@[acceptAction] forContext:UIUserNotificationActionContextDefault];
//    
//    [inviteCategory setActions:@[acceptAction] forContext:UIUserNotificationActionContextMinimal];
//    
//    
//    NSSet *categories = [NSSet setWithObjects:inviteCategory, nil];
//
//    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
//    
//    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
//    
//    
//    [[UIApplication sharedApplication] registerForRemoteNotifications];
//#endif
//}
//
//- (void)registerPush{
//    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
//}
//
@end
