//
//  GameState.m
//  Sliders
//
//  Created by Maria Luisa on 3/30/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "GameState.h"
#import "Hero.h"
#import "Enemy.h"

static NSString *KEY_GAME_STATE_LABEL = @"keyGameStateLabel";
static NSString *KEY_CURRENT_LEVEL = @"keyCurrentLevel";
static NSString *KEY_HEROES_ARRAY = @"keyHeroesArray";
static NSString *KEY_HEROES_ARE_MOVING = @"keyHeroesAreMoving";
static NSString *KEY_ENEMIES_ARRAY = @"keyEnemiesArray";
static NSString *KEY_NUMBER_OF_KILLS_IN_LEVEL = @"keyNumberOfKillsInLevel";
static NSString *KEY_NUMBER_OF_KILLS_IN_TOTAL = @"keyNumberOfKillsInTotal";
static NSString *KEY_NUMBER_OF_KILLS_IN_TOUCH = @"keyNumberOfKillsInTouch";
static NSString *KEY_SCORE = @"keyScore";

@implementation GameState

+(id)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

-(void)saveStateInUserDefaults {
    NSUserDefaults *u = [NSUserDefaults standardUserDefaults];
    
    [u setInteger:self.gameState forKey:KEY_GAME_STATE_LABEL];
    [u setInteger:self.currentLevel forKey:KEY_CURRENT_LEVEL];
    
    NSData *heroesData = [NSKeyedArchiver archivedDataWithRootObject:self.heroes];
    [u setObject:heroesData forKey:KEY_HEROES_ARRAY];
    
    [u setBool:self.heroesAreMoving forKey:KEY_HEROES_ARE_MOVING];
    
    NSData *enemiesData = [NSKeyedArchiver archivedDataWithRootObject:self.enemies];
    [u setObject:enemiesData forKey:KEY_ENEMIES_ARRAY];
    
    [u setInteger:self.numberOfKillsInLevel forKey:KEY_NUMBER_OF_KILLS_IN_LEVEL];
    [u setInteger:self.numberOfKillsInTotal forKey:KEY_NUMBER_OF_KILLS_IN_TOTAL];
    [u setInteger:self.numberOfKillsInTouch forKey:KEY_NUMBER_OF_KILLS_IN_TOUCH];
    [u setInteger:self.score forKey:KEY_SCORE];
}

-(void)loadStateFromUserDefaults {
    NSUserDefaults *u = [NSUserDefaults standardUserDefaults];
    
    self.gameState = [u integerForKey:KEY_GAME_STATE_LABEL];
    
    self.currentLevel = [u integerForKey:KEY_CURRENT_LEVEL];
    if (self.currentLevel == 0) {
        self.currentLevel = 1;
    }
    
    NSData *heroesData = [u objectForKey:KEY_HEROES_ARRAY];
    self.heroes = [NSKeyedUnarchiver unarchiveObjectWithData:heroesData];
    if (self.heroes == nil) {
        self.heroes = [NSMutableArray array];
    }
    
    self.heroesAreMoving = [u boolForKey:KEY_HEROES_ARE_MOVING];
    
    NSData *enemiesData = [u objectForKey:KEY_ENEMIES_ARRAY];
    self.enemies = [NSKeyedUnarchiver unarchiveObjectWithData:enemiesData];
    if (self.enemies == nil) {
        self.enemies = [NSMutableArray array];
    }
    
    self.numberOfKillsInLevel = [u integerForKey:KEY_NUMBER_OF_KILLS_IN_LEVEL];
    self.numberOfKillsInTotal = [u integerForKey:KEY_NUMBER_OF_KILLS_IN_TOTAL];
    self.numberOfKillsInTouch = [u integerForKey:KEY_NUMBER_OF_KILLS_IN_TOUCH];
    self.score = [u integerForKey:KEY_SCORE];
}

-(void)resetState {
    self.gameState = GameNotStarted;
    
    self.currentLevel = 1;
    
    self.heroes = [NSMutableArray array];
    
    self.heroesAreMoving = FALSE;
    
    self.enemies = [NSMutableArray array];
    self.numberOfKillsInLevel = 0;
    self.numberOfKillsInTotal = 0;
    self.numberOfKillsInTouch = 0;
    self.score = 0;
}

@end
