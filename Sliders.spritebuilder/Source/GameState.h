//
//  GameState.h
//  Sliders
//
//  Created by Maria Luisa on 3/30/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@property (nonatomic, assign) GameStateLabel gameState;
@property (nonatomic, assign) NSInteger currentLevel;
@property (nonatomic, assign) NSInteger currentStep;
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
@property (nonatomic, assign) NSInteger score;

+(id)sharedInstance;

@end
