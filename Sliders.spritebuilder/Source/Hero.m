//
//  Hero.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Hero.h"
#import "MainScene.h"

static const NSInteger INITIAL_DAMAGE = 1;

@implementation Hero

- (void) didLoadFromCCB {
    // Set physics properties
    self.physicsBody.collisionType = @"hero";
    
    // Set drawing order
    self.zOrder = DrawingOrderHero;
    
    // Set initial damage
    self.damage = INITIAL_DAMAGE;
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
    self.damage = [decoder decodeIntegerForKey:@"damage"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder {
    // Variables from CCSprite class
    [encoder encodeCGPoint:self.position forKey:@"position"];
    // Variables from Hero class
    self.savedVelocity = self.physicsBody.velocity;
    [encoder encodeCGPoint:self.savedVelocity forKey:@"velocity"];
    [encoder encodeObject:self.ccbFileName forKey:@"ccbFileName"];
    [encoder encodeInteger:self.damage forKey:@"damage"];
}

@end
