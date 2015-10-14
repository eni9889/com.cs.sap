//
//  UIImage+Extension.h
//  SnapUploader
//
//  Created by tsinglink on 15/10/10.
//  Copyright © 2015年 tsinglink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)
- (UIImage*)imageByBestFitForSize:(CGSize)targetSize;
- (UIImage*)imageByScaleToFitForSize:(CGSize)targetSize;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;

- (UIImage *)avatarImageSize:(CGSize)size;
- (UIImage *)roundImage:(CGSize)targetSize cornerRadius:(NSInteger)radius;
- (UIImage *)image:(UIImage *)myIconImage tinColor:(UIColor *)tintColor;

- (UIImage*)imageByBestFitForSize1:(CGSize)targetSize;
+ (UIImage *)imageWithColor:(UIColor *)color;

- (UIImage *)addTextOnImage:(CGSize)targetSize text:(NSString *)text;
@end
