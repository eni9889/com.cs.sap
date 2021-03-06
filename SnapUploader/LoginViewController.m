//
//  LoginViewController.m
//  
//
//  Created by tsinglink on 15/9/16.
//
//

#import "LoginViewController.h"
#import "UIColor+HexColor.h"
#import "PureLayout.h"
#import "CTAssetsGridViewController.h"
#import "CTAssetsPickerController.h"
#import "CTAssetsPageViewController.h"
#import "CTAssetItemViewController.h"
#import "PHAsset+CTAssetsPickerController.h"
#import "MyNavigationController.h"
#import "EditVideoController.h"

#import "SKClient.h"
#import <CommonCrypto/CommonDigest.h>
#import "SVProgressHUD.h"

#import "UserInfo.h"
#import "AppDelegate.h"

#import "MoreViewController.h"

#define kExpireDate 55 * 60
@interface LoginViewController () <CTAssetsPickerControllerDelegate>
{
    UITextField *userTextField;
    UITextField *pwdTextField;
}
@property (nonatomic, strong) PHImageManager *exportManager;
@property (nonatomic, copy)NSString *googleEmail;
@property (nonatomic, copy)NSString *googlePwd;
@property (nonatomic, copy)NSString *snapUsername;
@property (nonatomic, copy)NSString *realName;
@property (nonatomic, copy)NSString *snapPwd;
@property (nonatomic, copy)NSString *snapchatAuthToken;
@property (nonatomic, copy)NSString *googleAuthToken;
@property (nonatomic, copy)NSString *googleAuthDate;
@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        self.loginErrorCode = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorFromHex:0xfff20a];
    self.mTableView.backgroundColor = self.view.backgroundColor;
    self.mTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.title = @"Snap Uploader";
    self.loginErrorCode = -1;
    [self loadParam];
}

- (void)loadParam
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"loginPara.plist"];
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (mutableDic != nil)
    {
        self.googleEmail = [mutableDic objectForKey:@"googleEmail"];
        self.googlePwd = [mutableDic objectForKey:@"googlePwd"];
        self.snapUsername = [mutableDic objectForKey:@"snapUsername"];
        self.snapPwd = [mutableDic objectForKey:@"snapPwd"];
        self.snapchatAuthToken = [mutableDic objectForKey:@"snapchatAuthToken"];
        self.googleAuthDate = [mutableDic objectForKey:@"googleAuthTokenDate"];
        NSInteger utc = [self.googleAuthDate integerValue];
        NSInteger nowUtc = [[NSDate date] timeIntervalSince1970];
        if (nowUtc - utc < kExpireDate)
        {
            self.googleAuthToken = [mutableDic objectForKey:@"googleAuthToken"];
        }
        else
        {
            self.googleAuthToken = nil;
        }
        
        self.realName = [mutableDic objectForKey:@"realAccountName"];
    }
    
    NSString *sessionPath = [documentsDirectory stringByAppendingPathComponent:@"session.plist"];
    SKSession *session = [NSKeyedUnarchiver unarchiveObjectWithFile:sessionPath];
    if (session != nil)
    {
        [SKClient sharedClient].currentSession = session;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [userTextField resignFirstResponder];
    [pwdTextField resignFirstResponder];
}

- (void)fillParaAndLogin
{
    self.snapUsername = userTextField.text;
    self.snapPwd = pwdTextField.text;
    [self startLogin:YES];
}

- (void)startLogin:(BOOL)enterToMain
{
    [userTextField resignFirstResponder];
    [pwdTextField resignFirstResponder];
    [self loadParam];
    BOOL sucess = [self checkParame];
    if (sucess)
    {
        [self loginSKClient:enterToMain refresh:NO];
    }
}

