#import "Enemy.h"
#import "Hero.h"
#import "PositionGenerator.h"
#import "LevelConfiguration.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "MainScene.h"

// Enum type = NSInteger
// Enum name = GameState
typedef NS_ENUM(NSInteger, GameState) {
    GameNotStarted,
    GameRunning,
    GamePaused,
    GameOver,
    GameRunningAgain
};


// Game constants
static const NSInteger CHARACTER_WIDTH = 100;
static const NSInteger CHARACTER_HEIGHT = 100;
static const NSString *KEY_GAME_STATE = @"keyGameState";
static const NSString *KEY_TOP_SCORES = @"keyTopScores";

@implementation MainScene {
    
    // CCNodes - code connections with SpriteBuilder
    CCPhysicsNode *_physicsNode;
    CCLabelTTF *_lblScore;
    CCButton *_btnPause;
    // CCNodes of the Score ccb file
    CCLabelTTF *_lblYourFinalScore;
    CCLabelTTF *_lblTopScores;
    
    // Game variables
    GameState _gameState;
    NSInteger _currentLevel;
    NSMutableArray *_heroes;  // Holds all the heroes in the level
    NSMutableArray *_enemies;  // Holds all the enemies in the level
    NSInteger _numberOfKillsInLevel;  // Amount of enemies eliminated in the current level
    NSInteger _numberOfKillsInTotal;  // Amount of enemies eliminated in total (in all the levels)
    NSInteger _numberOfKillsInTouch;  // Amount of enemies eliminated with a single touch
    NSInteger _score;
    
    // Helper objects
    PositionGenerator *_pathGenerator;  // Generates positions for new enemies and power ups
    LevelConfiguration *_levelConfig;  // Holds configurations of all the levels
    
}

#pragma mark Node Lifecycle

- (void) didLoadFromCCB {
    // Initialize game variables
    _gameState = [self getGameStateFromUserDefaults];
    _currentLevel = [self getCurrentLevel];
    _heroes = [NSMutableArray array];
    _enemies = [NSMutableArray array];

    // Initialize helper objects
    _levelConfig = [[LevelConfiguration alloc] init];
    _pathGenerator = [[PositionGenerator alloc] init];
    _pathGenerator.screenWidth = [CCDirector sharedDirector].viewSize.width;
    _pathGenerator.screenHeight = [CCDirector sharedDirector].viewSize.height;
    _pathGenerator.characterWidth = CHARACTER_WIDTH;
    _pathGenerator.characterHeight = CHARACTER_HEIGHT;
    
    // Set collisions delegate
    _physicsNode.collisionDelegate = self;
    
    // Load appropriate overlay screen depending on game state
    NSLog(@"gameState: @%ld", _gameState);
    if (_gameState == GameNotStarted) {
        [self loadOverlay:@"Title"];
    } else if (_gameState == GameRunningAgain) {
        [self startGame];
    } else if (_gameState == GamePaused || _gameState == GameRunning) {
        [self startGame];
        [self loadOverlay:@"Pause"];
    }
    
    
    //_physicsNode.debugDraw = true;
    
}

-(void) update:(CCTime)delta {
    if (_gameState == GameRunning) {
        
        if ([self isLevelCompleted]) {
            // Load next level
            if (![self loadNextLevel]) {
                // If the next level couldn't be loaded (because there were no more levels), end the game
                [self endGame];
            }
        } else {
            // If level is not completed but there are not more enemies to kill, load the next step of the level
            if ([_enemies count] == 0) {
                // The next step of the level will spawn new enemies
                [self loadNextStepOfLevel:_currentLevel isFirstStep:NO];
            }
        }
        
    }
}

#pragma mark User Input Events

-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    CGPoint touchLocation = [touch locationInNode: self];
    _numberOfKillsInTouch = 0;
    [self impulseHeroesToPoint:touchLocation];
}

#pragma mark Level loading

- (NSInteger) getCurrentLevel {
    // TODO: Add logic to check from the NSUserDefaults if there is a level saved
    return 1;
}

-(BOOL) isLevelCompleted {
    BOOL levelCompleted = false;
    
    NSInteger enemiesForNextLevel =
            [[_levelConfig get:KEY_TOTAL_ENEMIES forLevel:_currentLevel] integerValue];
    
    if (_numberOfKillsInLevel >= enemiesForNextLevel) {
        levelCompleted = true;
    }
    
    return levelCompleted;
}

-(BOOL) loadNextLevel {
    BOOL nextLevelLoaded = false;
    _currentLevel++;
    if (_currentLevel <= [_levelConfig getLevelsCount]) {
        // If there are more levels, load next level
        [self loadLevel:_currentLevel];
        nextLevelLoaded = true;
    }
    return nextLevelLoaded;
}

