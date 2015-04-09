//
//  GameState.h
//  Sliders
//
//  Created by Maria Luisa on 3/30/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Enemy.h"
#import "Hero.h"

// Enum type = NSInteger
// Enum name = GameState
typedef NS_ENUM(NSInteger, GameStateLabel) {
    GameNotStarted,
    GameRunning,
    GamePaused,
    GameOver,
    GameRunningAgain
};

@interface GameState : NSObject

// Properties to save when the game is finished
@property (nonatomic, assign) GameStateLabel gameState;
@property (nonatomic, assign) NSInteger currentLevel;
// Holds all the heroes in the level
@property (nonatomic, retain) NSMutableArray *heroes;
@property (nonatomic, assign) BOOL heroesAreMoving;
// Holds all the enemies in the level
@property (nonatomic, retain) NSMutableArray *enemies;
// Amount of enemies eliminated in the current level
@property (nonatomic, assign) NSInteger numberOfKillsInLevel;
// Amount of enemies eliminated in total (in all the levels)
@property (nonatomic, assign) NSInteger numberOfKillsInTotal;
// Amount of enemies eliminated with a single touch
@property (nonatomic, assign) NSInteger numberOfKillsInTouch;
// Amount of enemies that collisioned with a hero (even if they were not killed)
@property (nonatomic, assign) NSInteger numberOfCollisionsWithEnemiesInTouch;
@property (nonatomic, assign) NSInteger score;

// Properties that don't need to be saved when the game is finished
@property (nonatomic, assign) CCTime secondsSinceHeroKilledEnemy;
@property (nonatomic, assign) BOOL enemiesAreAttacking;

// Sharing, saving and loadindg the game state
+(id)sharedInstance;
-(void)saveStateInUserDefaults;
-(void)loadStateFromUserDefaults;
-(void)resetState;

// Querying the game state when the game is running
-(Hero*)getRandomHero;
-(Enemy*)getRandomEnemy;
-(BOOL)areHeroesOnFocusMode;
-(BOOL)areEnemiesOnRevengeMode;

@end
