//
//  LevelConfiguration.h
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const KEY_START_HEROES_SPAWNED;
extern NSString * const KEY_TOTAL_ENEMIES;
extern NSString * const KEY_STEP_BASIC_ENEMIES_SPAWNED;

@interface LevelConfiguration : NSObject

-(NSString*) get:(NSString*)key forLevel:(NSInteger)level;
-(NSInteger) getLevelsCount;

@end
