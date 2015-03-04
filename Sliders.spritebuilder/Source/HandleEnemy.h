//
//  HandleEnemy.h
//  Sliders
//
//  Created by Maria Luisa on 3/4/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

// the @class keyword informs the compiler that the Enemy class will soon come along.
// This is necessary because there is a circular references between Enemy and HandleEnemy
@class Enemy;

@protocol HandleEnemy <NSObject>

-(void) removeEnemy:(Enemy*)enemy;

@end
