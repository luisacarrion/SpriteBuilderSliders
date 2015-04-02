//
//  Utils.m
//  Sliders
//
//  Created by Maria Luisa on 4/1/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+(CGPoint) getVectorToMoveFromPoint:(CGPoint)origin ToPoint:(CGPoint)target withImpulse:(NSInteger)impulse {
    // Determine direction of the impulse
    double impulseX = target.x - origin.x;
    double impulseY = target.y - origin.y;
    
    // Get the x and y components of the impulse
    CGPoint normalizedImpulse = ccpNormalize(ccp(impulseX, impulseY));
    impulseX = normalizedImpulse.x * impulse;
    impulseY = normalizedImpulse.y * impulse;
    
    return ccp(impulseX, impulseY);
}

@end
