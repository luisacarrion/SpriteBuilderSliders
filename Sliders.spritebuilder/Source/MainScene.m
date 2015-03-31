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
static const NSString *KEY_GAME_STATE_LABEL = @"keyGameStateLabel";
static const NSString *KEY_TOP_SCORES = @"keyTopScores";
static const NSInteger HERO_IMPULSE = 180;
static const NSInteger BULLET_IMPULSE = 10;
// Units the velocity of the heroes is reduced per frame when there are enemies in the field
static const NSInteger HERO_VEL_REDUCTION_WITH_ENEMIES = 1;
// Units the velocity of the heroes is reduced per frame when there are no enemies in the field
static const NSInteger HERO_VEL_REDUCTION_WITHOUT_ENEMIES = 10;
// Time to wait before firing the first shot to kill the heroes
static const NSInteger SECONDS_FOR_FIRST_ENEMY_SHOT = 5;
// Time to wait after firing the first shot to kill the heroes, in order to shoot again. The time resets to MSECONDS_FOR_FIRST_ENEMY_SHOT when a hero kills an enemy
static const NSInteger SECONDS_FOR_NEXT_ENEMY_SHOT = 2;

@implementation MainScene {
    
    // CCNodes - code connections with SpriteBuilder
    // CCNodes of the MainScene ccb file
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
    // Initialize game state
    g = [GameState sharedInstance];
    [g loadStateFromUserDefaults];
    
    // Initialize helper objects
    _levelConfig = [[LevelConfiguration alloc] init];
    _pathGenerator = [[PositionGenerator alloc] init];
    _pathGenerator.screenWidth = [CCDirector sharedDirector].viewSize.width;
    _pathGenerator.screenHeight = [CCDirector sharedDirector].viewSize.height;
    _pathGenerator.characterWidth = CHARACTER_WIDTH;
    _pathGenerator.characterHeight = CHARACTER_HEIGHT;
    
    // Set collisions delegate
    _physicsNode.collisionDelegate = self;
    
    NSLog(@"didLoadFromCCB() gameState: @%ld", g.gameState);
    
    // Load appropriate overlay screen depending on game state
    if (g.gameState == GameNotStarted) {
        
        // GameNotStarted: means the player just launched the game, so we show the title screen
        [self loadOverlay:@"Title"];
        
    } else if (g.gameState == GameRunningAgain) {
        
        // GameRunningAgain: means the player pressed the "play again" button from the pause overlay, therefore we begin the game immediately, withouth showing any overlays
        [self startGame];
        
    } else if (g.gameState == GamePaused || g.gameState == GameRunning) {
        
        // If the user left the app when the game was paused or running, we update the game objects with the data saved in the NSUserDefaults and then we load the pause overlay so the player can resume the game
        [self updateScoreLabel];
        
        // Recreate the CCSprite objects that couldn't be serialized completely and saved into NSUserDefaults
        [self recreateHeroes];
        [self recreateEnemies];
        
        // Simulate pressing the pause button
        [self pause];
    }
    
    //_physicsNode.debugDraw = true;
    
}

