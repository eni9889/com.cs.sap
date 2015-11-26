//
//  UsersViewController.m
//  SnapUploader
//
//  Created by tsinglink on 15/10/6.
//  Copyright © 2015年 tsinglink. All rights reserved.
//

#import "UsersViewController.h"
#import "UserInfo.h"
#import "PureLayout.h"
#import "UIColor+HexColor.h"
#import "SVProgressHUD.h"
#import "SnapchatKit.h"
#import "AppDelegate.h"
#import "NSData+SnapchatKit.h"

@interface UsersViewController ()
{
    NSMutableArray *indexedArray;
    NSMutableArray *selectedArray;
    NSMutableArray *sectionIndexArray;
    BOOL hasSelectStory;
}
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSArray *filteredProducts;
@property (nonatomic, retain) UIView *toolView;
@property (nonatomic, strong)UIButton *sendButton;
@property (nonatomic, strong)UIImageView *arrowImageView;
@property (nonatomic, strong) NSLayoutConstraint *hideEdgeConstraint;
@end

@implementation UsersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.frame = CGRectMake(0, 0, 30, 30);
    [button2 setImage:[UIImage imageNamed:@"backArrow.png"] forState:UIControlStateNormal];
    [button2 setImage:[UIImage imageNamed:@"backArrow.png"] forState:UIControlStateSelected];
    [button2 addTarget:self
                action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:button2];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.aTableView.tableHeaderView = self.searchController.searchBar;
    self.aTableView.rowHeight = 55.0;
    
    // we want to be the delegate for our filtered table so didSelectRowAtIndexPath is called for both tables
    //self.resultsTableController.tableView.delegate = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO; // default is YES
    self.searchController.searchBar.delegate = self; // so we can monitor text changes + others
    
    self.toolView = [UIView newAutoLayoutView];
    [self.view addSubview:self.toolView];
    self.toolView.backgroundColor = [UIColor colorFromHex:0x8000ff];
    [self.toolView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.aTableView withOffset:0.0];
    [self.toolView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.toolView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.toolView autoSetDimension:ALDimensionHeight toSize:60.0];
    self.hideEdgeConstraint = [self.toolView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-60.0];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolView addSubview:self.sendButton];
    [self.sendButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0.0];
    [self.sendButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0.0];
    [self.sendButton autoSetDimension:ALDimensionWidth toSize:90.0];
    [self.sendButton autoSetDimension:ALDimensionHeight toSize:60.0];

    [self.sendButton setBackgroundImage:[UIImage imageNamed:@"send_button_pressed"] forState:UIControlStateHighlighted];
    [self.sendButton addTarget:self action:@selector(readyToSend:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton addTarget:self action:@selector(touchDownHandle:) forControlEvents:UIControlEventTouchDown];
    [self.sendButton addTarget:self action:@selector(touchOutHandle:) forControlEvents:UIControlEventTouchUpOutside];
    
    self.arrowImageView = [UIImageView newAutoLayoutView];
    [self.sendButton addSubview:self.arrowImageView];
    [self.arrowImageView autoCenterInSuperview];
    [self.arrowImageView autoSetDimension:ALDimensionWidth toSize:90.0];
    [self.arrowImageView autoSetDimension:ALDimensionHeight toSize:60.0];
    self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *image = [UIImage imageNamed:@"arrow0"];
    UIImage *image1 = [UIImage imageNamed:@"arrow1"];
    UIImage *image2 = [UIImage imageNamed:@"arrow2"];
    UIImage *image3 = [UIImage imageNamed:@"arrow3"];
    self.arrowImageView.animationImages = @[image, image1, image2, image3];
    self.arrowImageView.animationDuration = 2.0;
    [self.arrowImageView startAnimating];
    
    self.definesPresentationContext = YES;
    selectedArray = [[NSMutableArray alloc] init];
    indexedArray = [[NSMutableArray alloc] init];
    sectionIndexArray = [[NSMutableArray alloc] init];
    [sectionIndexArray addObject:UITableViewIndexSearch];
    [sectionIndexArray addObject:@"★"];
    [sectionIndexArray addObjectsFromArray:[[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];

    
    [self loadAlpa];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

- (void)updateViewConstraints
{
    self.hideEdgeConstraint.constant = ([selectedArray count] || hasSelectStory) > 0 ? 0.0 : (60.0);
    [super updateViewConstraints];
}

- (IBAction)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)loadAlpa
{
    UILocalizedIndexedCollation *theCollation = [UILocalizedIndexedCollation currentCollation];
    NSInteger highSection = [[theCollation sectionTitles] count];
    indexedArray = [NSMutableArray arrayWithCapacity:highSection];
    for (int i=0; i<=highSection; i++)
    {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [indexedArray addObject:array];
    }
    
    NSArray *users = [UserInfo reloadLocalCache];
    for (UserInfo *user in users)
    {
        NSInteger section = [theCollation sectionForObject:user
                                   collationStringSelector:@selector(displayName)];
        user.sectionIndex = section;
        NSMutableArray *sectionNames = indexedArray[section];
        [sectionNames addObject:user];
    }
    
    for (int index = 0; index < highSection; index++)
    {
         NSMutableArray *personArrayForSection = indexedArray[index];
         NSArray *sortedPersonArrayForSection = [theCollation sortedArrayFromArray:personArrayForSection collationStringSelector:@selector(displayName)];
         indexedArray[index] = sortedPersonArrayForSection;
    }
}

- (IBAction)readyToSend:(id)sender
{
    [self.arrowImageView startAnimating];
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (app.loginViewController.loginErrorCode == 1)
    {
        [SVProgressHUD showErrorWithStatus:@"Logining, please wait for a moment about 10 seconds, then try again."];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    if (app.loginViewController.loginErrorCode == -1)
    {
        [SVProgressHUD showErrorWithStatus:@"Sorry, we encountered some error, please exit and then sign in again"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    
    SKBlob *blob = [SKBlob blobWithContentsOfPath:self.filePath];
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (int i=0; i<[selectedArray count]; i++)
    {
        UserInfo *user = [selectedArray objectAtIndex:i];
        NSString *name = user.userName;
        if ([name length] == 0)
        {
            name = @"";
        }
        [names addObject:name];
    }
    if (self.text == nil)
    {
        self.text = @"";
    }

    if (self.seconds <= 0)
    {
        self.seconds = 1;
    }
    
    self.view.userInteractionEnabled = NO;
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([names count] > 0)
        {
            [[SKClient sharedClient] sendSnap:blob to:names text:self.text timer:self.seconds completion:^(id obj, NSError *error){
                
                self.view.userInteractionEnabled = YES;
                if (error != nil)
                {
                    NSLog(@"%@", error);
                    [SVProgressHUD showErrorWithStatus:@"Upload Faild, please try again later"];
                }
                else
                {
                    NSLog(@"Upload Success");
                    [SVProgressHUD showSuccessWithStatus:@"Upload Success"];
                }

                [self closeView];
            }];
        }
        
        if (hasSelectStory)
        {
            [[SKClient sharedClient] postStory:blob for2:24*3600 completion:^(NSError *error){
                self.view.userInteractionEnabled = YES;
                
                if (error != nil)
                {
                    NSLog(@"postStory %@", error);
                    [SVProgressHUD showErrorWithStatus:@"Upload Faild, please try again later"];
                }
                else
                {
                    NSLog(@"postStory Success");
                    [SVProgressHUD showSuccessWithStatus:@"Upload Success"];
                }
                [self closeView];
            }];
        }
    });
}

- (void)closeView
{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (app.window.rootViewController != app.loginViewController.myTabBarController)
    {
        app.window.rootViewController = app.loginViewController.myTabBarController;
    }
}

- (IBAction)touchDownHandle:(id)sender
{
    [self.arrowImageView stopAnimating];
}

- (IBAction)touchOutHandle:(id)sender
{
    [self.arrowImageView startAnimating];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
     NSString *searchText = searchController.searchBar.text;
    [self filterContentForSearchText:searchText];
}

-(void)filterContentForSearchText:(NSString*)searchText
{
    NSMutableArray *tempResults = [NSMutableArray array];
    NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    
    for (int i = 0; i < indexedArray.count; i++)
    {
        NSArray *array = [indexedArray objectAtIndex:i];
        for (int j=0; j<[array count]; j++)
        {
            UserInfo *user = [array objectAtIndex:j];
            NSString *storeString = user.displayName;
            NSRange storeRange = NSMakeRange(0, storeString.length);
            NSRange foundRange = [storeString rangeOfString:searchText options:searchOptions range:storeRange];
            if (foundRange.length)
            {
                [tempResults addObject:user];
            }
        }
    }
    
    self.filteredProducts = tempResults;
    [self.aTableView reloadData];
}

- (void)selectPerson:(UserInfo *)person
{
    if ([selectedArray containsObject:person])
    {
        [selectedArray removeObject:person];
    }
    else
    {
        [selectedArray addObject:person];
    }
    [self.aTableView reloadData];
    
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     ];
    
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
        tableViewHeaderFooterView.textLabel.font = [UIFont systemFontOfSize:16];
        tableViewHeaderFooterView.textLabel.textColor = [UIColor colorFromHex:0x39b4e6];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if ([self.searchController isActive])
    {
        return nil;
    }
    else
    {
        return sectionIndexArray;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if ([self.searchController isActive])
    {
        return 0;
    }
    else
    {
        if (title == UITableViewIndexSearch)
        {
            [tableView scrollRectToVisible:self.searchController.searchBar.frame animated:NO];
            return -1;
        }
        else if (index == 1)
        {
            return 0; // story
        }
        else
        {
            return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index-2];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   if ([self.searchController isActive])
    {
        return 1;
    }
    else
    {
        return [indexedArray count] + 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.searchController isActive])
    {
        return [self.filteredProducts count];
    }
    else
    {
        if (section == 0)
        {
            return 1;
        }
        else
        {
            return [[indexedArray objectAtIndex:(section - 1)] count];
        }
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.searchController isActive])
    {
        return nil;
    }
    else
    {
        if (section == 0)
        {
            return @"Stories";
        }
        else
        {
            NSInteger count = [[indexedArray objectAtIndex:(section - 1)] count];
            return count > 0 ? [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:(section - 1)] : nil;
        }
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self.searchController isActive])
    {
        return 0;
    }
    else
    {
        if (section == 0)
        {
            return 30;
        }
        else
        {
            return [[indexedArray objectAtIndex:(section - 1)] count] ? 30 : 0;
        }
    }

    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];

        UIImageView *imageView = [UIImageView newAutoLayoutView];
        [cell.contentView addSubview:imageView];
        imageView.image = [UIImage imageNamed:@"SendCheckbox.png"];
        [imageView autoSetDimension:ALDimensionWidth toSize:30.0];
        [imageView autoSetDimension:ALDimensionHeight toSize:30.0];
        [imageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:cell.contentView];
        [imageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:15.0];;
        imageView.tag = 1001;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:1001];
    imageView.image = [UIImage imageNamed:@"SendCheckbox.png"];
    NSInteger section = [indexPath section];
    
    if ([self.searchController isActive])
    {
        UserInfo *person = [self.filteredProducts objectAtIndex:[indexPath row]];
        if ([selectedArray containsObject:person])
        {
            imageView.image = [UIImage imageNamed:@"SendCheckboxSelected.png"];
        }
        cell.textLabel.text = person.displayName;
    }
    else
    {
        if (section == 0)
        {
            cell.textLabel.text = @"My Story";
            if (hasSelectStory)
            {
                imageView.image = [UIImage imageNamed:@"SendCheckboxSelected.png"];
            }
        }
        else
        {
            NSArray *setitl = [indexedArray objectAtIndex:(section - 1)];
            if ([setitl count] > [indexPath row])
            {
                UserInfo *person = [setitl objectAtIndex:[indexPath row]];
                if ([selectedArray containsObject:person])
                {
                    imageView.image = [UIImage imageNamed:@"SendCheckboxSelected.png"];
                }
                cell.textLabel.text = person.displayName;
            }
            
        }

    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = [indexPath section];
    UserInfo *person;
    if ([self.searchController isActive])
    {
        person = [self.filteredProducts objectAtIndex:[indexPath row]];
    }
    else
    {
        if (section == 0)
        {
            hasSelectStory = !hasSelectStory;
            [self.aTableView reloadData];
            [self.view setNeedsUpdateConstraints];
            [self.view updateConstraintsIfNeeded];
            
            [UIView animateWithDuration:0.2
                             animations:^{
                                 [self.view layoutIfNeeded];
                             }
             ];
        }
        else
        {
            NSArray *setitl = [indexedArray objectAtIndex:(section - 1)];
            if ([setitl count] > [indexPath row])
            {
                person = [setitl objectAtIndex:[indexPath row]];
            }
            
            if (person != nil)
            {
                [self selectPerson:person];
            }
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)dealloc
{
    
}
@end
