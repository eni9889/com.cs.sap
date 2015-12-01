//
//  LoginPara.h
//  SnapUploader
//
//  Created by tsinglink on 15/12/1.
//  Copyright © 2015年 tsinglink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginPara : NSObject
@property (nonatomic, copy)NSString *googleEmail;
@property (nonatomic, copy)NSString *googlePwd;
@property (nonatomic, copy)NSString *snapUsername;
@property (nonatomic, copy)NSString *realName;
@property (nonatomic, copy)NSString *snapPwd;
@property (nonatomic, copy)NSString *snapchatAuthToken;
@property (nonatomic, copy)NSString *googleAuthToken;
@property (nonatomic, copy)NSString *googleAuthDate;
@end