/* Load the level passed as argument. Loading the level implies: spawning the enemies, spawning power ups and spawning other objects defined in the LevelConfiguration.m file */
- (void) loadLevel:(NSInteger)level {

    // Reset the number of enemies killed per level
    _numberOfKillsInLevel = 0;
    
    // Load the first step of the level
    [self loadNextStepOfLevel:level isFirstStep:YES];
}

// A new step of the level is loaded when the user kills all the enemies in the current step
-(void) loadNextStepOfLevel:(NSInteger)level isFirstStep:(BOOL)isFirstStep {
    NSLog(@"nextStepOfLevel: %ld, isFirstStep %d", level, isFirstStep);
    
    // Spawn heroes
    if (isFirstStep) {
        // Heroes are spawned only at the beginning of each level (in the first step)
        NSInteger heroesToSpawn = [[_levelConfig get:KEY_START_HEROES_SPAWNED forLevel:_currentLevel] integerValue];
        for (int i = 0; i < heroesToSpawn; i++) {
            [self spawnHero];
        }
    }

    // Spawn enemies
    NSInteger basicEnemiesToSpawn = [[_levelConfig get:KEY_STEP_BASIC_ENEMIES_SPAWNED forLevel:_currentLevel] integerValue];
    for (int i = 0; i < basicEnemiesToSpawn; i++) {
        [self spawnEnemyOfType:@"EnemyBasic"];
    }

}

#pragma mark Heroes and Enemies Handling

-(void) spawnHero {
    Hero *hero = (Hero *) [CCBReader load:@"Hero"];
    [_heroes addObject:hero];
    [_physicsNode addChild:hero];
    
    hero.position = [_pathGenerator getRandomPosition];
}

-(void) spawnEnemyOfType:(NSString*)enemyType {
    Enemy *enemy = (Enemy *) [CCBReader load:enemyType];
    [_enemies addObject:enemy];
    [_physicsNode addChild:enemy];
    
    enemy.position = [_pathGenerator getRandomPosition];
    enemy.handleEnemyDelegate = self;
}

-(void) impulseHeroesToPoint:(CGPoint)point {
    for (Hero *hero in _heroes) {
        double impulseX = point.x - hero.position.x;
        double impulseY = point.y - hero.position.y;
        
        [hero.physicsBody  applyImpulse:ccp(impulseX, impulseY)];
    }
}

#pragma mark HandleEnemy Delegate

-(void) removeEnemy:(Enemy *)enemy {
    [enemy removeFromParent];
    [_enemies removeObject:enemy];
    
    // Increment enemies killed counters
    _numberOfKillsInTouch++;
    _numberOfKillsInLevel++;
    _numberOfKillsInTotal++;
    
    // Calculate obtained score for killing this enemy
    NSInteger scoreObtained = enemy.damageLimit * _numberOfKillsInTouch;
    
    [self showMessage:scoreObtained forEnemyWithPosition:enemy.position];
    
    [self incrementScoreBy:scoreObtained];
}

#pragma mark Collision Delegates

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero1 hero:(CCNode*)hero2 {
    // Ignore hero collisions so that they can pass through each other
    return NO;
}

-(BOOL)ccPhysicsCollisionSeparate:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero enemy:(CCNode*)enemy {
    if (_gameState == GameRunning) {
        // After the physics engine step ends, remove the enemy and increment the score
        [[_physicsNode space] addPostStepBlock:^{
            [(Enemy*)enemy applyDamage:((Hero*)hero).damage];
        }key:enemy];
        
    }
    return YES;
}

#pragma mark Score Calculation and Presentation

-(void) showMessage:(NSInteger)scoreObtained forEnemyWithPosition:(CGPoint)position {
    CCLabelTTF *lblScoreObtained = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"+%ld", scoreObtained] fontName:@"Helvetica" fontSize:16];
    
    lblScoreObtained.position = position;
    [self addChild:lblScoreObtained];
    
    CCActionFadeOut *fadeAction = [CCActionFadeOut actionWithDuration:0.75];
    CCActionMoveBy *moveUpAction = [CCActionMoveBy actionWithDuration:0.75 position:ccp(0, 10)];
    CCActionRemove *removeAction = [CCActionRemove action];
    
    CCActionSpawn *spawnAction = [CCActionSpawn actionWithArray:@[fadeAction, moveUpAction]];
    CCActionSequence *sequenceAction = [CCActionSequence actionWithArray:@[spawnAction, removeAction]];
    
    [lblScoreObtained runAction:sequenceAction];
}

-(void) incrementScoreBy:(NSInteger)amount {
    _score += amount;
    _lblScore.string = [NSString stringWithFormat:@"%ld", _score];
}

