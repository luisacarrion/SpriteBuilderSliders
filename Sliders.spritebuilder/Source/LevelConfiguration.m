//
//  LevelConfiguration.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "LevelConfiguration.h"

NSString * const KEY_TOTAL_ENEMIES = @"KeyTotalEnemies";
NSString * const KEY_BASIC_ENEMIES_SPAWNED_PER_STEP = @"KeyBasicEnemiesSpawnedPerStep";
NSString * const KEY_HEROES_SPAWNED_AT_LOAD = @"KeyHeroesSpawnedAtLoad";

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
    /* Levels have steps. Which means, one level has various stages.
        For example, if in level 1 you have to kill 6 enemies to pass to level 2, then those 6 enemies won't appear in the map at once;They will apper 2 enemies per step.
     This means that level 1 would have 3 steps: every step spawns 2 enemies. A new step is loaded evey time the user kills all the enemies in the current step.*/
    NSLog(@"KeyTotalEnemies: %@", KEY_TOTAL_ENEMIES);
    NSLog(@"KeyTotalEnemies: %@", KEY_BASIC_ENEMIES_SPAWNED_PER_STEP);
    return [NSArray arrayWithObjects:
            // Level 1
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"2", KEY_HEROES_SPAWNED_AT_LOAD,
             @"4", KEY_TOTAL_ENEMIES,
             @"2", KEY_BASIC_ENEMIES_SPAWNED_PER_STEP,
             nil
             ],
            // Level 2
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"0", KEY_HEROES_SPAWNED_AT_LOAD,
             @"6", KEY_TOTAL_ENEMIES,
             @"3", KEY_BASIC_ENEMIES_SPAWNED_PER_STEP,
             nil
             ],
            nil];
}



@end
