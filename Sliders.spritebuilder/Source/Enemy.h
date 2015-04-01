//
//  Enemy.h
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "HandleEnemy.h"

@interface Enemy : CCSprite <NSCoding>

@property (nonatomic, copy) NSString *ccbFileName;
// Maximum amount of damage a type of enemy can received. This value is fixed and never changes.
@property (nonatomic, assign) NSInteger health;
// Amount of damage received. Once it is equal to the damageLimit, this enemy dies.
@property (nonatomic, assign) NSInteger damageReceived;
// Amount of damage done to heroes (attack power)
@property (nonatomic, assign) NSInteger attackPower;
@property (nonatomic, weak) id <HandleEnemy> handleEnemyDelegate;

-(void) applyDamage:(NSInteger) damage;

@end
