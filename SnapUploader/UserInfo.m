//
//  UserInfoWrapper.m
//  SnapUploader
//
//  Created by chenshun on 15/10/7.
//  Copyright (c) 2015年 tsinglink. All rights reserved.
//

#define kUserName @"kUserName"
#define kIdentifier @"kIdentifier"
#define kDisplayName @"kDisplayName"

#import "UserInfo.h"
#import "SKUser.h"

@implementation UserInfo

- (id)initWithDictionary:(NSDictionary *)dic
{
    if (self = [super init])
    {
        self.userName = [dic objectForKey:kUserName];
        self.identifier = [dic objectForKey:kIdentifier];
        self.displayName = [dic objectForKey:kDisplayName];
    }
    
    return self;
}

+ (NSArray *)reloadLocalCache
{
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"CacheFriends.plist"];
    NSArray *array = [NSArray arrayWithContentsOfFile:path];
    if (array != nil)
    {
        for(int i=0; i<[array count]; i++)
        {
            NSDictionary *dic = [array objectAtIndex:i];
            UserInfo *info = [[UserInfo alloc] initWithDictionary:dic];
            [friends addObject:info];
        }
    }
    
    return friends;
}

+ (void)refreshFromRemote
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"CacheFriends.plist"];
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    NSMutableOrderedSet *friensSt = [SKClient sharedClient].currentSession.friends;
    for (SKUser *user in friensSt)
    {
        NSString *userID = user.username;
        NSString *usreIdenti = user.userIdentifier;
        NSString *display = user.displayName;
        if ([userID length] == 0)
        {
            userID = @"";
        }
        if ([usreIdenti length] == 0)
        {
            usreIdenti = @"";
        }
        if ([display length] == 0)
        {
            display = @"";
        }
        NSDictionary *dic = [NSDictionary dictionaryWithObjects:@[userID, usreIdenti, display] forKeys:@[kUserName, kIdentifier, kDisplayName]];
        [friends addObject:dic];
    }
    
    if ([friends count] > 0)
    {
        [friends writeToFile:path atomically:YES];
    }
}
@end
