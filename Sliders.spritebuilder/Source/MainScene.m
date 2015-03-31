#import "GameState.h"
#import "Enemy.h"
#import "Hero.h"
#import "PositionGenerator.h"
#import "LevelConfiguration.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "MainScene.h"


// Game constants
static const NSInteger CHARACTER_WIDTH = 100;
static const NSInteger CHARACTER_HEIGHT = 100;
static const NSString *KEY_GAME_STATE = @"keyGameState";
static const NSString *KEY_TOP_SCORES = @"keyTopScores";
static const NSInteger HERO_IMPULSE = 180;
static const NSInteger HERO_VEL_REDUCTION_WITH_ENEMIES = 1;
static const NSInteger HERO_VEL_REDUCTION_WITHOUT_ENEMIES = 10;

@implementation MainScene {
    
    // CCNodes - code connections with SpriteBuilder
    CCPhysicsNode *_physicsNode;
    CCLabelTTF *_lblScore;
    CCButton *_btnPause;
    // CCNodes of the Score ccb file
    CCLabelTTF *_lblYourFinalScore;
    CCLabelTTF *_lblTopScores;
    
    // Game variables
    GameState *g;
    
    // Helper objects
    PositionGenerator *_pathGenerator;  // Generates positions for new enemies and power ups
    LevelConfiguration *_levelConfig;  // Holds configurations of all the levels
    
}

#pragma mark Node Lifecycle

- (void) didLoadFromCCB {
    // Initialize game variables
    g = [GameState sharedInstance];
    
    g.gameState = [self getGameStateLabelFromUserDefaults];
    g.currentLevel = [self getCurrentLevel];
    g.heroes = [NSMutableArray array];
    g.enemies = [NSMutableArray array];

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
    NSLog(@"gameState: @%ld", g.gameState);
    if (g.gameState == GameNotStarted) {
        [self loadOverlay:@"Title"];
    } else if (g.gameState == GameRunningAgain) {
        [self startGame];
    } else if (g.gameState == GamePaused || g.gameState == GameRunning) {
        [self startGame];
        [self setGameStateLabel:GamePaused];
        [self loadOverlay:@"Pause"];
    }
    
    
    //_physicsNode.debugDraw = true;
    
}

-(void) update:(CCTime)delta {
    if (g.gameState == GameRunning) {
        // Load next levels when heroes stop moving
        if (!g.heroesAreMoving) {
            if ([self isLevelCompleted]) {
                // Load next level
                if (![self loadNextLevel]) {
                    // If the next level couldn't be loaded (because there were no more levels), end the game
                    [self endGame];
                }
            } else {
                // If level is not completed but there are not more enemies to kill, load the next step of the level
                if ([g.enemies count] == 0) {
                    // The next step of the level will spawn new enemies
                    [self loadNextStepOfLevel:g.currentLevel isFirstStep:NO];
                }
            }
        }
    }
}

-(void) fixedUpdate:(CCTime)delta {
    // Use fixed update to update the velocity, because fixedUpdate is updated with the physics engine
    if (g.gameState == GameRunning) {
        // Slow heroes down (to simulate friction), otherwise they would keep moving for ever
        if ([g.enemies count] == 0) {
            // If all enemies have been killed, stop heroes faster, so the next level can be loaded sooner
            [self reduceHeroesVelocityByAmount:HERO_VEL_REDUCTION_WITHOUT_ENEMIES];
        } else {
            [self reduceHeroesVelocityByAmount:HERO_VEL_REDUCTION_WITH_ENEMIES];
        }
    }
}

#pragma mark User Input Events

-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if (g.gameState == GameRunning) {
        CGPoint touchLocation = [touch locationInNode: self];
        g.numberOfKillsInTouch = 0;

        // Stop heroes that are moving, so they are moved in the new direction
        for (Hero *hero in g.heroes) {
            hero.physicsBody.velocity = ccp(0, 0);
        }
    
        [self impulseHeroesToPoint:touchLocation withImpulse:HERO_IMPULSE];
    }
}

#pragma mark Level loading

- (NSInteger) getCurrentLevel {
    // TODO: Add logic to check from the NSUserDefaults if there is a level saved
    return 1;
}

-(BOOL) isLevelCompleted {
    BOOL levelCompleted = false;
    
    NSInteger enemiesForNextLevel =
            [[_levelConfig get:KEY_TOTAL_ENEMIES forLevel:g.currentLevel] integerValue];

    // Level is completed when the amount of enemies killed so far is equal or greater than the amount of enemies needed for next level
    if (g.numberOfKillsInLevel >= enemiesForNextLevel) {
        levelCompleted = true;
    }
    
    return levelCompleted;
}

-(BOOL) loadNextLevel {
    BOOL nextLevelLoaded = false;
    g.currentLevel++;
    if (g.currentLevel <= [_levelConfig getLevelsCount]) {
        // If there are more levels, load next level
        [self loadLevel:g.currentLevel];
        nextLevelLoaded = true;
    }
    return nextLevelLoaded;
}