- (void)loginSKClient:(BOOL)enterToMain refresh:(BOOL)doRefresh
{
    if (self.loginErrorCode == 1)
    {
        return;
    }
    
    self.loginErrorCode = 1;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    //https://clients.casper.io/login.php?in=true&next=%2Fdocs-casper-api-auth.php
    // wangqiong0915@gmail.com  wangqiong0915
    [SKClient sharedClient].casperAPIKey = @"4fdd65f73c82260e1c2a84ee97966c27";
    [SKClient sharedClient].casperAPISecret = @"644f39e42f3d9438fcfef5e83062fe06";
    
    if ([self.snapchatAuthToken length] != 0 && [self.realName length] != 0 && !doRefresh)
    {
        if ([self.googleAuthToken length] != 0 && [SKClient sharedClient].currentSession != nil)
        {
            if (enterToMain)
            {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                [SVProgressHUD showWithStatus:@"Logging in to server..."];
            }
            else
            {
                [SVProgressHUD showWithStatus:@"Updating..."];
            }
            
            [SKClient clientWithUsername:self.realName authToken:self.snapchatAuthToken gauth:self.googleAuthToken];
            [[SKClient sharedClient] restoreSessionWithUsername:[SKClient sharedClient].username
                                              snapchatAuthToken:[SKClient sharedClient].authToken
                                                googleAuthToken:[SKClient sharedClient].googleAuthToken
                                                   doGetUpdates:^(NSError *error){
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    
                    if (enterToMain)
                    {
                        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    }
                    [SVProgressHUD dismiss];
                    if (error == nil)
                    {
                        [UserInfo refreshFromRemote];
                        [self saveParam];
                        self.loginErrorCode = 0;
                        NSLog(@"restoresession success");
                        
                        if (enterToMain)
                        {
                            [self enterToMainView:self.view.window];
                        }
                    }
                    else
                    {
                        self.loginErrorCode = -1;
                        NSLog(@"restoresession error %@", error);
                        [self loginSKClient:enterToMain refresh:YES];
                    }
                });
                
            }];
        }
        else
        {
            if (enterToMain)
            {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                [SVProgressHUD showWithStatus:@"Logging in to server..."];
            }
            else
            {
                [SVProgressHUD showWithStatus:@"Updating..."];
            }
            NSLog(@"start getAuthTokenForGmail");
            [[SKClient sharedClient] signInWithUsername:self.realName authToken:self.snapchatAuthToken gmail:self.googleEmail gpass:self.googlePwd completion:^(NSDictionary *dic, NSError *error){
                
                NSLog(@"request gauth and updatesession = %@", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (enterToMain)
                    {
                        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    }
                    [SVProgressHUD dismiss];
                    
                    if (error == nil)
                    {
                        [UserInfo refreshFromRemote];
                        [self saveParam];
                        self.loginErrorCode = 0;
                        
                        if (enterToMain)
                        {
                            [self enterToMainView:self.view.window];
                        }
                    }
                    else
                    {
                        self.loginErrorCode = -1;
                        [self loginSKClient:enterToMain refresh:YES];
                    }
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                });
            }];
        }
    }
    else
    {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD showWithStatus:@"Logging in to server..."];
         [[SKClient sharedClient] signInWithUsername:self.snapUsername password:self.snapPwd gmail:self.googleEmail gpass:self.googlePwd
                                     completion:^(NSDictionary *json, NSError *error) {
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             
                                             NSLog(@"signInWithUsername %@", error);
                                             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                             [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                                             if (error == nil)
                                             {
                                                 [SVProgressHUD dismiss];
                                                 
                                                 self.loginErrorCode = 0;
                                                 [UserInfo refreshFromRemote];
                                                 
                                                 if (enterToMain)
                                                 {
                                                     [self enterToMainView:self.view.window];
                                                 }
                                                 
                                                 [self saveParam];
                                             }
                                             else
                                             {
                                                 self.loginErrorCode = -1;
                                                 [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                                             }
                                         });
                                     }];
    }
}

- (void)saveParam
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"loginPara.plist"];
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
    [mutableDic setObject:self.googleEmail forKey:@"googleEmail"];
    [mutableDic setObject:self.googlePwd forKey:@"googlePwd"];
    [mutableDic setObject:self.snapUsername forKey:@"snapUsername"];
    [mutableDic setObject:self.snapPwd forKey:@"snapPwd"];
    if ([[SKClient sharedClient].username length] > 0)
    {
        [mutableDic setObject:[SKClient sharedClient].username forKey:@"realAccountName"];
    }
    else
    {
        [mutableDic setObject:@"" forKey:@"realAccountName"];
    }
    
    if ([[SKClient sharedClient].googleAuthToken length] > 0)
    {
        [mutableDic setObject:[SKClient sharedClient].googleAuthToken forKey:@"googleAuthToken"];
    }
    else
    {
        [mutableDic setObject:@"" forKey:@"googleAuthToken"];
    }
    NSInteger utc = [[NSDate date] timeIntervalSince1970];
    [mutableDic setObject:[NSNumber numberWithInteger:utc] forKey:@"googleAuthTokenDate"];
    
    if ([[SKClient sharedClient].authToken length] > 0)
    {
        [mutableDic setObject:[SKClient sharedClient].authToken forKey:@"snapchatAuthToken"];
    }
    else
    {
        [mutableDic setObject:@"" forKey:@"snapchatAuthToken"];
    }
    
    [mutableDic writeToFile:path atomically:YES];
    
    NSString *sessionPath = [documentsDirectory stringByAppendingPathComponent:@"session.plist"];
    SKSession *session = [SKClient sharedClient].currentSession;
    if (session != nil)
    {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:session];
        [data writeToFile:sessionPath atomically:YES];
    }
}

- (BOOL)checkParame
{
    if ([self.snapUsername length] == 0)
    {
        return NO;
    }
    
    if ([self.snapPwd length] == 0)
    {
        self.snapPwd = @"";
    }
    
    if (self.googleEmail == nil)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Input gmail account" message:@"Gmail is required to login into Snapchat" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        [alertView show];
        return NO;
    }
    
    if ([self.googlePwd length] == 0)
    {
        self.googlePwd = @"";
    }
    
    return YES;
}

