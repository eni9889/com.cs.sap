//
//  UsersViewController.h
//  SnapUploader
//
//  Created by tsinglink on 15/10/6.
//  Copyright © 2015年 tsinglink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UsersViewController : UIViewController<UITableViewDataSource, UITableViewDelegate,
UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>
@property (nonatomic, strong) IBOutlet UITableView *aTableView;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSTimeInterval seconds;

@property (nonatomic, strong)NSData *mediaData;
@end
