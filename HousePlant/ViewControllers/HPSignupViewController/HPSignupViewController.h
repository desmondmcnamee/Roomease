//
//  HPSignupViewController.h
//  HousePlant
//
//  Created by Desmond McNamee on 12/22/2013.
//  Copyright (c) 2013 HousePlant. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMPAvatarView.h"
#import "MBProgressHUD.h"

@interface HPSignupViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MBProgressHUDDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *usernameClearButton;

@property (weak, nonatomic) IBOutlet UIButton *passwordClearButton;

@property (weak, nonatomic) IBOutlet UIImageView *blankProfilePicImage;
@property (weak, nonatomic) IBOutlet AMPAvatarView *setProfilePicImage;
@property (weak, nonatomic) IBOutlet UIButton *editProfileButton;


- (IBAction)onPasswordClearButtonPress:(id)sender;
- (IBAction)onEditProfilePicturePress:(id)sender;
- (IBAction)onSignupPress:(id)sender;
- (IBAction)onUsernameClearButtonPress:(id)sender;
- (IBAction)onBackPress:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
