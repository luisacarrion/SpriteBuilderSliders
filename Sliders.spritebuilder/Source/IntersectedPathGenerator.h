//
//  IntersectedPathGenerator.h
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IntersectedPathGenerator : NSObject

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

@end
