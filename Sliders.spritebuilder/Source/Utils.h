//
//  Utils.h
//  Sliders
//
//  Created by Maria Luisa on 4/1/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+(CGPoint) getVectorToMoveFromPoint:(CGPoint)origin ToPoint:(CGPoint)target withImpulse:(NSInteger)impulse;

@end