- (void)enterToMainView:(UIWindow *)awindow
{
    [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"AutoLogin"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    awindow.rootViewController = [UIViewController new];
 
    CTAssetsPickerController *picker1 = [[CTAssetsPickerController alloc] init];
    picker1.delegate = self;
    CTAssetsPickerController *picker2 = [[CTAssetsPickerController alloc] init];
    picker2.delegate = self;

    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    picker1.assetCollectionFetchOptions = fetchOptions;
    
    fetchOptions = [PHFetchOptions new];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
    picker2.assetCollectionFetchOptions = fetchOptions;

    
    CTAssetsGridViewController *photoViewController = [[CTAssetsGridViewController alloc] init];
        photoViewController.title = @"Photo";
        photoViewController.picker = picker1;

    MyNavigationController *nav = [[MyNavigationController alloc] initWithRootViewController:photoViewController];
    
    CTAssetsGridViewController *videoViewController = [[CTAssetsGridViewController alloc] init];
    videoViewController.title = @"Video";
    videoViewController.picker = picker2;
    MyNavigationController *nav2 = [[MyNavigationController alloc] initWithRootViewController:videoViewController];
    
    self.myTabBarController = [[UITabBarController alloc] init];
    self.myTabBarController.viewControllers = @[nav, nav2];
    awindow.rootViewController = self.myTabBarController;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    if (buttonIndex == 1)
    {
        UITextField *textFiled = [alertView textFieldAtIndex:0];
        self.googleEmail = textFiled.text;
        textFiled = [alertView textFieldAtIndex:1];
        self.googlePwd = textFiled.text;
        
        if ([self.googleEmail length] == 0)
        {
            return;
        }
        
        if ([self.googlePwd length] == 0)
        {
            self.googlePwd = @"";
        }

        [self loginSKClient:YES refresh:YES];
    }
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

- (void)didSelectAtIndexPath:(NSIndexPath *)indexPath asserts:(PHFetchResult *)assert
{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    PHAsset *passet = [assert objectAtIndex:indexPath.item];
    if ([passet ctassetsPickerIsVideo])
    {
        EditVideoController *itemView = [EditVideoController assetItemViewControllerForAsset:passet];
        MyNavigationController *nav = [[MyNavigationController alloc] initWithRootViewController:itemView];
//        app.window.rootViewController = nav;
    }
    else
    {
        
        CTAssetItemViewController *itemView = [CTAssetItemViewController assetItemViewControllerForAsset:passet];
        MyNavigationController *nav = [[MyNavigationController alloc] initWithRootViewController:itemView];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    if (row == 0 || row == 1)
    {
        cell.backgroundColor = [UIColor whiteColor];
    }
    else
    {
#if kCCSUploader
        cell.backgroundColor = [UIColor colorFromHex:0x8000ff];
        #else
        cell.backgroundColor = [UIColor colorFromHex:0x2e926b];
#endif
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 50.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44.0)];
    UILabel *label = [UILabel newAutoLayoutView];
    [view addSubview:label];
    [label autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:5.0];
    [label autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:5.0];
    [label autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:8.0];
    
    label.text = @"Your login credentials will be enctrypted and stored securely and is only used to login into snapchat.";
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:15.0];
    label.numberOfLines = 0;
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    NSString *identifier = @"CameraCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        if (row == 0)
        {
            UIView *lineView = [UIView newAutoLayoutView];
            [cell.contentView addSubview:lineView];
            [lineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
            [lineView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
            [lineView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
            [lineView autoSetDimension:ALDimensionHeight toSize:2.0];
            lineView.backgroundColor = self.view.backgroundColor;
        }
        
        if (row == 0 || row == 1)
        {
            UITextField *textField = [UITextField newAutoLayoutView];
            [cell.contentView addSubview:textField];
            [textField autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20.0];
            [textField autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20.0];
            [textField autoAlignAxis:ALAxisHorizontal toSameAxisOfView:cell.contentView];
            textField.font = [UIFont boldSystemFontOfSize:17.0];
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            if (row == 0)
            {
                userTextField = textField;
                [userTextField becomeFirstResponder];
            }
            else
            {
                pwdTextField = textField;
                textField.secureTextEntry = YES;
            }
        }
        else
        {
            UILabel *label = [UILabel newAutoLayoutView];
            [cell.contentView addSubview:label];
            [label autoPinEdgeToSuperviewEdge:ALEdgeTop];
            [label autoPinEdgeToSuperviewEdge:ALEdgeBottom];
            [label autoPinEdgeToSuperviewEdge:ALEdgeLeading];
            [label autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont boldSystemFontOfSize:20.0];
            label.text = @"Login";
            label.textAlignment = NSTextAlignmentCenter;
        }
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (row == 0)
    {
        userTextField.placeholder = @"Snapchat Username";
        userTextField.text = self.snapUsername;
    }
    else if (row == 1)
    {
        pwdTextField.placeholder = @"Snapchat Password";
        pwdTextField.text = self.snapPwd;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if ([indexPath row] == 2)
    {
        [self fillParaAndLogin];
    }
}

- (void)dealloc
{
    
}
@end
