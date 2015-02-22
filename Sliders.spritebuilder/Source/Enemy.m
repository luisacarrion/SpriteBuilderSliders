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
    
    NSLog(@"hitLimit: %ld", self.hitLimit);
    self.physicsBody.collisionType = @"enemy";
    self.physicsBody.sensor = YES;
    self.zOrder = DrawingOrderEnemy;

}


@end

