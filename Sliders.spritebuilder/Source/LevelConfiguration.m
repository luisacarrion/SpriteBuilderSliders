//
//  LevelConfiguration.m
//  Sliders
//
//  Created by Maria Luisa on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "LevelConfiguration.h"

NSString * const KEY_TOTAL_ENEMIES = @"total_Enemies";
NSString * const KEY_STEP_BASIC_ENEMIES_SPAWNED = @"step_BasicEnemiesSpawned";
NSString * const KEY_START_HEROES_SPAWNED = @"start_HeroesSpawned";

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
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"LevelConfiguration" ofType:@"plist"];
    
    NSArray *arrayOfLevels = [NSArray arrayWithContentsOfFile:plistPath];
    
    NSLog(@"plist[0] %@", arrayOfLevels[0]);
    
    return arrayOfLevels;
}



@end
