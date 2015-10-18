//
//  Social.m
//  iDiary
//
//  Created by chenshun on 13-3-18.
//  Copyright (c) 2013年 ChenShun. All rights reserved.
//

#import "TTSocial.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIColor+HexColor.h"

@implementation TTSocial
@synthesize viewController;

- (void)showWarning:(NSString *)text
{
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:text delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
    [alertView show];
}

- (void)sendEmail:(NSString *)title body:(NSString *)body recipient:(NSString *)address
{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if (mailClass != nil)
	{
		// We must always check whether the current device is configured for sending emails
		if ([mailClass canSendMail])
		{
            MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            {
                picker.navigationBar.tintColor = [UIColor whiteColor];
            }
            picker.mailComposeDelegate = self;
            
            if ([title length] > 0)
            {
               [picker setSubject:title]; 
            }
            
            if ([address length] > 0)
            {
                NSArray *toRecipients = [NSArray arrayWithObject:address];
                [picker setToRecipients:toRecipients];
            }

            
            if ([body length] > 0)
            {
               [picker setMessageBody:body isHTML:NO]; 
            }
            
            [viewController presentModalViewController:picker animated:YES];
		}
		else
        {
			[self showWarning:NSLocalizedString(@"No mail account", nil)];
		}
	}
	else
    {
		[self showWarning: @"Device not configured to send mail."];
	}
}

- (void)sendFeedback:(NSString *)title body:(NSString *)body
{
    [self sendEmail:title body:body recipient:@"wangqiong_01@126.com"];
}

#pragma mark -
#pragma mark Workaround
// Displays an email composition interface inside the application. Populates all the Mail fields.
-(void)displayMailComposerSheet:(NSString *)text  to:(NSArray *)toRecipients cc:(NSArray *)ccRecipients bcc:(NSArray *)bccRecipients images:(NSArray *)images
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        picker.navigationBar.tintColor = [UIColor whiteColor];
    }
	picker.mailComposeDelegate = self;
	
    if ([toRecipients count] > 0)
    {
        [picker setToRecipients:toRecipients];
    }
	
    if ([ccRecipients count] > 0)
    {
        [picker setCcRecipients:ccRecipients];
    }
	
    if ([bccRecipients count] > 0)
    {
        [picker setBccRecipients:bccRecipients];
    }
	
    //
    //	// Attach an image to the email
    for (int i=0; i<[images count]; i++)
    {
        UIImage *img = [images objectAtIndex:i];
        NSData *myData = UIImagePNGRepresentation(img);
        NSString *imageName = [NSString stringWithFormat:@"%d", [[NSDate date] timeIntervalSince1970]];
        [picker addAttachmentData:myData mimeType:@"image/png" fileName:imageName];
    }

	// Fill out the email body text
    if (text != nil)
    {
        [picker setMessageBody:text isHTML:NO];
    }
    
	
	[viewController presentModalViewController:picker animated:YES];
}

- (void)emailShareVcard:(NSData *)data name:(NSString *)fileName
{
    if (![MFMailComposeViewController canSendMail])
    {
        return;
    }
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        picker.navigationBar.tintColor = [UIColor whiteColor];
    }
	picker.mailComposeDelegate = self;
	

    [picker addAttachmentData:data mimeType:@"text/x-vcard" fileName:fileName];
    

	[viewController presentViewController:picker animated:YES completion:nil];
}

- (BOOL)mmsShareVcard:(NSData *)data name:(NSString *)fileName
{
    if (![MFMessageComposeViewController canSendAttachments])
    {
        return NO;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
        NSDictionary *dic2 = [NSDictionary dictionaryWithObject:[UIColor colorFromHex:0x0093e7] forKey:UITextAttributeTextColor];
        [[UINavigationBar appearance] setTitleTextAttributes:dic2];
    }
    
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;
	
    [picker addAttachmentData:data typeIdentifier:(NSString *)kUTTypeVCard filename:fileName];
    
    
	[viewController presentModalViewController:picker animated:YES];

   
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        NSDictionary *dic3 = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
        [[UINavigationBar appearance] setTitleTextAttributes:dic3];
        [[UINavigationBar appearance] setBarTintColor:[UIColor colorFromHex:0x0093e7]];
    }
    
    return YES;
}

