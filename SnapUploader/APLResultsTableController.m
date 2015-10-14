/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The table view controller responsible for displaying the filtered products as the user types in the search field.
 */

#import "APLResultsTableController.h"

@implementation APLResultsTableController

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return self.filteredProducts.count;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
//    
//    APLProduct *product = self.filteredProducts[indexPath.row];
//    [self configureCell:cell forProduct:product];
//    
//    return cell;
//}
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    
//    // we use a nib which contains the cell's view and this class as the files owner
//    [self.tableView registerNib:[UINib nibWithNibName:kTableCellNibName bundle:nil] forCellReuseIdentifier:kCellIdentifier];
//}
//
//- (void)configureCell:(UITableViewCell *)cell forProduct:(APLProduct *)product {
//    cell.textLabel.text = product.title;
//    
//    // build the price and year string
//    // use NSNumberFormatter to get the currency format out of this NSNumber (product.introPrice)
//    //
//    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
//    numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
//    NSString *priceString = [numberFormatter stringFromNumber:product.introPrice];
//    
//    NSString *detailedStr = [NSString stringWithFormat:@"%@ | %@", priceString, (product.yearIntroduced).stringValue];
//    cell.detailTextLabel.text = detailedStr;
//}

@end