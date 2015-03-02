//
//  Enemy.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Enemy.h"
#import "MainScene.h"

@implementation Enemy {

}

- (void) didLoadFromCCB {
    // Set physics properties
    self.physicsBody.collisionType = @"enemy";
    self.physicsBody.sensor = YES;
    
    // Set drawing order
    self.zOrder = DrawingOrderEnemy;
}


@end

