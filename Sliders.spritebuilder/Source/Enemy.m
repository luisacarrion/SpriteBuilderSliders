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

-(void) applyDamage:(NSInteger)damage {
    self.damageReceived += damage;
    if (self.damageReceived >= self.damageLimit) {
        [self die];
    }
}

-(void) die {
    [self.handleEnemyDelegate removeEnemy:self];
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
    self.damageReceived = [decoder decodeIntegerForKey:@"damageReceived"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder {
    // Variables from CCSprite class
    [encoder encodeCGPoint:self.position forKey:@"position"];
    // Variables from Enemy class
    [encoder encodeObject:self.ccbFileName forKey:@"ccbFileName"];
    [encoder encodeInteger:self.damageReceived forKey:@"damageReceived"];
}

@end

