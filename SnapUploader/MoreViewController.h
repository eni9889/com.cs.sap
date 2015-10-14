//
//  MoreViewController.h
//  iMyCamera
//
//  Created by MacBook on 14-2-10.
//  Copyright (c) 2014年 MacBook. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoreViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
    IBOutlet UITableView *aTableView;
}
@end
