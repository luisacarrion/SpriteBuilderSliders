//
//  Hero.h
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "HandleHero.h"

@interface Hero : CCSprite <NSCoding>

@property (nonatomic, copy) NSString *ccbFileName;
@property (nonatomic, assign) NSInteger health;
@property (nonatomic, assign) NSInteger damageReceived;
// Amount of damage done to enemies (attack power)
@property (nonatomic, assign) NSInteger attackPower;
// Property to save the velocity in NSUserDefaults (because the physicsbody is not saved because CCSprite doesn't implement the NSCoding protocol)
@property (nonatomic, assign) CGPoint savedVelocity;
@property (nonatomic, weak) id <HandleHero> handleHeroDelegate;

-(void) applyDamage:(NSInteger) damage;

@end
