//
//  UserInfoWrapper.h
//  SnapUploader
//
//  Created by chenshun on 15/10/7.
//  Copyright (c) 2015年 tsinglink. All rights reserved.
//

#import "SKClient.h"

@interface UserInfo : NSObject
@property (nonatomic, assign)NSInteger sectionIndex;
@property (nonatomic, copy)NSString *userName;
@property (nonatomic, copy)NSString *identifier;
@property (nonatomic, copy)NSString *displayName;

+ (NSArray *)reloadLocalCache;
+ (void)refreshFromRemote;
@end
