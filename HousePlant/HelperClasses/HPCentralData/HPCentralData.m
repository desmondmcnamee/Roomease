//
//  HPCentralData.m
//  RoomEase
//
//  Created by Desmond McNamee on 1/9/2014.
//  Copyright (c) 2014 HousePlant. All rights reserved.
//

#import "HPCentralData.h"

@implementation HPCentralData

+(void) resyncAllData
{
    //resync everything stored in NSUserDefault store with fresh parse data! Yum :)
}

+(void) resyncCurrentUser
{
    //resync all the current user info.
}

+(void) resyncHouse
{
    //resync this users house.
}

+(void) resyncRoommates:(CentralDataSaveResultBlock)block
{
    //resync the roommates in this house.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSMutableArray *roommatesData = [[NSMutableArray alloc] init];
        
        //pulling from parse
        PFObject *parseHome = [[PFUser currentUser] objectForKey:@"home"];
#warning house not saved to central data
        [parseHome fetch];
        if (parseHome == nil)
        {
            //No home exists for this user yet.
            if (block)
            {
                block(nil);
            }
        }
        
        NSArray *pfRoommates = [parseHome objectForKey:@"users"];
        for (PFObject *pfRoommate in pfRoommates) {
            [pfRoommate fetch];
            HPRoommate * roommate = [[HPRoommate alloc] init];
            roommate.username = pfRoommate[@"username"];
            
            [roommate setAtHomeString:pfRoommate[@"atHome"]];
            
            
            PFFile *userImageFile = [pfRoommate objectForKey:@"profilePic"];
            roommate.profilePic = [UIImage imageWithData:[userImageFile getData]];
            
            NSData *roommateData = [NSKeyedArchiver archivedDataWithRootObject:roommate];
            [roommatesData addObject:roommateData];
        }
        
        [persistantStore setObject:roommatesData forKey:@"hp_roommates"];
        [persistantStore synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block)
                block(nil);
        });
        
        
    });
}


+(void) clearCentralData
{
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    for (id key in dict) {
        [defs removeObjectForKey:key];
    }
    [defs synchronize];
}

+(void) getCurrentUserInBackgroundWithBlock:(CentralDataRoommateResultBlock)block
{

    __block NSData *roommateData = [persistantStore objectForKey:@"hp_currentUser"];
    __block HPRoommate *roommate =  [NSKeyedUnarchiver unarchiveObjectWithData:roommateData];
    
    if(roommate == nil)
    {
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            roommate = [[HPRoommate alloc] init];
            [[PFUser currentUser] fetch];
            roommate.username = [[PFUser currentUser] username];
            [roommate setAtHomeString:[PFUser currentUser][@"atHome"]];
        
            PFFile *userImageFile = [[PFUser currentUser] objectForKey:@"profilePic"];
            roommate.profilePic = [UIImage imageWithData:[userImageFile getData]];
        
            //convert roommate object into encoded data to store in NSUserdefault
            roommateData = [NSKeyedArchiver archivedDataWithRootObject:roommate];
        
            [persistantStore setObject:roommateData forKey:@"hp_currentUser"];
            [persistantStore synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block)
                    block(roommate, nil);
            });
        });
    }

    if (block)
        block(roommate, nil);
    
}


+(HPRoommate *) getCurrentUser;
{
    //if the user isn't stored in NSUserDefaults pull him from parse. Otherwise return the user stored in NSUserDefaults.
    
    NSData *roommateData = [persistantStore objectForKey:@"hp_currentUser"];
    HPRoommate *roommate =  [NSKeyedUnarchiver unarchiveObjectWithData:roommateData];
    
    if(roommate == nil)
    {
        roommate = [[HPRoommate alloc] init];
        [[PFUser currentUser] fetch];
        PFUser *currentUser = [PFUser currentUser];
        roommate.username = [[PFUser currentUser] username];
       
        PFFile *userImageFile = [[PFUser currentUser] objectForKey:@"profilePic"];
        roommate.profilePic = [UIImage imageWithData:[userImageFile getData]];
        
        [roommate setAtHomeString:currentUser[@"atHome"]];
        
        //convert roommate object into encoded data to store in NSUserdefault
        roommateData = [NSKeyedArchiver archivedDataWithRootObject:roommate];
        
        [persistantStore setObject:roommateData forKey:@"hp_currentUser"];
        [persistantStore synchronize];
    }
    
    return roommate;
}

