//
//  Enemy.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Enemy.h"
#import "Hero.h"
#import "MainScene.h"
#import "Utils.h"

static const NSInteger BULLET_IMPULSE = 20;//10;
static const NSInteger BULLET_ATTACK_POWER = 1;

@implementation Enemy {
}

- (void) didLoadFromCCB {
    self.isAlive = true;
    
    // Set physics properties
    self.physicsBody.sensor = YES;
    
    // Set drawing order
    self.zOrder = DrawingOrderEnemy;
}

-(void) applyDamage:(NSInteger)damage {
    self.damageReceived += damage;
    
    if (self.isOnRevengeMode) {
        [self playRevengeModeAnimation];
    } else {
        [self stopRevengeModeAnimation];
    }
    
    if (self.damageReceived >= self.health) {
        [self die];
    }
}

-(void) die {
    // Remove the enemy collision type, so heroes cannot collide with an enemy once it's fading away
    self.isAlive = false;
    [self playDieAnimation];
    [self.handleEnemyDelegate removeEnemy:self];
}

-(void) playRevengeModeAnimation {
    self.isOnRevengeMode = true;
    
    if (self.damageReceived == 0) {
        [self.animationManager runAnimationsForSequenceNamed:@"Revenge Mode"];
    } else if (self.damageReceived == 1) {
        [self.animationManager runAnimationsForSequenceNamed:@"Revenge Mode Wounded 1"];
    } else if (self.damageReceived >= 2) {
        [self.animationManager runAnimationsForSequenceNamed:@"Revenge Mode Wounded 2"];
    }
}

-(void) stopRevengeModeAnimation {
    self.isOnRevengeMode = false;
    if (self.damageReceived == 0) {
        [self.animationManager runAnimationsForSequenceNamed:@"Normal"];
    } else if (self.damageReceived == 1) {
        [self.animationManager runAnimationsForSequenceNamed:@"Normal Wounded 1"];
    } else if (self.damageReceived >= 2) {
        [self.animationManager runAnimationsForSequenceNamed:@"Normal Wounded 2"];
    }
}

-(void) playSpawnAnimation {
    self.scaleY = 0.5;
    self.scaleX = 0.5;
    
    CCAction *growAction = [CCActionScaleTo actionWithDuration:0.05 scaleX:1 scaleY:1];
    
    [self runAction:growAction];
}

-(void) playDieAnimation {
    // Load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"EnemyExplosion"];
    
    // Make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    
    // Place the particle effect on the enemiy's position
    explosion.position = self.position;
    
    // Add the particle effect to the same node the seal is on
    [self.parent addChild:explosion];
    
    [self removeFromParent];
    
    /*
    // Display sword slash animation before removing the enemy
    // Add sword slash sprite
    CCSprite *swordSlash = [CCSprite spriteWithImageNamed:@"assets/slash2.png"];
    swordSlash.position = self.position;
    swordSlash.anchorPoint = ccp(0.5, 0.5);
    [self.parent addChild:swordSlash];
    
    // Play the CCAction animations to fade the sword slash
    CCActionDelay *delayAction = [CCActionDelay actionWithDuration:0.1];
    CCActionFadeOut *fadeAction = [CCActionFadeOut actionWithDuration:0.75];
    CCActionRemove *removeAction = [CCActionRemove action];
    CCActionSequence *swordSlashSequenceAction = [CCActionSequence actionWithArray:@[delayAction, fadeAction, removeAction]];
    [swordSlash runAction:swordSlashSequenceAction];
    
    // Play the CCAction animations to fade the enemy
    CCActionSequence *sequenceActionEnemy = [CCActionSequence actionWithArray:@[fadeAction, removeAction]];
    [self runAction:sequenceActionEnemy];
     */
}

-(void) playAnimationShootBulletAtHero:(Hero*)hero {
    // Animate the enemy to make it look like it's throwing a shuriken
    
    // Calculate the coordinates for the move by animation
    CGPoint towardsHeroCoordinates = [Utils getVectorToMoveFromPoint:self.position ToPoint:hero.position withImpulse:10];
    
    // Create the reusable CCActions
    CCActionMoveBy *moveByAction = [CCActionMoveBy actionWithDuration:0.1 position:towardsHeroCoordinates];
    CCActionScaleBy *scaleAction = [CCActionScaleBy actionWithDuration:0.1 scaleX:0.9 scaleY:0.9];
    CCActionSpawn *spawnActionMove = [CCActionSpawn actionWithArray:@[moveByAction, scaleAction]];
    
    // Create the bullet and the CCActions that depend on the bullet
    Bullet *bullet = [self getNewBulletForHero:hero];
    CCActionCallFunc *fireBulletAction = [CCActionCallFunc actionWithTarget:bullet selector:@selector(fire)];
    CCActionSpawn *spawnActionMoveAndFire = [CCActionSpawn actionWithArray:@[spawnActionMove, fireBulletAction]];
    
    // Create the sequence of actions that the enemy will execute
    CCActionSequence *sequenceAction = [CCActionSequence actionWithArray:@[spawnActionMoveAndFire, [spawnActionMove reverse]]];
    
    // Create extra bullets (and the animations to fire them) for every point of this enemy's attack power
    for (int i = 1; i < self.attackPower; i++) {
        bullet = [self getNewBulletForHero:hero];
        fireBulletAction = [CCActionCallFunc actionWithTarget:bullet selector:@selector(fire)];
        spawnActionMoveAndFire = [CCActionSpawn actionWithArray:@[spawnActionMove, fireBulletAction]];
        
        // Concatenate the previous sequenceAction with the new actions to fire the new bullet
        sequenceAction = [CCActionSequence actionWithArray:@[sequenceAction, spawnActionMoveAndFire, [spawnActionMove reverse]]];
    }
    
    // Run all the sequenceAction to fire all the bullets created
    [self runAction:sequenceAction];
}

-(Bullet*) getNewBulletForHero:(Hero*) hero {
    Bullet *bullet = (Bullet*) [CCBReader load:@"Bullet"];
    [self.parent addChild:bullet];
    bullet.position = self.position;
    bullet.attackPower = BULLET_ATTACK_POWER;
    bullet.targetHero = hero;
    bullet.impulse = BULLET_IMPULSE;
    
    return bullet;
}

#pragma mark NSCoding Delegates

-(id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Variables from CCSprite class
    self.position = [decoder decodeCGPointForKey:@"position"];
    // Variables from Enemy class
    self.ccbFileName = [decoder decodeObjectForKey:@"ccbFileName"];
    self.health = [decoder decodeIntegerForKey:@"health"];
    self.damageReceived = [decoder decodeIntegerForKey:@"damageReceived"];
    self.attackPower = [decoder decodeIntegerForKey:@"attackPower"];
    self.animationRunning = [decoder decodeObjectForKey:@"animationRunning"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder {
    // Variables from CCSprite class
    [encoder encodeCGPoint:self.position forKey:@"position"];
    // Variables from Enemy class
    [encoder encodeObject:self.ccbFileName forKey:@"ccbFileName"];
    [encoder encodeInteger:self.health forKey:@"health"];
    [encoder encodeInteger:self.damageReceived forKey:@"damageReceived"];
    [encoder encodeInteger:self.attackPower forKey:@"attackPower"];
    self.animationRunning = [self.animationManager runningSequenceName];
    [encoder encodeObject:self.animationRunning forKey:@"animationRunning"];
}

@end

