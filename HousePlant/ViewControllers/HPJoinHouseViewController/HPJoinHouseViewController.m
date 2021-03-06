//
//  HPJoinHouseViewController.m
//  HousePlant
//
//  Created by Desmond McNamee on 1/3/2014.
//  Copyright (c) 2014 HousePlant. All rights reserved.
//

#import "HPJoinHouseViewController.h"
#import "HPMainViewController.h"
#import "HPNewHouseSetup.h"

typedef void (^BackgroundTaskResultBlock)(NSString *errorString);

@interface HPJoinHouseViewController ()

@end

@implementation HPJoinHouseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewDidAppear:(BOOL)animated
{
    [_houseNameTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*** User interface sheeet ***/
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == _houseNameTextField)
    {
        [_houseNameClearButton setHidden:false];
        [_passwordClearButton setHidden:true];
        [_houseNameTextHighlight setHidden:false];
        [_passwordTextHighlight setHidden:true];
        
    }
    else if (textField == _passwordTextField)
    {
        [_houseNameClearButton setHidden:true];
        [_passwordClearButton setHidden:false];
        [_houseNameTextHighlight setHidden:true];
        [_passwordTextHighlight setHidden:false];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _houseNameTextField) {
        [_passwordTextField becomeFirstResponder];
    }
    else
    {
        [self onMoveInButtonPress:nil];
    }
    return YES;
}


- (IBAction)onBackPress:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)houseNameClearButtonPress:(id)sender {
    _houseNameTextField.text = @"";
}
- (IBAction)passwordClearButtonPress:(id)sender {
    _passwordTextField.text = @"";
}

- (IBAction)onMoveInButtonPress:(id)sender {
    [_activityIndicator setHidden:false];
    [self joinUserToHouseInBackgroundWithBlock:^(NSString *errorString) {
        //
        [_activityIndicator setHidden:true];
        if (errorString) {
            [CSNotificationView showInViewController:self
                                               style:CSNotificationViewStyleError
                                             message:errorString];
            return;
        }
        HPMainViewController *mainViewController = [[HPMainViewController alloc] init];
        mainViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        // initialize the navigation controller and present it
        [self presentViewController:mainViewController animated:YES completion:nil];
    }];
    
}

- (void) joinUserToHouseInBackgroundWithBlock:(BackgroundTaskResultBlock)block
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *errorString = [self validateUserInputs];
        
        if (!errorString) {
            [HPNewHouseSetup setup];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block)
                block(errorString);
            
        });
    
    });


}

- (NSString *) validateUserInputs
{
    if (_houseNameTextField.text.length < 1)
    {
        return @"Please enter a house name.";
    }
    if (_passwordTextField.text.length < 1) {
        return @"Please enter a password.";
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"House"];
    [query whereKey:@"name" equalTo:_houseNameTextField.text];
    
    NSArray *houseArray = [query findObjects];
    
    if (houseArray.count == 0) {
        
        return @"Could not find house. Remember house names are case sensative.";
    }
    
    PFObject *house = [houseArray objectAtIndex:0];
    
    NSString *housePassword = [house objectForKey:@"password"];
    if(![housePassword isEqualToString:_passwordTextField.text])
    {
        return @"Password does not match this house.";
    }
    
#warning this should be fixed.
    if ([[house objectForKey:@"users"] count] >= 4) {
        return @"Sorry this house is full. Only 4 people per house.";
    }
    
    [house addObject:[PFUser currentUser] forKey:@"users"];
    
    if(![house save])
    {
        return @"There was an error moving in. Please try again.";
    }
    else
    {
        [[PFUser currentUser] setObject:house forKey:@"home"];
        [[PFUser currentUser] save];
    }
    
    return nil;
}
@end