#pragma mark -
#pragma mark Dismiss Mail/SMS view controller

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the
// message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	
    //	feedbackMsg.hidden = NO;
    //	// Notifies users about errors associated with the interface
    //	switch (result)
    //	{
    //		case MFMailComposeResultCancelled:
    //			feedbackMsg.text = @"Result: Mail sending canceled";
    //			break;
    //		case MFMailComposeResultSaved:
    //			feedbackMsg.text = @"Result: Mail saved";
    //			break;
    //		case MFMailComposeResultSent:
    //			feedbackMsg.text = @"Result: Mail sent";
    //			break;
    //		case MFMailComposeResultFailed:
    //			feedbackMsg.text = @"Result: Mail sending failed";
    //			break;
    //		default:
    //			feedbackMsg.text = @"Result: Mail not sent";
    //			break;
    //	}
	[viewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)showMailPicker:(NSString *)text 
                             to:(NSArray *)toRecipients cc:(NSArray *)ccRecipients bcc:(NSArray *)bccRecipients images:(NSArray *)images
{
	// The MFMailComposeViewController class is only available in iPhone OS 3.0 or later.
	// So, we must verify the existence of the above class and provide a workaround for devices running
	// earlier versions of the iPhone OS.
	// We display an email composition interface if MFMailComposeViewController exists and the device
	// can send emails.	Display feedback message, otherwise.
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    
	if (mailClass != nil)
    {
        //[self displayMailComposerSheet];
		// We must always check whether the current device is configured for sending emails
		if ([mailClass canSendMail])
        {
			[self displayMailComposerSheet:text to:toRecipients cc:ccRecipients bcc:bccRecipients images:images];
		}
		else
        {
			[self showWarning:NSLocalizedString(@"No mail account", nil)];
		}
	}
	else
    {
		[self showWarning: @"Device not configured to send mail."];
	}
}

// Displays an SMS composition interface inside the application.
-(void)displaySMSComposerSheet:(NSString *)text phones:(NSArray *)recipientArray
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
        NSDictionary *dic2 = [NSDictionary dictionaryWithObject:[UIColor colorFromHex:0x0093e7] forKey:UITextAttributeTextColor];
        [[UINavigationBar appearance] setTitleTextAttributes:dic2];
    }
    
	MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
	picker.messageComposeDelegate = self;
    
    if ([recipientArray count] > 0)
    {
        picker.recipients = recipientArray;
    }
    
	picker.body = text;
	[viewController presentViewController:picker animated:YES completion:nil];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        NSDictionary *dic3 = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
        [[UINavigationBar appearance] setTitleTextAttributes:dic3];
        [[UINavigationBar appearance] setBarTintColor:[UIColor colorFromHex:0x0093e7]];
    }
    
    
}

// Dismisses the message composition interface when users tap Cancel or Send. Proceeds to update the
// feedback message field with the result of the operation.
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
	
	// Notifies users about errors associated with the interface
    //	switch (result)
    //	{
    //		case MessageComposeResultCancelled:
    //			feedbackMsg.text = @"Result: SMS sending canceled";
    //			break;
    //		case MessageComposeResultSent:
    //			feedbackMsg.text = @"Result: SMS sent";
    //			break;
    //		case MessageComposeResultFailed:
    //			feedbackMsg.text = @"Result: SMS sending failed";
    //			break;
    //		default:
    //			feedbackMsg.text = @"Result: SMS not sent";
    //			break;
    //	}
	[viewController dismissModalViewControllerAnimated:YES];
}


- (void)showSMSPicker:(NSString *)text phones:(NSArray *)recipientArray
{
    //	The MFMessageComposeViewController class is only available in iPhone OS 4.0 or later.
    //	So, we must verify the existence of the above class and log an error message for devices
    //		running earlier versions of the iPhone OS. Set feedbackMsg if device doesn't support
    //		MFMessageComposeViewController API.
	Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));
	
	if (messageClass != nil)
    {
		// Check whether the current device is configured for sending SMS messages
		if ([messageClass canSendText])
        {
			[self displaySMSComposerSheet:text phones:recipientArray];
		}
		else
        {
            
			[self showWarning: @"Device not configured to send SMS."];
            
		}
	}
	else
    {
        
		[self showWarning:@"Device not configured to send SMS."];
	}
}
@end
