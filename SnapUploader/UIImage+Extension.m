//
//  UIImage+Extension.m
//  SnapUploader
//
//  Created by tsinglink on 15/10/10.
//  Copyright © 2015年 tsinglink. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)
- (UIImage*)imageByBestFitForSize:(CGSize)targetSize {
    
    CGFloat aspectRatio = (float) self.size.width / (float) self.size.height;
    
    CGFloat targetHeight = targetSize.height;
    CGFloat scaledWidth = targetSize.height * aspectRatio;
    if (scaledWidth > self.size.width && targetHeight > self.size.height)
    {
        CGFloat targetWidth = (targetSize.width < scaledWidth) ? targetSize.width : scaledWidth;
        return [self imageByScalingAndCroppingForSize:CGSizeMake(targetWidth, targetHeight)];
    }
    
    return [self imageByAspectToFill:targetSize];
}

- (UIImage*)imageByScaleToFitForSize:(CGSize)targetSize
{
    CGFloat scaleFactor = 0.0;
    CGFloat widthFactor = targetSize.width / self.size.width;
    CGFloat heightFactor = targetSize.height / self.size.height;
    if (widthFactor > heightFactor)
    {
        scaleFactor = heightFactor;
    }
    else
    {
        scaleFactor = widthFactor;
    }
    
    CGFloat scaledWidth  = ceil(self.size.width * scaleFactor);
    CGFloat scaledHeight = ceil(self.size.height * scaleFactor);
    CGRect rect = CGRectZero;
    rect.size.width = scaledWidth;
    rect.size.height = scaledHeight;
    
    if (NULL != UIGraphicsBeginImageContextWithOptions)
    {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2);
    }
    else
    {
        UIGraphicsBeginImageContext(rect.size);
    }
    
    [self drawInRect:rect];
    
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}

- (UIImage *)addTextOnImage:(CGSize)targetSize text:(NSString *)text
{
    CGFloat scaleFactor = 0.0;
    CGFloat widthFactor = targetSize.width / self.size.width;
    CGFloat heightFactor = targetSize.height / self.size.height;
    if (widthFactor > heightFactor)
    {
        scaleFactor = heightFactor;
    }
    else
    {
        scaleFactor = widthFactor;
    }
    
    CGFloat scaledWidth  = ceil(self.size.width * scaleFactor);
    CGFloat scaledHeight = ceil(self.size.height * scaleFactor);
    CGRect rect = CGRectZero;
    rect.size.width = scaledWidth;
    rect.size.height = scaledHeight;
    
    if (NULL != UIGraphicsBeginImageContextWithOptions)
    {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2);
    }
    else
    {
        UIGraphicsBeginImageContext(rect.size);
    }
    
    [self drawInRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [[[UIColor blackColor] colorWithAlphaComponent:0.65] CGColor]);
    CGContextBeginPath(ctx);
    CGContextAddRect(ctx, CGRectMake(0, (rect.size.height - 45.0) / 2, rect.size.width, 45.0));
    CGContextFillPath(ctx);
    
    UIFont *font = [UIFont systemFontOfSize:18];
    
    CGRect srcRc = CGRectMake(0, (rect.size.height - 45.0) / 2, rect.size.width, 45.0);
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName:[UIColor whiteColor]};
    CGRect textRect = [text boundingRectWithSize:srcRc.size options:NSStringDrawingUsesFontLeading attributes:attributes context:nil];
    CGRect result = textRect;
    result.origin.y = srcRc.origin.y + (srcRc.size.height - textRect.size.height) / 2;
    result.origin.x = 0;
    result.size.width = srcRc.size.width;
    [text drawInRect:result withAttributes:attributes];
    
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    //裁剪
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    if (NULL != UIGraphicsBeginImageContextWithOptions)
    {
        UIGraphicsBeginImageContextWithOptions(targetSize, NO, 2);
    }
    else
    {
        UIGraphicsBeginImageContext(targetSize);
    }
    
    CGRect thumbnailRect = [self scaleAndCropRectForSize:targetSize];
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil)
        NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)imageByAspectToFill:(CGSize)targetSize
{
    // 这里只考虑了IMAGE 比 targetSize大的情况
    CGFloat scaleFactor = 0.0;
    CGFloat widthFactor = targetSize.width / self.size.width;
    CGFloat heightFactor = targetSize.height / self.size.height;
    if (widthFactor > heightFactor)
    {
        scaleFactor = widthFactor; // scale to fit height
    }
    else
    {
        scaleFactor = heightFactor; // scale to fit width
    }
    
    CGFloat scaledWidth  = ceil(self.size.width * scaleFactor);
    CGFloat scaledHeight = ceil(self.size.height * scaleFactor);
    CGRect rect = CGRectZero;
    rect.size.width = scaledWidth;
    rect.size.height = scaledHeight;
    
    if (NULL != UIGraphicsBeginImageContextWithOptions)
    {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2);
    }
    else
    {
        UIGraphicsBeginImageContext(rect.size);
    }
    
    [self drawInRect:rect];
    
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}

- (CGRect)scaleAndCropRectForSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
        {
            scaleFactor = widthFactor; // scale to fit height
        }
        else
        {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = ceil(width * scaleFactor);
        scaledHeight = ceil(height * scaleFactor);
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
        {
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    }
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    return thumbnailRect;
}

- (UIImage *)avatarImageSize:(CGSize)size
{
    CGRect thumbnailRect = [self scaleAndCropRectForSize:size];
    CGRect rect;
    rect.origin = CGPointMake(0, 0);
    rect.size = size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    [path addClip];
    [self drawInRect:thumbnailRect];
    UIImage *roundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundImage;
}

- (UIImage *)roundImage:(CGSize)targetSize cornerRadius:(NSInteger)radius
{
    CGRect rect;
    rect.origin = CGPointMake(0, 0);
    rect.size = targetSize;
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
    [path addClip];
    CGRect thumbnailRect = [self scaleAndCropRectForSize:targetSize];
    [self drawInRect:thumbnailRect];
    UIImage *roundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundImage;
}

- (UIImage *)image:(UIImage *)myIconImage tinColor:(UIColor *)tintColor
{
    UIGraphicsBeginImageContextWithOptions(myIconImage.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, myIconImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, myIconImage.size.width, myIconImage.size.height);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, myIconImage.CGImage);
    
    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [tintColor setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