+(void) saveCurrentUserInBackgroundWithRoommate:(HPRoommate*)roommate andBlock:(CentralDataSaveResultBlock)block
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error;
        if (![HPCentralData saveCurrentUser:roommate])
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"save failed" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"house" code:100 userInfo:details];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block)
                block(error);
        });
    });
}

+(bool) saveCurrentUser:(HPRoommate *)roommate
{
    //save the new user to parse.
    PFUser *currentUser = [PFUser currentUser];
    HPRoommate *oldUser = [HPCentralData getCurrentUser];
    
#warning does it makes sence to switch the order of the following two lines of code? That way roommate's nil fields will be filled with local storage values before sending the new roommate to parse.
    [HPCentralData transferAttributesFromUser:roommate toPFObject:currentUser];
    
    roommate = [HPCentralData transferOldRoommate:oldUser toNewRoomate:roommate];
    
    NSData *userData = [NSKeyedArchiver archivedDataWithRootObject:roommate];
    [persistantStore setObject:userData forKey:@"hp_currentUser"];
    [persistantStore synchronize];
    
    //This function saves the the new current user to the local roommate array.
    [HPCentralData saveRoommatesWithSingleRoommate:roommate];
    
    return true;
}

//Checks if the home exists in local storage and if it doesn't it pulls it from parse and stores it in local storage.
+(void) getHouseInBackgroundWithBlock:(CentralDataHouseResultBlock)block
{
    __block NSData  *homeData = [persistantStore objectForKey:@"hp_home"];
    __block HPHouse *home = [NSKeyedUnarchiver unarchiveObjectWithData:homeData];
    
    if (home == nil)
    {
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

            home = [[HPHouse alloc] init];
            [[PFUser currentUser] fetch];
            __block PFObject *parseHome = [[PFUser currentUser] objectForKey:@"home"];
            if (parseHome == nil)
            {
                //No home exists for this user yet.
                if (block)
                    block(nil, nil);
                return;
            }
            parseHome = [parseHome fetchIfNeeded];
            home.houseName = [parseHome objectForKey:@"name"];
            
            //Get the parse GeoPoint and convert it into a location to be stored locally
            PFGeoPoint *parseGeoPoint = [parseHome objectForKey:@"location"];
            CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:parseGeoPoint.latitude longitude:parseGeoPoint.longitude];
            home.location = newLocation;
            
            home.addressText = [parseHome objectForKey:@"addressText"];
            
            //convert roommate object into encoded data to store in NSUserdefault
            homeData = [NSKeyedArchiver archivedDataWithRootObject:home];
            [persistantStore setObject:homeData forKey:@"hp_home"];
            [persistantStore synchronize];

            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block)
                    block(home, nil);
            });
        });
    }
    else if (block)
    {
        block(home, nil);
    }
        
}

+(HPHouse *) getHouse
{
    NSData *homeData = [persistantStore objectForKey:@"hp_home"];
    HPHouse *home =  [NSKeyedUnarchiver unarchiveObjectWithData:homeData];
    
    if (home == nil) {
        //No local copy yet. Better grab it from parse.
        home = [[HPHouse alloc] init];
        [[PFUser currentUser] fetch];
        __block PFObject *parseHome = [[PFUser currentUser] objectForKey:@"home"];
        
        [parseHome fetch];
        if (parseHome == nil)
        {
            //No home exists for this user yet.
            return nil;
        }
        home.houseName = [parseHome objectForKey:@"name"];
        
        //Get the parse GeoPoint and convert it into a location to be stored locally
        PFGeoPoint *parseGeoPoint = [parseHome objectForKey:@"location"];
        CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:parseGeoPoint.latitude longitude:parseGeoPoint.longitude];
        home.location = newLocation;
        
        home.addressText = [parseHome objectForKey:@"addressText"];
        
        //convert roommate object into encoded data to store in NSUserdefault
        homeData = [NSKeyedArchiver archivedDataWithRootObject:home];
        [persistantStore setObject:homeData forKey:@"hp_home"];
        [persistantStore synchronize];
    }
    return home;
}