/* Load the level passed as argument. Loading the level implies: spawning the enemies, spawning power ups and spawning other objects defined in the LevelConfiguration.m file */
- (void) loadLevel:(NSInteger)level {
    // Reset the number of enemies killed per level
    g.numberOfKillsInLevel = 0;
    
    // Load the first step of the level
    [self loadNextStepOfLevel:level isFirstStep:YES];
}

// A new step of the level is loaded when the user kills all the enemies in the current step
-(void) loadNextStepOfLevel:(NSInteger)level isFirstStep:(BOOL)isFirstStep {
    NSLog(@"nextStepOfLevel: %ld, isFirstStep %d", level, isFirstStep);
    // Spawn heroes
    if (isFirstStep) {
        // The first step is step 0
        g.currentStep = 0;
        // Heroes are spawned only at the beginning of each level (in the first step)
        NSInteger heroesToSpawn = [[_levelConfig get:KEY_START_HEROES_SPAWNED forLevel:g.currentLevel] integerValue];
        for (int i = 0; i < heroesToSpawn; i++) {
            [self spawnHero];
        }
    } else {
        // Update the game state with the current step of the level being loaded
        g.currentStep++;
    }

    // Spawn enemies
    NSInteger basicEnemiesToSpawn = [[_levelConfig get:KEY_STEP_BASIC_ENEMIES_SPAWNED forLevel:g.currentLevel] integerValue];
    for (int i = 0; i < basicEnemiesToSpawn; i++) {
        [self spawnEnemyOfType:@"EnemyBasic"];
    }

}

#pragma mark Heroes and Enemies Handling

-(void) spawnHero {
    Hero *hero = (Hero *) [CCBReader load:@"Hero"];
    [g.heroes addObject:hero];
    [_physicsNode addChild:hero];
    
    hero.position = [_pathGenerator getRandomPosition];
}

-(void) spawnEnemyOfType:(NSString*)enemyType {
    Enemy *enemy = (Enemy *) [CCBReader load:enemyType];
    [g.enemies addObject:enemy];
    [_physicsNode addChild:enemy];
    
    enemy.position = [_pathGenerator getRandomPosition];
    enemy.handleEnemyDelegate = self;
}

-(void) impulseHeroesToPoint:(CGPoint)point withImpulse:(double)impulse {
    for (Hero *hero in g.heroes) {
        // Determine direction of the impulse
        double impulseX = point.x - hero.position.x;
        double impulseY = point.y - hero.position.y;
        
        // Get the x and y components of the impulse
        CGPoint normalizedImpulse = ccpNormalize(ccp(impulseX, impulseY));
        impulseX = normalizedImpulse.x * impulse;
        impulseY = normalizedImpulse.y * impulse;
        
        [hero.physicsBody  applyImpulse:ccp(impulseX, impulseY)];
    }
    g.heroesAreMoving = TRUE;
}

-(void) reduceHeroesVelocityByAmount:(double)totalReductionInVelocity {
    int stoppedHeroesCounter = 0;
    
    // Reduce the velocity of each hero
    for (Hero *hero in g.heroes) {
        // Get the x and y components of the reduction in velocity
        CGPoint normalizedVelocity = ccpNormalize(hero.physicsBody.velocity);
        double reductionInX = normalizedVelocity.x * totalReductionInVelocity;
        double reducitonInY = normalizedVelocity.y * totalReductionInVelocity;
        
        // Keep reducing velocity until the hero stops (until velocity is 0)
        if (hero.physicsBody.velocity.x != 0) {
            hero.physicsBody.velocity = ccp(hero.physicsBody.velocity.x - reductionInX, hero.physicsBody.velocity.y);
        }
        if (hero.physicsBody.velocity.y != 0) {
            hero.physicsBody.velocity = ccp(hero.physicsBody.velocity.x, hero.physicsBody.velocity.y - reducitonInY);
        }
        
        // If the new velocity passed over 0, then we set the velocity at 0
        if ( (normalizedVelocity.x > 0 && hero.physicsBody.velocity.x < 0)
            || (normalizedVelocity.x < 0 && hero.physicsBody.velocity.x > 0) ) {
            hero.physicsBody.velocity = ccp(0, hero.physicsBody.velocity.y);
        }
        if ((normalizedVelocity.y > 0 && hero.physicsBody.velocity.y < 0)
            || (normalizedVelocity.y < 0 && hero.physicsBody.velocity.y > 0)) {
            hero.physicsBody.velocity = ccp(hero.physicsBody.velocity.x, 0);
        }
        
        if (hero.physicsBody.velocity.x == 0 && hero.physicsBody.velocity.y == 0) {
            stoppedHeroesCounter++;
        }
    }
    
    if (stoppedHeroesCounter == [g.heroes count]) {
        g.heroesAreMoving = FALSE;
    }

}

