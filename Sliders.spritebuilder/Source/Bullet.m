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
    //[self startParticleEffect];
    self.physicsBody.velocity = ccp(0, 0);
    [self impulseToTarget];
}

-(void)impulseToTarget {
    CGPoint impulseVector = [Utils getVectorToMoveFromPoint:self.position ToPoint:self.targetHero.position withImpulse:self.impulse];
    //CGPoint impulseVector = [Utils getVectorToMoveFromPoint:self.position ToPoint:self.targetHero.position withImpulse:1];
    [self.physicsBody  applyImpulse:impulseVector];

}
/*
-(void)startParticleEffect {
    CCParticleSystem *bulletTrail = (CCParticleSystem *)[CCBReader load:@"BulletParticles"];
    
    // make the particle effect clean itself up, once it is completed
    bulletTrail.autoRemoveOnFinish = TRUE;
    
    // place the particle effect on the seals position
    bulletTrail.position = self.position;
    
    // add the particle effect to the same node the seal is on
    [self.parent addChild:bulletTrail];
    
}
 */

-(void) rotateIndefinitely {
    CCActionRotateBy *rotateAction = [CCActionRotateBy actionWithDuration:0.3 angle:360];
    CCActionRepeatForever *forever = [CCActionRepeatForever actionWithAction:rotateAction];
    
    [self runAction:forever];
}

@end