+ (void) saveHouseInBackgroundWithHouse:(HPHouse *)house andBlock:(CentralDataSaveResultBlock)block
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        HPHouse *oldHouse = [HPCentralData getHouse];
        HPHouse *newHouse = house;
        __block NSError *error = nil;
        
        //save the new house to parse.
        [[PFUser currentUser] fetch];
        PFObject *parseHome = [[PFUser currentUser] objectForKey:@"home"];
        if (parseHome == nil)
        {
            //this should never happen
            NSLog(@"User house is null on the server. This should never happen.");
            if (block)
            {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"save failed" forKey:NSLocalizedDescriptionKey];
                error = [NSError errorWithDomain:@"house" code:100 userInfo:details];
                block(error);
            }
            return;
        }
        
        //Set the new attributes as long as they are not null. If they are null we assume keep the old NSUserDefault values.
        bool parseSave = [HPCentralData transferAttributesFromHouse:house toPFObject:parseHome];
        
        if (parseSave == false) {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"save failed" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"house" code:200 userInfo:details];
        }
        
        newHouse = [HPCentralData transferOldhouse:oldHouse toNewHouse:newHouse];
        
        //if it is successfully saved to parse, replace the hp_home in NSUserDefaults with the new house.
        //convert roommate object into encoded data to store in NSUserdefault
        NSData *homeData = [NSKeyedArchiver archivedDataWithRootObject:newHouse];
        [persistantStore setObject:homeData forKey:@"hp_home"];
        [persistantStore synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block)
                block(error);
                
        });
    });
}

+ (bool) saveHouse:(HPHouse *)house
{    
    //save the new house to parse.
    PFObject *parseHome = [[PFUser currentUser] objectForKey:@"home"];
    HPHouse *oldHouse = [HPCentralData getHouse];
    
    if (parseHome == nil)
    {
        //this should never happen
        NSLog(@"User house is null on the server. This should never happen.");
        return false;
    }
 
    //Set the new attributes as long as they are not null. If they are null we assume keep the old NSUserDefault values.
    [HPCentralData transferAttributesFromHouse:house toPFObject:parseHome];
    house = [HPCentralData transferOldhouse:oldHouse toNewHouse:house];
    
    //if it is successfully saved to parse, replace the hp_home in NSUserDefaults with the new house.
    //convert roommate object into encoded data to store in NSUserdefault
    NSData *homeData = [NSKeyedArchiver archivedDataWithRootObject:house];
    [persistantStore setObject:homeData forKey:@"hp_home"];
    [persistantStore synchronize];
    
    return true;
}

+(void) getRoommatesInBackgroundWithBlock:(CentralDataRoommatesResultBlock)block
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSArray *roommates = [HPCentralData getRoommates];
        NSError *error;
        if (!roommates)
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"saving roommates failed" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"roommates" code:100 userInfo:details];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block)
                block(roommates, error);
        });
    });
}

+(NSArray *) getRoommates
{
    NSMutableArray *roommatesData = [persistantStore objectForKey:@"hp_roommates"];
    NSMutableArray *roommates = [[NSMutableArray alloc] init];
    
    for (NSData *roommateData in roommatesData) {
        HPRoommate *roommate = [NSKeyedUnarchiver unarchiveObjectWithData:roommateData];
        [roommates addObject:roommate];
    }
    
    if ([roommates count] == 0)
    {
        roommatesData = [[NSMutableArray alloc] init];
        
        //As long as user is saved in the cloud we must fetch here. Trust me.
        [[PFUser currentUser] fetch];
        //pulling from parse
        PFObject *parseHome = [[PFUser currentUser] objectForKey:@"home"];
#warning house not saved to central data
        [parseHome fetch];
        if (parseHome == nil)
        {
            //No home exists for this user yet.
            return nil;
        }

        NSArray *pfRoommates = [parseHome objectForKey:@"users"];
        for (PFObject *pfRoommate in pfRoommates) {
            [pfRoommate fetch];
            HPRoommate * roommate = [[HPRoommate alloc] init];
            roommate.username = pfRoommate[@"username"];
            
            [roommate setAtHomeString:pfRoommate[@"atHome"]];
            
            
            PFFile *userImageFile = [pfRoommate objectForKey:@"profilePic"];
            roommate.profilePic = [UIImage imageWithData:[userImageFile getData]];
            
            [roommates addObject:roommate];
            
            NSData *roommateData = [NSKeyedArchiver archivedDataWithRootObject:roommate];
            [roommatesData addObject:roommateData];
        }
        
        [persistantStore setObject:roommatesData forKey:@"hp_roommates"];
        [persistantStore synchronize];
        
    }
    
    return roommates;
}

#pragma mark - House Helper Methods

