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
    self.isAlive = true;
    
    // Set physics properties
    self.physicsBody.collisionType = @"hero";
    
    // Set drawing order
    self.zOrder = DrawingOrderHero;
}

-(void) displayNormalMode {
    if (self.damageReceived == 0) {
        self.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"assets/hero.png"];
    } else if (self.damageReceived == 1) {
        self.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"assets/heroWounded1.png"];
    } else if (self.damageReceived == 2) {
        self.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"assets/heroWounded2.png"];
    } else if (self.damageReceived >= 3) {
        self.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"assets/heroWounded3.png"];
    }
}

-(void) displayFocusMode {
    if (self.damageReceived == 0) {
        self.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"assets/heroFocused.png"];
    } else if (self.damageReceived == 1) {
        self.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"assets/heroFocusedWounded1.png"];
    } else if (self.damageReceived == 2) {
        self.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"assets/heroFocusedWounded2.png"];
    } else if (self.damageReceived >= 3) {
        self.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"assets/heroFocusedWounded3.png"];
    }
}

-(void) applyDamage:(NSInteger)damage {
    self.damageReceived += damage;
    
    if (self.damageReceived > 0) {
        [self displayNormalMode];
    }
    
    if (self.damageReceived >= self.health) {
        [self die];
    }
}

-(void) die {
    self.isAlive = false;
    [self playDieAnimation];
    [self.handleHeroDelegate removeHero:self];
}

-(void) playDieAnimation {
    // Create the CCActions
    CCActionFadeOut *fadeAction = [CCActionFadeOut actionWithDuration:0.75];
    CCActionRemove *removeAction = [CCActionRemove action];
    
    // Play the CCAction animations to fade the hero
    CCActionSequence *sequenceAction = [CCActionSequence actionWithArray:@[fadeAction, removeAction]];
    [self runAction:sequenceAction];
}


#pragma mark NSCoding Delegates

-(id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Variables from CCSprite class
    self.position = [decoder decodeCGPointForKey:@"position"];
    // Variables from Hero class
    self.savedVelocity = [decoder decodeCGPointForKey:@"velocity"];
    self.ccbFileName = [decoder decodeObjectForKey:@"ccbFileName"];
    self.health = [decoder decodeIntegerForKey:@"health"];
    self.damageReceived = [decoder decodeIntegerForKey:@"damageReceived"];
    self.attackPower = [decoder decodeIntegerForKey:@"attackPower"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder {
    // Variables from CCSprite class
    [encoder encodeCGPoint:self.position forKey:@"position"];
    // Variables from Hero class
    self.savedVelocity = self.physicsBody.velocity;
    [encoder encodeCGPoint:self.savedVelocity forKey:@"velocity"];
    [encoder encodeObject:self.ccbFileName forKey:@"ccbFileName"];
    [encoder encodeInteger:self.health forKey:@"health"];
    [encoder encodeInteger:self.damageReceived forKey:@"damageReceived"];
    [encoder encodeInteger:self.attackPower forKey:@"attackPower"];
}

@end
