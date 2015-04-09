//
//  Bullet.m
//  Sliders
//
//  Created by Maria Luisa on 3/31/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Bullet.h"
#import "MainScene.h"
#import "Utils.h"

@implementation Bullet

- (void) didLoadFromCCB {
    // Set drawing order
    self.zOrder = DrawingOrderBullet;

    [self rotateIndefinitely];
}

-(void) fixedUpdate:(CCTime)delta {
    // We redirect the bullet to the target hero continuously, becase the hero could have moved while the bullet was flying towards it
    self.physicsBody.velocity = ccp(0, 0);
    [self impulseToTarget];
}

-(void)impulseToTarget {
    CGPoint impulseVector = [Utils getVectorToMoveFromPoint:self.position ToPoint:self.targetHero.position withImpulse:self.impulse];
    [self.physicsBody  applyImpulse:impulseVector];

}

-(void) rotateIndefinitely {
    CCActionRotateBy *rotateAction = [CCActionRotateBy actionWithDuration:0.3 angle:360];
    CCActionRepeatForever *forever = [CCActionRepeatForever actionWithAction:rotateAction];
    
    [self runAction:forever];
}

@end
