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

@implementation Bullet {
    bool _fired;
}

- (void) didLoadFromCCB {
    // Set drawing order
    self.zOrder = DrawingOrderBullet;

    //self.visible = false;
    
    [self rotateIndefinitely];
}

-(void) fixedUpdate:(CCTime)delta {
    // If the target died, remove the bullet (in cases where two bullets are fired and the first bullet already killed the hero
    if (self.targetHero == nil || self.targetHero.health <= 0) {
        CCActionRemove *remove = [CCActionRemove action];
        [self runAction:remove];
    } else {
        // We redirect the bullet to the target hero continuously, becase the hero could have moved while the bullet was flying towards it
        if (_fired) {
            self.physicsBody.velocity = ccp(0, 0);
            [self impulseToTarget];
        }
    }
}

-(void) fire {
    _fired = TRUE;
    self.visible = true;
}

-(void)impulseToTarget {
    CGPoint impulseVector = [Utils getVectorToMoveFromPoint:self.position ToPoint:self.targetHero.position withImpulse:self.impulse];
    [self.physicsBody  applyImpulse:impulseVector];

}

-(void) rotateIndefinitely {
    CCTime duration = 0.6;//0.3;
    CCActionRotateBy *rotateAction = [CCActionRotateBy actionWithDuration:duration angle:360];
    CCActionRepeatForever *forever = [CCActionRepeatForever actionWithAction:rotateAction];
    
    [self runAction:forever];
}

@end
