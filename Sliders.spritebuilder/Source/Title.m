//
//  Title.m
//  Sliders
//
//  Created by Maria Luisa on 5/1/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Title.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKLoginKit/FBSDKLoginManager.h>
#import <FBSDKShareKit/FBSDKShareKit.h>


@implementation Title {
}

- (void) didLoadFromCCB {
    NSLog(@"fb token: %@", [FBSDKAccessToken currentAccessToken]);
    NSLog(@"fb user: %@", [FBSDKAccessToken currentAccessToken].userID);
}

/*

-(void) onEnter {
    [super onEnter];
    
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    UIView *view = [CCDirector sharedDirector].view;
    loginButton.center = ccpAdd(view.center, ccp(0, 140));
    [view addSubview:loginButton];
}
*/
@end