+ (bool)transferAttributesFromHouse:(HPHouse *)house toPFObject:(PFObject *)parseHome
{
    //Set the new attributes as long as they are not null. If they are null we assume keep the old NSUserDefault values.
    if ([house houseName] != nil) {
        parseHome[@"name"] = [house houseName];
    }
    
    if ([house location] != nil) {
        parseHome[@"location"] =  [PFGeoPoint geoPointWithLocation:[house location]];
    }
    
    if ([house addressText] != nil) {
        parseHome[@"addressText"] = [house addressText];
    }
    
    if ([parseHome save] == false) {
        return false;
    }
    
    return true;
}

//This function fills in any blankspaces in the new house with the old houses attributes. This prevents blanks being stored in local storage.
+ (HPHouse *) transferOldhouse:(HPHouse *)oldHouse toNewHouse:(HPHouse *)newHouse
{
    //Set the new attributes as long as they are not null. If they are null we assume keep the old NSUserDefault values.
    if ([newHouse houseName] == nil) {
        newHouse.houseName = oldHouse.houseName;
    }
    
    if ([newHouse location] == nil) {
        newHouse.location = oldHouse.location;
    }
    
    if ([newHouse addressText] == nil) {
        newHouse.addressText = oldHouse.addressText;
    }
    
    if ([newHouse region] == nil) {
        newHouse.region = oldHouse.region;
    }
    
    return newHouse;
}

#pragma mark - CurrentUser Helper Methods

+ (bool)transferAttributesFromUser:(HPRoommate *)roommate toPFObject:(PFObject *)parseUser
{
    //Set the new attributes as long as they are not null. If they are null we assume keep the old NSUserDefault values.
    if ([roommate username] != nil) {
       parseUser[@"username"] = roommate.username;
    }
    
    if ([roommate profilePic] != nil) {
        NSData *imageData = UIImagePNGRepresentation(roommate.profilePic);
        PFFile *imageFile = [PFFile fileWithName:@"profile_pic.jpg" data:imageData];
        parseUser[@"profilePic"] = imageFile;
    }

#warning This logic requires that the UI always pass an atHomeString when modifying the user. Otherwise it will be set to null. Can this be better thought out?
    if ([roommate atHomeString] != nil) {
        parseUser[@"atHome"] = [roommate atHomeString];
    }
    else
    {
        parseUser[@"atHome"] = @"unknown";
    }
    
    //Make sure the user is logged in.
    if ([PFUser currentUser] != nil)
    {
        if ([parseUser save] == false) {
            return false;
        }
    }
    else
    {
        NSLog(@"Tried to save a logged out user.");
    }
    
    return true;
}

//This function fills in any blankspaces in the new roommate with the old roommates attributes. This prevents blanks being stored in local storage.
+ (HPRoommate *) transferOldRoommate:(HPRoommate *)oldRoommate toNewRoomate:(HPRoommate *)newRoommate
{
    //Set the new attributes as long as they are not null. If they are null we assume keep the old NSUserDefault values.
    if ([newRoommate username] == nil) {
        newRoommate.username = oldRoommate.username;
    }
    
    if ([newRoommate profilePic] == nil) {
        newRoommate.profilePic = oldRoommate.profilePic;
    }
    
    if ([newRoommate atHomeString] == nil) {
        newRoommate.atHomeString = oldRoommate.atHomeString;
    }

    return newRoommate;
}

//You need to pass a username here bacause it is possible that a roommate object will have a null username
+ (bool)saveRoommatesWithSingleRoommate:(HPRoommate *)roommate
{
    NSMutableArray *roommatesData = [[NSMutableArray alloc] init];
    //Find the user in the local storage roommate array.
    if (!roommate.username) {
        [NSException raise:@"HP Exception: Invalid roommate sent to saveRoommatesWithSingleRoommate" format:@"roommate of %@ is invalid", roommate];
    }
    NSMutableArray *roommates = [NSMutableArray arrayWithArray:[HPCentralData getRoommates]];
    
    for (int roommateCount = 0; roommateCount < [roommates count]; roommateCount++) {
        HPRoommate *roommateToFind = [roommates objectAtIndex:roommateCount];
        if ([roommateToFind.username isEqualToString:roommate.username]) {
            [roommates replaceObjectAtIndex:roommateCount withObject:roommate];
        }
    }
    
    //Loop through and convert all the roommates into data
    for (HPRoommate* roomateToConvertToData in roommates) {
        NSData *roommateData = [NSKeyedArchiver archivedDataWithRootObject:roomateToConvertToData];
        [roommatesData addObject:roommateData];
    }
    
    [persistantStore setObject:roommatesData forKey:@"hp_roommates"];
    [persistantStore synchronize];
    
    return true;
}

@end
