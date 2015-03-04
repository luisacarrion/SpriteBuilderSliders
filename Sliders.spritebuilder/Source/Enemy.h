//
//  Enemy.h
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "HandleEnemy.h"

@interface Enemy : CCSprite

@property (nonatomic, assign) NSInteger damageReceived;
@property (nonatomic, assign) NSInteger damageLimit;
@property (nonatomic, weak) id <HandleEnemy> handleEnemyDelegate;

-(void) applyDamage:(NSInteger) damage;

@end
