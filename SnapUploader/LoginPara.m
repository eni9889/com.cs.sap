//
//  LoginPara.m
//  SnapUploader
//
//  Created by tsinglink on 15/12/1.
//  Copyright © 2015年 tsinglink. All rights reserved.
//

#import "LoginPara.h"
#import "SKClient.h"

#define kExpireDate 55 * 60

@implementation LoginPara

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
@end
