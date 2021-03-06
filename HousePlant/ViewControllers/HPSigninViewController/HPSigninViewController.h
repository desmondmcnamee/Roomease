//
//  HPSigninViewController.h
//  HousePlant
//
//  Created by Desmond McNamee on 12/22/2013.
//  Copyright (c) 2013 HousePlant. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPSigninViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *usernameHighlight;
@property (weak, nonatomic) IBOutlet UIImageView *passwordHighlight;

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *usernameClearButton;
@property (weak, nonatomic) IBOutlet UIButton *passwordClearButton;

- (IBAction)onUsernameClearPress:(id)sender;
- (IBAction)onPasswordClearPress:(id)sender;

- (IBAction)onSigninPress:(id)sender;
- (IBAction)onBackPress:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


@end