-(void) update:(CCTime)delta {
    if (g.gameState == GameRunning) {
        
        if (![self isGameOver]) {
            
            // If there are enemies and some time has passed, enemies shoot at the heroes
            if ([g.enemies count] > 0) {
                g.secondsSinceHeroKilledEnemy += delta;
                if (g.secondsSinceHeroKilledEnemy >= SECONDS_FOR_FIRST_ENEMY_SHOT && !g.enemiesAreAttacking) {
                    [self enemy:g.getRandomEnemy shootsAtHero:g.getRandomHero];
                    g.enemiesAreAttacking = TRUE;
                } else if (g.secondsSinceHeroKilledEnemy >= SECONDS_FOR_FIRST_ENEMY_SHOT + SECONDS_FOR_NEXT_ENEMY_SHOT) {
                    [self enemy:g.getRandomEnemy shootsAtHero:g.getRandomHero];
                    // Reset the counter of seconds, so it always waits the amount of SECONDS_FOR_NEXT_ENEMY_SHOT until an enemy is killed
                    g.secondsSinceHeroKilledEnemy = SECONDS_FOR_FIRST_ENEMY_SHOT;
                }
            }
            
            // If heroes stopped moving and there are no more enemies, Load next level or next step of current level
            if (!g.heroesAreMoving) {
                if ([self isLevelCompleted]) {
                    // Load next level
                    if (![self loadNextLevel]) {
                        // If the next level couldn't be loaded (because there were no more levels), end the game
                        [self endGame];
                    }
                } else if ([self isStepOfCurrentLevelCompleted]) {
                    // If level is not completed but there are no more enemies to kill, load the next step of the level (to load more enemies for the current level)
                    
                    // The next step of the level will spawn new enemies
                    [self loadNextStepOfLevel:g.currentLevel isFirstStep:NO];
                }
            }
            
        } else {
            // Game is over
            [self endGame];
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
    
    // Show a message indicating the new level
    NSString *message = [NSString stringWithFormat:@"Level %ld", level];
    CGPoint position = ccp(_pathGenerator.screenWidth/2, _pathGenerator.screenHeight - 20);
    [self showMessage:message atPosition:position];
    
    // Load the first step of the level
    [self loadNextStepOfLevel:level isFirstStep:YES];
}

-(BOOL) isStepOfCurrentLevelCompleted {
    BOOL stepCompleted = false;
    
    // Step is completed when the player has eliminated all the enemies in the current step
    if ([g.enemies count] == 0) {
        stepCompleted = true;
    }
    
    return stepCompleted;
}

// A new step of the level is loaded when the user kills all the enemies in the current step
-(void) loadNextStepOfLevel:(NSInteger)level isFirstStep:(BOOL)isFirstStep {
    NSLog(@"nextStepOfLevel: %ld, isFirstStep %d", level, isFirstStep);
    // Spawn heroes
    if (isFirstStep) {
        // Heroes are spawned only at the beginning of each level (in the first step)
        NSInteger heroesToSpawn = [[_levelConfig get:KEY_START_HEROES_SPAWNED forLevel:g.currentLevel] integerValue];
        for (int i = 0; i < heroesToSpawn; i++) {
            [self spawnHero];
        }
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
    
    hero.ccbFileName = @"Hero";
    hero.position = [_pathGenerator getRandomPosition];
    hero.handleHeroDelegate = self;
}

-(void) spawnEnemyOfType:(NSString*)enemyType {
    Enemy *enemy = (Enemy *) [CCBReader load:enemyType];
    [g.enemies addObject:enemy];
    [_physicsNode addChild:enemy];
    
    enemy.ccbFileName = enemyType;
    enemy.position = [_pathGenerator getRandomPosition];
    enemy.handleEnemyDelegate = self;
}

-(void) recreateHeroes {
    // Recreate heroes with the data obtained from the NSUserDefaults when the gameState was loaded
    NSMutableArray *recreatedHeroes = [NSMutableArray array];
    for (Hero *tempHero in g.heroes) {
        Hero *hero = (Hero *) [CCBReader load:tempHero.ccbFileName];
        hero.position = tempHero.position;
        hero.physicsBody.velocity = tempHero.savedVelocity;
        hero.ccbFileName = tempHero.ccbFileName;
        hero.health = tempHero.health;
        hero.damageReceived = tempHero.damageReceived;
        hero.attackPower = tempHero.attackPower;
        hero.handleHeroDelegate = self;
        
        [_physicsNode addChild:hero];
        [recreatedHeroes addObject:hero];
    }
    g.heroes = recreatedHeroes;
}

-(void) recreateEnemies {
    // Recreate enemies with the data obtained from the NSUserDefaults when the gameState was loaded
    NSMutableArray *recreatedEnemies = [NSMutableArray array];
    for (Enemy *tempEnemy in g.enemies) {
        Enemy *enemy = (Enemy *) [CCBReader load:tempEnemy.ccbFileName];
        enemy.position = tempEnemy.position;
        enemy.ccbFileName = tempEnemy.ccbFileName;
        enemy.health = tempEnemy.health;
        enemy.damageReceived = tempEnemy.damageReceived;
        enemy.handleEnemyDelegate = self;
        
        [_physicsNode addChild:enemy];
        [recreatedEnemies addObject:enemy];
        
    }
    g.enemies = recreatedEnemies;
}

-(void) impulseHeroesToPoint:(CGPoint)point withImpulse:(double)impulse {
    for (Hero *hero in g.heroes) {
        CGPoint impulseVector = [self getVectorToMoveFromPoint:hero.position ToPoint:point withImpulse:impulse];
        [hero.physicsBody  applyImpulse:impulseVector];
    }
    g.heroesAreMoving = TRUE;
}

-(CGPoint) getVectorToMoveFromPoint:(CGPoint)origin ToPoint:(CGPoint)target withImpulse:(NSInteger)impulse {
    // Determine direction of the impulse
    double impulseX = target.x - origin.x;
    double impulseY = target.y - origin.y;
    
    // Get the x and y components of the impulse
    CGPoint normalizedImpulse = ccpNormalize(ccp(impulseX, impulseY));
    impulseX = normalizedImpulse.x * impulse;
    impulseY = normalizedImpulse.y * impulse;
    
    return ccp(impulseX, impulseY);
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

-(void) enemy:(Enemy*)enemy shootsAtHero:(Hero*)hero {
    CCSprite *bullet = (CCSprite*) [CCBReader load:@"Bullet"];
    
    [_physicsNode addChild:bullet];
    
    bullet.position = enemy.position;
    
    CGPoint impulseVector = [self getVectorToMoveFromPoint:enemy.position ToPoint:hero.position withImpulse:BULLET_IMPULSE];
    [bullet.physicsBody  applyImpulse:impulseVector];
    
}

-(void) removeBullet:(CCSprite*)bullet {
    [bullet removeFromParent];
}

#pragma mark HandleEnemy Delegate

-(void) removeEnemy:(Enemy *)enemy {
    [enemy removeFromParent];
    [g.enemies removeObject:enemy];
    
    // Increment enemies killed counters
    g.numberOfKillsInTouch++;
    g.numberOfKillsInLevel++;
    g.numberOfKillsInTotal++;
    
    // Enemies stop attacking
    g.secondsSinceHeroKilledEnemy = 0;
    g.enemiesAreAttacking = FALSE;
    
    // Calculate obtained score for killing this enemy
    NSInteger scoreObtained = enemy.health * g.numberOfKillsInTouch;
    NSString *scoreObtainedAsString = [NSString stringWithFormat:@"+%ld", scoreObtained];
    [self showMessage:scoreObtainedAsString atPosition:enemy.position];
    
    [self incrementScoreBy:scoreObtained];
}

#pragma mark HandleHero Delegate

-(void) removeHero:(Hero*)hero {
    [hero removeFromParent];
    [g.heroes removeObject:hero];
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
            [(Enemy*)enemy applyDamage:((Hero*)hero).attackPower];
        }key:enemy];
        
    }
    return YES;
}

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair bullet:(CCNode *)bullet wall:(CCNode *)wall {
    [[_physicsNode space] addPostStepBlock:^{
        [self removeBullet:(CCSprite*)bullet];
    }key:bullet];
}

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair bullet:(CCNode *)bullet hero:(CCNode *)hero {
    [[_physicsNode space] addPostStepBlock:^{
        [self removeBullet:(CCSprite*)bullet];
        [(Hero*)hero applyDamage:1];
    }key:bullet];
}

#pragma mark Score Calculation and Presentation

-(void) showMessage:(NSString*)message atPosition:(CGPoint)position {
    CCLabelTTF *lblForMessage = [CCLabelTTF labelWithString:message fontName:@"Helvetica" fontSize:16];
    
    lblForMessage.position = position;
    [self addChild:lblForMessage];
    
    CCActionFadeOut *fadeAction = [CCActionFadeOut actionWithDuration:0.75];
    CCActionMoveBy *moveUpAction = [CCActionMoveBy actionWithDuration:0.75 position:ccp(0, 10)];
    CCActionRemove *removeAction = [CCActionRemove action];
    
    CCActionSpawn *spawnAction = [CCActionSpawn actionWithArray:@[fadeAction, moveUpAction]];
    CCActionSequence *sequenceAction = [CCActionSequence actionWithArray:@[spawnAction, removeAction]];
    
    [lblForMessage runAction:sequenceAction];
}

-(void) incrementScoreBy:(NSInteger)amount {
    g.score += amount;
    [self updateScoreLabel];
}

-(void) updateScoreLabel {
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
    _physicsNode.paused = true;
}

// Method called from the Pause.ccb file
-(void) resume {
    [self setGameStateLabel:GameRunning];
    [self removeChildByName:@"Pause"];
    // Resume the game
    [[CCDirector sharedDirector] resume];
    _physicsNode.paused = false;
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

-(void) setGameStateLabel:(GameStateLabel)state {
    NSLog(@"setGameState() gameState: @%ld", g.gameState);
    
    // If the game state is different from GameRunning, we should disable some stuff
    if (state != GameRunning) {
        self.userInteractionEnabled = FALSE;
        _btnPause.visible = FALSE;
        _lblScore.visible = FALSE;
    } else {
        self.userInteractionEnabled = TRUE;
        _btnPause.visible = TRUE;
        _lblScore.visible = TRUE;

    }
    
    if (state == GameNotStarted || state == GameRunningAgain) {
        // Reset the game state: the game is ready to be reloaded
        [g resetState];
        [g saveStateInUserDefaults];
    }

    // Always save the game state that was passed to the method, because the resetState method could have overwritten it
    g.gameState = state;
    [[NSUserDefaults standardUserDefaults] setInteger:g.gameState forKey:KEY_GAME_STATE_LABEL];
}

-(void) startGame {
    // Load the first level
    [self loadLevel:g.currentLevel];
    
    [self setGameStateLabel:GameRunning];
}

-(BOOL) isGameOver {
    BOOL gameOver = FALSE;
    
    if ([g.heroes count] == 0) {
        gameOver = TRUE;
    }
    
    return gameOver;
}

-(void) endGame {
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
    
    [self setGameStateLabel:GameNotStarted];
}

@end

