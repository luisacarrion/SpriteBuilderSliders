//
//  Hero.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Hero.h"
#import "MainScene.h"

static const NSInteger INITIAL_DAMAGE = 1;

@implementation Hero


- (void) didLoadFromCCB {
    // Set physics properties
    self.physicsBody.collisionType = @"hero";
    
    // Set drawing order
    self.zOrder = DrawingOrderHero;
    
    // Set initial damage
    self.damage = INITIAL_DAMAGE;
}


@end
