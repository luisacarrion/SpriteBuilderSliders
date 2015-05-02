//
//  IntersectedPathGenerator.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "PositionGenerator.h"

@implementation PositionGenerator

-(CGPoint) getRandomPositionAvoidingHeroes:(NSArray*)heroes andEnemies:(NSArray*)enemies {
    bool intersectionFound = true;
    
    CGPoint p;
    
    while (intersectionFound == true) {
        intersectionFound = false;
        p = [self getRandomPosition];
        
        for (CCSprite *hero in heroes) {
            if ([self characterPosition:p intersects:hero]) {
                intersectionFound = true;
                NSLog(@"Intersect hero at x: %f y: %f", p.x, p.y);
            }
        }
        
        for (CCSprite *enemy in enemies) {
            if ([self characterPosition:p intersects:enemy]) {
                intersectionFound = true;
                NSLog(@"Intersect enemy at x: %f y: %f", p.x, p.y);
            }
        }
    }
    
    return p;
}

-(CGPoint) getRandomPosition {
    NSInteger x = arc4random() % (self.screenWidth - self.characterWidth*2);
    NSInteger y = arc4random() % (self.screenHeight - self.characterHeight*2);
    // We don't want the characters to be completely in the border of the screen
    x += self.characterWidth;
    y += self.characterHeight;
    
    return ccp(x, y);
}

-(BOOL) characterPosition:(CGPoint)c1 intersects:(CCSprite*)c2 {
    BOOL intersectX;
    BOOL intersectY;
    
    // We assume that the size of character 1 will be the same as the size of character 2
    CGFloat c1Left = c1.x - c2.contentSize.width/2;
    CGFloat c1Right = c1.x + c2.contentSize.width/2;
    CGFloat c1Bottom = c1.y - c2.contentSize.height/2;
    CGFloat c1Top = c1.y + c2.contentSize.height/2;
    
    CGFloat c2Left = c2.position.x - c2.contentSize.width/2;
    CGFloat c2Right = c2.position.x + c2.contentSize.width/2;
    CGFloat c2Bottom = c2.position.y - c2.contentSize.height/2;
    CGFloat c2Top = c2.position.y + c2.contentSize.height/2;
    
    intersectX = (c1Left <= c2Right) && (c1Right >= c2Left);
    intersectY = (c1Bottom <= c2Top) && (c1Top >= c2Bottom);
    
    return intersectX && intersectY;
}

@end
