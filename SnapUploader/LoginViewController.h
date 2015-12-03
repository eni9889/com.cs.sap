//
//  LoginViewController.h
//  
//
//  Created by tsinglink on 15/9/16.
//
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (nonatomic, strong)IBOutlet UITableView *mTableView;
@property (nonatomic, strong)UITabBarController *myTabBarController;
@property (nonatomic) int loginErrorCode;
- (void)enterToMainView:(UIWindow *)window;
- (void)startLogin:(BOOL)enterToMain;
@end
