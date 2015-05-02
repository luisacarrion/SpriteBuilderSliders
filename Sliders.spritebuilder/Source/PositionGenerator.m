//
//  IntersectedPathGenerator.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "PositionGenerator.h"

@implementation PositionGenerator {
    
}

-(instancetype) init {
    self.heroPositions = [NSMutableArray array];
    self.enemyPositions = [NSMutableArray array];
    
    self = [super init];
    return self;
}

-(CGPoint) getRandomPosition {
    NSInteger x = arc4random() % (self.screenWidth - self.characterWidth*2);
    NSInteger y = arc4random() % (self.screenHeight - self.characterHeight*2);
    // We don't want the characters to be completely in the border of the screen
    x += self.characterWidth;
    y += self.characterHeight;
    
    return ccp(x, y);
}

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


-(BOOL) character:(CCSprite*)c1 intersects:(CCSprite*)c2 {
    BOOL intersectX;
    BOOL intersectY;
    
    intersectX = (c1.position.x - c1.contentSize.width/2) <= c2.position.x
                    && c2.position.x <= (c1.position.x + c1.contentSize.width/2);
    intersectY = (c1.position.y - c1.contentSize.height/2) <= c2.position.y
    && c2.position.y <= (c1.position.y + c1.contentSize.height/2);
    
    if (intersectX && intersectY) {
        NSLog(@"Intersect!!!");
    }
    
    return intersectX && intersectY;
}





/*
 Methods not being used for now
 */
-(void) tempGeneratePaths:(NSInteger)amount {
    // Remove old positions to generate new ones
    self.heroPositions = [NSMutableArray array];
    self.enemyPositions = [NSMutableArray array];
    
    // Create new positions for heros and enemies
    for (int i = 0; i < amount; i++) {
        [self.heroPositions addObject:[NSValue valueWithCGPoint:[self getRandomPosition]]];
        [self.enemyPositions addObject:[NSValue valueWithCGPoint:[self getRandomPosition]]];
        
    }
}

-(void) generatePaths:(NSInteger)amount {
    self.intersectionPoint = [self getRandomPosition];
    NSMutableArray *pathAngles = [NSMutableArray array];
    NSMutableArray *oppositPathAngles = [NSMutableArray array];
    
    NSLog(@"randomOrigin: %@ *****************************", NSStringFromCGPoint(self.intersectionPoint));
    
    for (int i = 0; i < amount; i++) {
        double angle = [self getRandomPathAngle];
        // convert to radians
        angle = angle / 180 * M_PI;
        pathAngles[i] = [NSNumber numberWithDouble:angle];
        
        // convert to radians
    
        NSLog(@"angle %f", angle);
        
        
        
        
        
        
        CGPoint normalizedVector = ccpForAngle(angle);
        /*
        double rndVerticalCoordinate;
        
        if (normalizedVector.y > 0) {
            NSInteger max = self.screenHeight;
            int min = self.origin.y;
            
            rndVerticalCoordinate = (arc4random() % (max - min - self.characterHeight)) + 1;
            NSLog(@"rndVerticalCoordinate 1: %f", rndVerticalCoordinate);
            rndVerticalCoordinate = rndVerticalCoordinate - self.origin.y;
            
        } else {
            NSInteger max = self.origin.y;
            int min = 0;
            
            rndVerticalCoordinate = (arc4random() % (max - min - self.characterHeight)) + 1;
            NSLog(@"rndVerticalCoordinate 2: %f", rndVerticalCoordinate);
            rndVerticalCoordinate = self.origin.y - rndVerticalCoordinate;
        }
        
        NSLog(@"rndVerticalCoordinate: %f", rndVerticalCoordinate);
        */
        
        
        
        // Determine distance from origin to bounding box along the path angle
        NSInteger verticalDistanceFromOriginToTopOrBottom;
        
        if (normalizedVector.y > 0) {
            // Distance from origin to top
            verticalDistanceFromOriginToTopOrBottom = self.screenHeight - self.intersectionPoint.y;
            
        } else {
            // Distance from origin to bottom
            verticalDistanceFromOriginToTopOrBottom = self.intersectionPoint.y;
        }
        
        
        
        
        
        
        
        
        double tanResult = tan(angle);
        double distanceAlongPathAngle = verticalDistanceFromOriginToTopOrBottom / tanResult;
        
        //double rndHorizontalCoordinate = rndVerticalCoordinate / tanResult;
        //NSLog(@"rndHorizontalCoordinate: %f", rndHorizontalCoordinate);
        
        //double distanceAlongPathAngle = sqrt(rndVerticalCoordinate*rndVerticalCoordinate +
            //rndHorizontalCoordinate*rndHorizontalCoordinate);
        
        if (distanceAlongPathAngle < 0) {
            // We keep the distance positive because the angle will apply the negative vector if necessary
            distanceAlongPathAngle *= -1;
        }
        
        //NSLog(@"verticalDistanceFromOriginToTop: %ld", verticalDistanceFromOriginToTopOrBottom);
        NSLog(@"tanResult: %f", tanResult);
        //NSLog(@"pathAngles[%d] integerValue: %ld", i, [pathAngles[i] integerValue]);
        NSLog(@"distanceAlongPathAngle[%d]: %f", i, distanceAlongPathAngle);
        
        NSLog(@"normalizedVector[%d]: %@", i, NSStringFromCGPoint(normalizedVector));
        
        NSLog(@"self.heroPositions count: %lu", (unsigned long)[self.heroPositions count]);
        
        CGPoint mult = ccpMult(normalizedVector, distanceAlongPathAngle);
        
        // We have to add the origin because coordinates are given with the origin as reference
        mult = ccpAdd(mult, self.intersectionPoint);
        
        [self.heroPositions addObject:[NSValue valueWithCGPoint:mult]];
        
        
        
        
        //self.heroPositions[[self.heroPositions count]] =
        //[NSValue valueWithCGPoint:ccpMult(normalizedVector, distanceAlongPathAngle)];
        
        NSLog(@"self.heroPositions[%d]: %@", i, NSStringFromCGPoint(ccpMult(normalizedVector, distanceAlongPathAngle)));
        
        // Determine opposite angles (for enemies)
    }
    
    
    
}

/*
 Method not being used for now
 */
-(NSInteger) getRandomPathAngle {
    // Angle has to be between -90 and 90 to be above or below origin
    NSInteger rndAngle = (arc4random() % 180) + 1;
    NSLog(@"rndAngle: %ld", rndAngle);
    
    rndAngle -= 90;
    
    // 50% chance of being left or right of origin
    NSInteger rndLeftSide = arc4random() % 2;
    
    if (rndLeftSide == 1) {
        rndAngle += 180;
    }
    NSLog(@"final rndAngle: %ld", rndAngle);
    
    return rndAngle;
}

@end