-(NSArray*) getUpdatedTopScores {
    int MAX_TOP_SCORES = 5;
    
    // Get saved top scores
    NSArray *topScores =  [[NSUserDefaults standardUserDefaults] objectForKey:KEY_TOP_SCORES];
    
    // Insert the current _score as a top score, if applicable
    NSMutableArray *newTopScores = [NSMutableArray arrayWithArray:topScores];
    if ([newTopScores count] == 0) {
        // Add the score if we don't have previous top score
        newTopScores[0] = [NSNumber numberWithInteger:_score];
    } else {
        BOOL scoreAdded = FALSE;
        
        // If the _score is greater than a previously saved top score, we add it
        for (int i = 0; i < MAX_TOP_SCORES; i++) {
            if (_score >= [(NSNumber*)newTopScores[i] integerValue]) {
                [newTopScores insertObject:[NSNumber numberWithInteger:_score] atIndex:i];
                scoreAdded = TRUE;
                break;
            }
        }
        
        // If we still don't have the MAX_TOP_SCORES amount, and the score wasn't added, we add it
        if (!scoreAdded && [newTopScores count] < MAX_TOP_SCORES) {
            [newTopScores addObject:[NSNumber numberWithInteger:_score]];
        }
    }
    
    // Keep the scores to the MAX_TOP_SCORES amount
    while ([newTopScores count] > MAX_TOP_SCORES) {
        [newTopScores removeLastObject];
    }
    
    // Save the new top scores
    [[NSUserDefaults standardUserDefaults] setObject:newTopScores forKey:KEY_TOP_SCORES];
    
    return newTopScores;
}


#pragma mark Overlays Handling

-(CCNode*) loadOverlay:(NSString*)ccbFile {
    CCNode *overlayScreen = [CCBReader load:ccbFile owner:self];
    overlayScreen.positionType = CCPositionTypeNormalized;
    overlayScreen.position = ccp(0.5, 0.5);
    overlayScreen.anchorPoint = ccp(0.5, 0.5);
    [self addChild:overlayScreen];
    return overlayScreen;
}

// Method called from the Title.ccb file
-(void) play {
    [self startGame];
    
    [self removeChildByName:@"Title"];
}

// Method called from the MainScene.ccb file
-(void) pause {
    [self setGameState:GamePaused];
    
    _btnPause.visible = FALSE;
    
    [self loadOverlay:@"Pause"];
    
    // Pause the game
    [[CCDirector sharedDirector] pause];
}

// Method called from the Pause.ccb file
-(void) resume {
    [self setGameState:GameRunning];
    [self removeChildByName:@"Pause"];
    _btnPause.visible = TRUE;
    // Resume the game
    [[CCDirector sharedDirector] resume];
}

// Method called from the Score.ccb file
// Method called from the Pause.ccb file
-(void) playAgain {
    [self setGameState:GameRunningAgain];
    
    // This check is necessary because this method can be called from a paused state
    if ([CCDirector sharedDirector].paused) {
        [[CCDirector sharedDirector] resume];
    }
    
    // Reload the game
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"MainScene"]];
}

// Method called from the Score.ccb file
// Method called from the Pause.ccb file
-(void) home {
    [self setGameState:GameNotStarted];
    
    // This check is necessary because this method can be called from a paused state
    if ([CCDirector sharedDirector].paused) {
        [[CCDirector sharedDirector] resume];
    }
    
    // Reload the game
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"MainScene"]];
}

#pragma mark Game State Handling

-(GameState) getGameStateFromUserDefaults {
    GameState state = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_GAME_STATE];
    return state;
}

-(void) setGameState:(GameState)state {
    _gameState = state;
    NSLog(@"gameState: @%ld", _gameState);
    [[NSUserDefaults standardUserDefaults] setInteger:_gameState forKey:KEY_GAME_STATE];
}

-(void) startGame {
    // Load the first level
    [self loadLevel:_currentLevel];
    _lblScore.visible = TRUE;
    _btnPause.visible = TRUE;
    
    // Enable user interaction
    self.userInteractionEnabled = TRUE;
    
    [self setGameState:GameRunning];
}

-(void) endGame {
    [self setGameState:GameNotStarted];
    self.userInteractionEnabled = FALSE;
    
    [self loadOverlay:@"Score"];
    
    // Show the player's score
    _lblYourFinalScore.string = [NSString stringWithFormat:@"%ld", _score];
    
    // Show the top scores
    NSArray *topScores = [self getUpdatedTopScores];
    NSMutableString *topScoresString = [NSMutableString stringWithString:@""];
    for (NSNumber *topScore in topScores) {
        [topScoresString appendString: [NSString stringWithFormat:@"%ld\n", [topScore integerValue]]];
    }
    _lblTopScores.string = topScoresString;
}

@end