-(void) stopAllHeroes {
    for (Hero *hero in g.heroes) {
        hero.physicsBody.velocity = ccp(0, 0);
    }
    g.heroesAreMoving = FALSE;
}

#pragma mark HandleEnemy Delegate

-(void) removeEnemy:(Enemy *)enemy {
    [enemy removeFromParent];
    [g.enemies removeObject:enemy];
    
    // Increment enemies killed counters
    g.numberOfKillsInTouch++;
    g.numberOfKillsInLevel++;
    g.numberOfKillsInTotal++;
    
    // Calculate obtained score for killing this enemy
    NSInteger scoreObtained = enemy.damageLimit * g.numberOfKillsInTouch;
    
    [self showMessage:scoreObtained forEnemyWithPosition:enemy.position];
    
    [self incrementScoreBy:scoreObtained];
}

#pragma mark Collision Delegates

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero1 hero:(CCNode*)hero2 {
    // Ignore hero collisions so that they can pass through each other
    return NO;
}

-(BOOL)ccPhysicsCollisionSeparate:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero enemy:(CCNode*)enemy {
    if (g.gameState == GameRunning) {
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
    g.score += amount;
    _lblScore.string = [NSString stringWithFormat:@"%ld", g.score];
}

-(NSArray*) getUpdatedTopScores {
    int MAX_TOP_SCORES = 5;
    
    // Get saved top scores
    NSArray *topScores =  [[NSUserDefaults standardUserDefaults] objectForKey:KEY_TOP_SCORES];
    
    // Insert the current _score as a top score, if applicable
    NSMutableArray *newTopScores = [NSMutableArray arrayWithArray:topScores];
    if ([newTopScores count] == 0) {
        // Add the score if we don't have previous top score
        newTopScores[0] = [NSNumber numberWithInteger:g.score];
    } else {
        BOOL scoreAdded = FALSE;
        
        // If the _score is greater than a previously saved top score, we add it
        for (int i = 0; i < MAX_TOP_SCORES; i++) {
            if (g.score >= [(NSNumber*)newTopScores[i] integerValue]) {
                [newTopScores insertObject:[NSNumber numberWithInteger:g.score] atIndex:i];
                scoreAdded = TRUE;
                break;
            }
        }
        
        // If we still don't have the MAX_TOP_SCORES amount, and the score wasn't added, we add it
        if (!scoreAdded && [newTopScores count] < MAX_TOP_SCORES) {
            [newTopScores addObject:[NSNumber numberWithInteger:g.score]];
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
    [self setGameStateLabel:GamePaused];
    
    [self loadOverlay:@"Pause"];
    
    // Pause the game
    [[CCDirector sharedDirector] pause];
}

// Method called from the Pause.ccb file
-(void) resume {
    [self setGameStateLabel:GameRunning];
    [self removeChildByName:@"Pause"];
    // Resume the game
    [[CCDirector sharedDirector] resume];
}

// Method called from the Score.ccb file
// Method called from the Pause.ccb file
-(void) playAgain {
    [self setGameStateLabel:GameRunningAgain];
    
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
    [self setGameStateLabel:GameNotStarted];
    
    // This check is necessary because this method can be called from a paused state
    if ([CCDirector sharedDirector].paused) {
        [[CCDirector sharedDirector] resume];
    }
    
    // Reload the game
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"MainScene"]];
}

#pragma mark Game State Handling

-(GameStateLabel) getGameStateLabelFromUserDefaults {
    GameStateLabel state = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_GAME_STATE];
    return state;
}

-(void) setGameStateLabel:(GameStateLabel)state {
    g.gameState = state;
    NSLog(@"setGameState() gameState: @%ld", g.gameState);
    
    [[NSUserDefaults standardUserDefaults] setInteger:g.gameState forKey:KEY_GAME_STATE];
    
    // If the game state is different from GameRunning, we should disable some stuff
    if (g.gameState != GameRunning) {
        self.userInteractionEnabled = FALSE;
        _btnPause.visible = FALSE;
        _lblScore.visible = FALSE;
    } else {
        self.userInteractionEnabled = TRUE;
        _btnPause.visible = TRUE;
        _lblScore.visible = TRUE;

    }
        
}

-(void) startGame {
    // Load the first level
    [self loadLevel:g.currentLevel];
    
    [self setGameStateLabel:GameRunning];
}

-(void) endGame {
    [self setGameStateLabel:GameNotStarted];
    
    [self loadOverlay:@"Score"];
    
    // Show the player's score
    _lblYourFinalScore.string = [NSString stringWithFormat:@"%ld", g.score];
    
    // Show the top scores
    NSArray *topScores = [self getUpdatedTopScores];
    NSMutableString *topScoresString = [NSMutableString stringWithString:@""];
    for (NSNumber *topScore in topScores) {
        [topScoresString appendString: [NSString stringWithFormat:@"%ld\n", [topScore integerValue]]];
    }
    _lblTopScores.string = topScoresString;
}

@end

