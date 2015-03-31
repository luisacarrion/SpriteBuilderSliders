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

-(void) applyDamage:(NSInteger)damage {
    self.damageReceived += damage;
    if (self.damageReceived >= self.health) {
        [self die];
    }
}

-(void) die {
    [self.handleHeroDelegate removeHero:self];
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
