//
//  Hero.h
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//


@interface Hero : CCSprite <NSCoding>

@property (nonatomic, copy) NSString *ccbFileName;
// Amount of damage done to enemies (attack power)
@property (nonatomic, assign) NSInteger damage;
// Property to save the velocity in NSUserDefaults (because the physicsbody is not saved because CCSprite doesn't implement the NSCoding protocol)
@property (nonatomic, assign) CGPoint savedVelocity;

@end
