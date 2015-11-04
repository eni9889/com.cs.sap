//
//  MoreViewController.m
//  iMyCamera
//
//  Created by MacBook on 14-2-10.
//  Copyright (c) 2014年 MacBook. All rights reserved.
//

#import "MoreViewController.h"
#import "UIColor+HexColor.h"
#import "PureLayout.h"
#import "TTSocial.h"
#import "AppDelegate.h"
#import "SKClient.h"
#define kRateAppUrl     @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@&pageNumber=0&sortOrdering=2&mt=8"
#define kRateiOS7AppStoreURLFormat @"itms-apps://itunes.apple.com/app/id%@"

@interface MoreViewController ()
{
    TTSocial *socila;
}
@end

@implementation MoreViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.navigationItem.title = @"Settings";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorFromHex:0xe5eaec];
    aTableView.backgroundColor = [UIColor clearColor];
    aTableView.backgroundView = nil;
    aTableView.rowHeight = 45.0;
    socila = [[TTSocial alloc] init];
    socila.viewController = self;
}

- (IBAction)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)loginOut:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Are you sure to log out?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"Yes", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"AutoLogin"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [app showMainView];
        if ([[SKClient sharedClient] isSignedIn])
        {
            [[SKClient sharedClient] signOut:^(NSError *error){}];
        }
    }
}

- (void)sendFeeback
{
    [socila sendFeedback:NSLocalizedString(@"Snap upload", nil) body:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 1)
    {
        return 55.0;
    }
    
    return 45.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    if (section == 1)
    {
        if (row == 0)
        {
            cell.backgroundColor = [UIColor colorFromHex:0x8000ff];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 2;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    NSString *identifier = @"CameraList";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];

        UILabel *detailLabel = [UILabel newAutoLayoutView];
        [cell.contentView addSubview:detailLabel];
        [detailLabel autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsMake(0, 0, 0, 8) excludingEdge:ALEdgeLeading];
        detailLabel.tag = 1000;
        detailLabel.textColor = [UIColor grayColor];
        detailLabel.font = [UIFont systemFontOfSize:16];
        if (section == 1)
        {
            UILabel *label = [UILabel newAutoLayoutView];
            [cell.contentView addSubview:label];
            [label autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero];
            label.text = @"Log out";
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            label.tag = 1001;
            label.font = [UIFont boldSystemFontOfSize:20.0];
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSInteger row = [indexPath row];
    
    UILabel *detalLabel = (UILabel *)[cell.contentView viewWithTag:1000];
    detalLabel.text = nil;
    UILabel *lgoutLabel = (UILabel *)[cell.contentView viewWithTag:1001];
    lgoutLabel.text = nil;
    
    NSString *text;
    if (section == 0)
    {
        if (row == 0)
        {
            text = @"Rate us";
        }
        else
        {
            text = @"Send Feedback";
        }
        cell.textLabel.text = text;
    }
    else
    {
        lgoutLabel.text = NSLocalizedString(@"log out", nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];

    if (section == 0)
    {
        if (row == 0)
        {
            NSString *rateUrl;
            float iOSVersion = [[UIDevice currentDevice].systemVersion floatValue];
            if (iOSVersion >= 7.0f && iOSVersion < 7.1f)
            {
                rateUrl = [NSString stringWithFormat:kRateiOS7AppStoreURLFormat, @"1050477919"];
            }
            else
            {
                rateUrl = [NSString stringWithFormat:kRateAppUrl, @"1050477919"];
            }
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:rateUrl]];
        }
        else
        {
            [self sendFeeback];
        }
    }
    else
    {
        [self loginOut:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
