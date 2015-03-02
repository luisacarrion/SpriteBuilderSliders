//
//  Hero.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Hero.h"
#import "MainScene.h"

@implementation Hero


- (void) didLoadFromCCB {
    // Set physics properties
    self.physicsBody.collisionType = @"hero";
    
    // Set drawing order
    self.zOrder = DrawingOrderHero;
}


@end
