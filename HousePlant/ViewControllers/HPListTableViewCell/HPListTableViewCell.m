//
//  HPListTableViewCell.m
//  RoomEase
//
//  Created by Desmond McNamee on 2014-03-17.
//  Copyright (c) 2014 HousePlant. All rights reserved.
//

#import "HPListTableViewCell.h"

#define CLOSED_SLIDER_X 0
#define OPEN_SLIDER_X -64
#define HALFWAY_SLIDER_X (OPEN_SLIDER_X/2)

@implementation HPListTableViewCell
{
    bool checked;
}

- (void)awakeFromNib
{
    // Initialization code
    _panGesture.delegate = self;
    checked = false;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    //If the gesture is more in the Y direction than X than don't handle pan, the user is probably trying to scroll a table.
    if ([gestureRecognizer class] == [UIPanGestureRecognizer class]) {
        
        UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint translation = [panGestureRecognizer translationInView:self];
        return fabs(translation.y) < fabs(translation.x);
    }
    return NO;
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    [_fader setHidden:false];
    CGPoint translation = [recognizer translationInView:self];
    bool outOfBounds = false;
    //Are they trying to slide it too far in one direction? Return.
    if (_mainCellView.frame.origin.x >= CLOSED_SLIDER_X && translation.x > 0) {
        outOfBounds = true;
    }
    if (_mainCellView.frame.origin.x <= OPEN_SLIDER_X && translation.x < 0) {
        outOfBounds = true;
    }
    
    //Did they lift their thumb?
    //Did the user lift thumb?
    //Fully open of fully close the sliderView based on where the user left off.
    if (recognizer.state == UIGestureRecognizerStateEnded || outOfBounds)
    {
        if(_mainCellView.frame.origin.x <= HALFWAY_SLIDER_X)
        {
            [UIView animateWithDuration:0.2 animations:^{
                [_mainCellView setFrame:CGRectMake(OPEN_SLIDER_X, _mainCellView.frame.origin.y, _mainCellView.frame.size.width, _mainCellView.frame.size.height)];
            } completion:nil];
        }
        else
        {
            [UIView animateWithDuration:0.2 animations:^{
                [_mainCellView setFrame:CGRectMake(CLOSED_SLIDER_X, _mainCellView.frame.origin.y, _mainCellView.frame.size.width, _mainCellView.frame.size.height)];
            } completion:^(BOOL finished) {
                //
                [_fader setHidden:true];
            }];
            
        }
    }
    
    if (_mainCellView.center.x + translation.x > 160) {
        _mainCellView.center = CGPointMake(160,
                                           _mainCellView.center.y);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self];
        return;
    }
    if (_mainCellView.center.x + translation.x < 160 + OPEN_SLIDER_X ) {
        _mainCellView.center = CGPointMake(160 + OPEN_SLIDER_X,
                                           _mainCellView.center.y);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self];
        return;
    }
    
    _mainCellView.center = CGPointMake(_mainCellView.center.x + translation.x,
                                       _mainCellView.center.y);


    [recognizer setTranslation:CGPointMake(0, 0) inView:self];
}

- (IBAction)onDeletePress:(id)sender {
    NSLog(@"Delete Press");
}
- (IBAction)onCheckboxPress:(id)sender {
    NSLog(@"Checkbox Press");
    if (checked) {
        [self.blankCheckbox setHidden:false];
        checked = false;
        [_avatar setHidden:true];
        
        NSDictionary* attributes = @{
                                     NSStrikethroughStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone]
                                     };
        
        NSAttributedString* attrText = [[NSAttributedString alloc] initWithString:self.entryTitle.text attributes:attributes];
        self.entryTitle.attributedText = attrText;
    }
    else
    {
        [HPCentralData getCurrentUserInBackgroundWithBlock:^(HPRoommate *roommate, NSError *error) {
            //
            if([roommate profilePic])
            {
                _avatar = [[AMPAvatarView alloc] initWithFrame:CGRectMake(20, 5, 31, 31)];
                
                [_mainCellView addSubview:_avatar];
                [_mainCellView sendSubviewToBack:_avatar];
                _avatar.image = roommate.profilePic;
                
                [_avatar setBorderWith:0.0];
                [_avatar setShadowRadius:0.0];
                [_avatar setBorderColor:kLightBlueColour];
                
                [self.blankCheckbox setHidden:true];
                
                NSDictionary* attributes = @{
                                             NSStrikethroughStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle]
                                             };
                
                NSAttributedString* attrText = [[NSAttributedString alloc] initWithString:self.entryTitle.text attributes:attributes];
                self.entryTitle.attributedText = attrText;
            }
        }];
        
        UITableView *tableView = (UITableView *)self.superview.superview;
        
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:([tableView numberOfRowsInSection:0] - 1) inSection:0];

        [tableView moveRowAtIndexPath:[tableView indexPathForCell:self] toIndexPath:lastIndexPath];
        checked = true;
    }

}
@end
