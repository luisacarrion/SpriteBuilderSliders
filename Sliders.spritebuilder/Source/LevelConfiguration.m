//
//  LevelConfiguration.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "LevelConfiguration.h"

NSString * const KEY_TOTAL_ENEMIES = @"KeyTotalEnemies";
NSString * const KEY_ENEMIES_SPAWNED_PER_STEP = @"KeyEnemiesSpawnedAtOnce";
NSString * const KEY_HEROES_SPAWNED_AT_LOAD = @"KeyHeroesSpawnedAtOnce";
NSString * const KEY_ENEMY_TYPE1 = @"keyEnemyType1";

@implementation LevelConfiguration {
    NSArray *_levelConfigurations;
}


-(instancetype) init {
    _levelConfigurations = [self getLevelConfigurations];
    
    self = [super init];
    return self;
}


-(NSString*) get:(NSString*)key forLevel:(NSInteger)level {
    return _levelConfigurations[level - 1][key];
}

-(NSInteger) getLevelsCount {
    return [_levelConfigurations count];
}

-(NSArray*) getLevelConfigurations {
    // Each level is a dictionary with the level parameters
    NSLog(@"KeyTotalEnemies: %@", KEY_TOTAL_ENEMIES);
    NSLog(@"KeyTotalEnemies: %@", KEY_ENEMIES_SPAWNED_PER_STEP);
    return [NSArray arrayWithObjects:
            // Level 1
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"2", KEY_HEROES_SPAWNED_AT_LOAD,
             @"4", KEY_TOTAL_ENEMIES,
             @"2", KEY_ENEMIES_SPAWNED_PER_STEP,
             @"EnemyBasic", KEY_ENEMY_TYPE1,
             nil
             ],
            // Level 2
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"0", KEY_HEROES_SPAWNED_AT_LOAD,
             @"6", KEY_TOTAL_ENEMIES,
             @"3", KEY_ENEMIES_SPAWNED_PER_STEP,
             @"EnemyBasic", KEY_ENEMY_TYPE1,
             nil
             ],
            nil];
}



@end
