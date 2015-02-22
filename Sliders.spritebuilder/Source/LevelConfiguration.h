//
//  LevelConfiguration.h
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const KEY_HEROES_SPAWNED_AT_LOAD;
extern NSString * const KEY_TOTAL_ENEMIES;
extern NSString * const KEY_ENEMIES_SPAWNED_PER_STEP;
extern NSString * const KEY_ENEMY_TYPE1;

@interface LevelConfiguration : NSObject

-(NSString*) get:(NSString*)key forLevel:(NSInteger)level;
-(NSInteger) getLevelsCount;

@end
