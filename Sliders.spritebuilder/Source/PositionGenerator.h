//
//  IntersectedPathGenerator.h
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 The position generator generates positions for all objects that should be placed in the map: soldiers, enemies, power ups, obstacles
 */
@interface PositionGenerator : NSObject

@property (nonatomic, assign) NSInteger screenWidth;
@property (nonatomic, assign) NSInteger screenHeight;
@property (nonatomic, assign) NSInteger characterWidth;
@property (nonatomic, assign) NSInteger characterHeight;
@property (nonatomic, assign) CGPoint intersectionPoint;
@property (nonatomic, retain) NSMutableArray *heroPositions;
@property (nonatomic, retain) NSMutableArray *enemyPositions;

-(void) generatePaths:(NSInteger)amount;

// Temporary while the other method is developed
-(void) tempGeneratePaths:(NSInteger)amount;
-(CGPoint) getRandomPosition;
-(CGPoint) getRandomPositionAvoidingHeroes:(NSArray*)heroes andEnemies:(NSArray*)enemies;

@end
