#import "GameState.h"
#import "Enemy.h"
#import "Hero.h"
#import "Bullet.h"
#import "PositionGenerator.h"
#import "LevelConfiguration.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Utils.h"
#import "MainScene.h"
#import "Mixpanel.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKLoginKit/FBSDKLoginManager.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

// Game constants
static const NSInteger CHARACTER_WIDTH = 100;
static const NSInteger CHARACTER_HEIGHT = 100;
static const NSString *KEY_GAME_STATE_LABEL = @"keyGameStateLabel";
static const NSString *KEY_TOP_SCORES = @"keyTopScores";
static const NSInteger HERO_IMPULSE = 640;//250;//300;//180;
// Units the velocity of the heroes is reduced per frame when there are enemies in the field
static const NSInteger HERO_VEL_REDUCTION_WITH_ENEMIES = 4;//3;//1;
// Units the velocity of the heroes is reduced per frame when there are no enemies in the field
static const NSInteger HERO_VEL_REDUCTION_WITHOUT_ENEMIES = 20;//30;//10;

// File names of sounds
static NSString *SOUND_BUTTON = @"audio/eklee-KeyPressMac01.wav";
static NSString *SOUND_ENEMY_HIT_BY_HERO = @"audio/Strong_Punch-Mike_Koenig-574430706.wav";


@implementation MainScene {
    
    // CCNodes - code connections with SpriteBuilder
    // CCNodes of the MainScene ccb file
    CCPhysicsNode *_physicsNode;
    CCLabelTTF *_lblScore;
    CCButton *_btnPause;
    // Current overlay being displayed
    CCNode *overlayScreen;
    // CCNodes of the Title ccb file
    CCButton *_btnFbLogin;
    CCButton *_btnFbLogout;
    // CCNodes of the Score ccb file
    CCLabelTTF *_lblYourFinalScore;
    CCLabelTTF *_lblTopScores;
    CCButton *_btnFbShare;
    
    // Game variables
    GameState *g;
    
    // Helper objects
    PositionGenerator *_pathGenerator;  // Generates positions for new enemies and power ups
    LevelConfiguration *_levelConfig;  // Holds configurations of all the levels
    
    // Game analytics objects
    Mixpanel *mixpanel;
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
        overlayScreen = [self loadOverlay:@"Title"];
        
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
    
    // Initialize game analytics object
    mixpanel = [Mixpanel sharedInstance];
    
    //_physicsNode.debugDraw = true;
    
}

-(void) update:(CCTime)delta {
    if (g.gameState == GameRunning) {
        if (![self isGameOver]) {
            // If heroes stopped moving and there are no more enemies, Load next level or next step of current level
            if (!g.heroesAreMoving) {
                // If heroes made a move, killed an enemy, and left enemies alive, one of those enemies will fire back because they are in rage mode
                // TODO: finish implementation of card
                if ([g areEnemiesOnRevengeMode]) {
                    [self enemy:g.getRandomEnemy shootsAtHero:g.getRandomHero];
                    // When enemies have their revenge, they calm down
                    [self endEnemiesRevengeMode];
                }
                
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
    
    // If the heroes are in focus mode, user touches won't be processed
    if (g.gameState == GameRunning && ![g areHeroesOnFocusMode]) {
        CGPoint touchLocation = [touch locationInNode: self];
        g.numberOfKillsInTouch = 0;
        g.numberOfCollisionsWithEnemiesInTouch = 0;

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
        
        // End tracking how long the user takes to complete this level
        [mixpanel track:[NSString stringWithFormat:@"Level %ld", g.currentLevel]];
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
    [self showMessage:message atPosition:position withDelay:3];
    
    // Load the first step of the level
    [self loadNextStepOfLevel:level isFirstStep:YES];
    
    // Start tracking how long the user takes to complete this level
    [mixpanel timeEvent:[NSString stringWithFormat:@"Level %ld", level]];
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
    
    // If all enemies in a step were killed, then there is no more revenge mode
    [self endEnemiesRevengeMode];
    
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
    
    NSInteger tankEnemiesToSpawn = [[_levelConfig get:KEY_STEP_TANK_ENEMIES_SPAWNED forLevel:g.currentLevel] integerValue];
    for (int i = 0; i < tankEnemiesToSpawn; i++) {
        [self spawnEnemyOfType:@"EnemyTank"];
    }
    
    NSInteger assassinEnemiesToSpawn = [[_levelConfig get:KEY_STEP_ASSASSIN_ENEMIES_SPAWNED forLevel:g.currentLevel] integerValue];
    for (int i = 0; i < assassinEnemiesToSpawn; i++) {
        [self spawnEnemyOfType:@"EnemyAssassin"];
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
    
    [enemy playSpawnAnimation];
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
        
        // If the saved animation is different from Default Timeline, then run the saved animation
        if (tempEnemy.animationRunning != nil && ![tempEnemy.animationRunning  isEqual: @"Default Timeline"]) {
            [enemy.animationManager runAnimationsForSequenceNamed:tempEnemy.animationRunning];
            enemy.animationManager.paused = TRUE;
        }

        
        [_physicsNode addChild:enemy];
        [recreatedEnemies addObject:enemy];
        
    }
    g.enemies = recreatedEnemies;
}

-(void) impulseHeroesToPoint:(CGPoint)point withImpulse:(double)impulse {
    for (Hero *hero in g.heroes) {
        CGPoint impulseVector = [Utils getVectorToMoveFromPoint:hero.position ToPoint:point withImpulse:impulse];
        [hero.physicsBody  applyImpulse:impulseVector];
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
        [self onHeroesStoppedMoving];
    }

}


-(void) onHeroesStoppedMoving {
    g.heroesAreMoving = FALSE;
    [self endHeroesFocusMode];
}

-(void) stopAllHeroes {
    for (Hero *hero in g.heroes) {
        hero.physicsBody.velocity = ccp(0, 0);
    }
    g.heroesAreMoving = FALSE;
}

-(void) enemy:(Enemy*)enemy shootsAtHero:(Hero*)hero {
    [enemy playAnimationShootBulletAtHero:hero];
}

-(void) removeBullet:(CCSprite*)bullet {
    [bullet removeFromParent];
}

-(void)startHeroesFocusMode {
    if (g.numberOfCollisionsWithEnemiesInTouch == 0) {
        // Only do this the first time a hero touches an enemy
        for (Hero *hero in g.heroes) {
            [hero displayFocusMode];
        }
    }
    g.numberOfCollisionsWithEnemiesInTouch++;
}

-(void)endHeroesFocusMode {
    for (Hero *hero in g.heroes) {
        [hero displayNormalMode];
    }
}

-(void)startEnemiesRevengeMode {
    for (Enemy* enemy in g.enemies) {
        [enemy playRevengeModeAnimation];
    }
}

-(void)endEnemiesRevengeMode {
    g.numberOfKillsInTouch = 0;
    for (Enemy* enemy in g.enemies) {
        [enemy stopRevengeModeAnimation];
    }
}

-(void) separateOverlappingHeroes:(Hero*)hero1 and:(Hero*)hero2 {

    // Determine the quadrant to which we want to impulse a hero to separate the two heroes
    float targetDirectionX;
    float targetDirectionY;
    if (hero1.position.x <= _pathGenerator.screenWidth / 2) {
        // If the hero is on the left side of the screen, we want to impulse it to the right
        targetDirectionX = 1;
    } else {
        // If the hero is on the right side of the screen, we want to impulse it to the left
        targetDirectionX = -1;
    }
    
    if (hero1.position.y <= _pathGenerator.screenHeight / 2) {
        // If the hero is on the upper side of the screen, we want to impulse it to the lower side
        targetDirectionY = 1;
    } else {
        // If the hero is on the lower side of the screen, we want to impulse it to the upper side
        targetDirectionY = -1;
    }
    
    
    // Determine the quadrant to where we want to impulse the hero and set targetX and targetY to the quadrant's coordinates
    float targetX = 0;
    float targetY = 0;
    if (targetDirectionX > 0) {
        if (targetDirectionY > 0) {
            // Quadrant 1
            targetX = _pathGenerator.screenWidth;
            targetY = _pathGenerator.screenHeight;
        } else if (targetDirectionY < 0) {
            // Quadrant 4
            targetX = _pathGenerator.screenWidth;
            targetY = 0;
        }
    } else if (targetDirectionX < 0) {
        if (targetDirectionY > 0) {
            // Quadrant 2
            targetX = 0;
            targetY = _pathGenerator.screenHeight;
        } else if (targetDirectionY < 0) {
            // Quadrant 3
            targetX = 0;
            targetY = 0;
        }
    }
    
    // Determine which one is the hero that is closer to the target point
    float hero1Closeness;
    float hero2Closeness;
    // Calculate closeness with Pitagoras theorem
    hero1Closeness = sqrtf( (targetX - hero1.position.x)*(targetX - hero1.position.x)
                           + (targetY - hero1.position.y)*(targetY - hero1.position.y) );
    hero2Closeness = sqrtf( (targetX - hero2.position.x)*(targetX - hero2.position.x)
                           + (targetY - hero2.position.y)*(targetY - hero2.position.y) );
    
    // To separate the heroes, Impulse the hero that is closer to the target point towards the target point
    Hero *heroToImpulse;
    if (hero2Closeness < hero1Closeness) {
        heroToImpulse = hero2;
    } else {
        heroToImpulse = hero1;
    }
    CGPoint impulseVector = [Utils getVectorToMoveFromPoint:heroToImpulse.position ToPoint:ccp(targetX, targetY) withImpulse:10];
    [heroToImpulse.physicsBody  applyImpulse:impulseVector];
}


#pragma mark HandleEnemy Delegate

-(void) removeEnemy:(Enemy *)enemy {
    // Remove enemy from the array, because it shouldn't be able to do anything else. It's dead
    [g.enemies removeObject:enemy];
    
    // Increment enemies killed counters
    g.numberOfKillsInTouch++;
    g.numberOfKillsInLevel++;
    g.numberOfKillsInTotal++;
    
    // Calculate obtained score for killing this enemy
    NSInteger scoreObtained = enemy.health * g.numberOfKillsInTouch;
    NSString *scoreObtainedAsString = [NSString stringWithFormat:@"+%ld", scoreObtained];
    [self showMessage:scoreObtainedAsString atPosition:enemy.position withDelay:0];
    
    [self incrementScoreBy:scoreObtained];
    
    // All others enemies enter revenge mode for their fallen ally
    [self startEnemiesRevengeMode];
}

#pragma mark HandleHero Delegate

-(void) removeHero:(Hero*)hero {
    [g.heroes removeObject:hero];
}

#pragma mark Collision Delegates

-(BOOL) ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero1 hero:(CCNode *)hero2 {
    if (g.heroesAreMoving == false && g.gameState == GameRunning) {
        // If heroes stopped moving and they are overlapping, we separate them
        [self separateOverlappingHeroes:(Hero*)hero1 and:(Hero*)hero2];
    }
    // Ignore hero collisions so that they can pass through each other
    return NO;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero enemy:(CCNode *)enemy {
    if (g.gameState == GameRunning && ((Hero*)hero).isAlive && ((Enemy*)enemy).isAlive) {
        [self startHeroesFocusMode];
        //[[OALSimpleAudio sharedInstance] playBg:SOUND_ENEMY_HIT_BY_HERO loop:NO];
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
        if (((Hero*)hero).isAlive) {
            [(Hero*)hero applyDamage:((Bullet*)bullet).attackPower];
        }
        // We need to remove the bullet if the hero was fading away but a bullet was shot at it
        [self removeBullet:(Bullet*)bullet];
    }key:bullet];
}

#pragma mark Score Calculation and Presentation

-(void) showMessage:(NSString*)message atPosition:(CGPoint)position withDelay:(CCTime)delay {
    CCLabelTTF *lblForMessage = [CCLabelTTF labelWithString:message fontName:@"Helvetica" fontSize:16];
    
    lblForMessage.position = position;
    lblForMessage.fontColor = [CCColor colorWithRed:0.4 green:0.46666666 blue:0.5451];
    [self addChild:lblForMessage];

    CCActionDelay *delayAction = [CCActionDelay actionWithDuration:delay];
    CCActionFadeOut *fadeAction = [CCActionFadeOut actionWithDuration:0.75];
    CCActionMoveBy *moveUpAction = [CCActionMoveBy actionWithDuration:0.75 position:ccp(0, 10)];
    CCActionRemove *removeAction = [CCActionRemove action];
    
    CCActionSpawn *spawnAction = [CCActionSpawn actionWithArray:@[fadeAction, moveUpAction]];
    CCActionSequence *sequenceAction = [CCActionSequence actionWithArray:@[delayAction, spawnAction, removeAction]];
    
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
    overlayScreen.anchorPoint = ccp(0.5, 0.5);
    //overlayScreen.positionType = CCPositionTypeNormalized;
    //overlayScreen.position = ccp(0.5, 0.5);

    [self addChild:overlayScreen];

    id entranceAction;

    if ([ccbFile isEqualToString:@"Title"]) {
        overlayScreen.position = ccp(_pathGenerator.screenWidth/2, _pathGenerator.screenHeight/2);
        
        // Show appropriate facebook button
        if ([FBSDKAccessToken currentAccessToken].userID == nil) {
            _btnFbLogin.visible = true;
            _btnFbLogout.visible = false;
        } else {
            _btnFbLogin.visible = false;
            _btnFbLogout.visible = true;
        }

        //id fadeIn = [CCActionTintBy actionWithDuration:5 red:100 green:10 blue:10];
        //entranceAction = fadeIn;
    } else {
        overlayScreen.position = ccp(_pathGenerator.screenWidth/2, _pathGenerator.screenHeight);

        id move = [CCActionMoveTo actionWithDuration:1 position:ccp(overlayScreen.position.x, _pathGenerator.screenHeight/2)];
        id easeMove = [CCActionEaseElasticOut actionWithAction:move period:0.5];
        entranceAction = easeMove;
        
        [overlayScreen runAction:entranceAction];

    }
    
    return overlayScreen;
}

-(void) removeOverlayAndExecute:(CCActionCallBlock*)block {
    //CCNode *overlayScreen = [self getChildByName:ccbFile recursively:false];
    id outAction;
    
    if ([overlayScreen.name isEqualToString:@"Title"]) {
        CCActionRemove *removeAction = [CCActionRemove action];
        CCActionSequence *sequenceAction = [CCActionSequence actionWithArray:@[removeAction, block]];
        outAction = sequenceAction;
    } else {
        id move = [CCActionMoveTo actionWithDuration:0.4 position:ccp(overlayScreen.position.x, _pathGenerator.screenHeight)];
        id easeMove = [CCActionEaseElasticIn actionWithAction:move period:0.5];
        CCActionRemove *removeAction = [CCActionRemove action];
        CCActionSequence *sequenceAction = [CCActionSequence actionWithArray:@[easeMove, removeAction, block]];
        outAction = sequenceAction;
    }
    
    [overlayScreen runAction:outAction];
    overlayScreen = nil;

}

// Method called from the Title.ccb file
-(void) play {
    // Always resume activity when a button is touched, because apparently the CCDirector is paused if the app was put on the background
    [[CCDirector sharedDirector] resume];
    
    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];

    CCActionCallBlock *block = [CCActionCallBlock actionWithBlock:^{
        [self startGame];
    }];
    
    [self removeOverlayAndExecute:block];
}

// Method called from the MainScene.ccb file
-(void) pause {
    // Always resume activity when a button is touched, because apparently the CCDirector is paused if the app was put on the background
    [[CCDirector sharedDirector] resume];

    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];
    
    [self setGameStateLabel:GamePaused];
    
    overlayScreen = [self loadOverlay:@"Pause"];
    
    // Pause the game
    _physicsNode.paused = true;
    
    // Save game state, in case the user leaves the app
    [g saveStateInUserDefaults];
}

// Method called from the Pause.ccb file
-(void) resume {
    // Always resume activity when a button is touched, because apparently the CCDirector is paused if the app was put on the background
    [[CCDirector sharedDirector] resume];

    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];
    
    CCActionCallBlock *block = [CCActionCallBlock actionWithBlock:^{
        [self setGameStateLabel:GameRunning];
        // Resume the game
        _physicsNode.paused = false;
    }];

    [self removeOverlayAndExecute:block];
}

// Method called from the Score.ccb file
// Method called from the Pause.ccb file
-(void) playAgain {
    // Always resume activity when a button is touched, because apparently the CCDirector is paused if the app was put on the background
    [[CCDirector sharedDirector] resume];

    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];
    
    [self setGameStateLabel:GameRunningAgain];
    // Game state label has to be saved so the game is reloaded without entering the title screen
    [[NSUserDefaults standardUserDefaults] setInteger:g.gameState forKey:KEY_GAME_STATE_LABEL];
    
    CCActionCallBlock *block = [CCActionCallBlock actionWithBlock:^{
        // Reload the game
        [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"MainScene"]];
    }];
    
    [self removeOverlayAndExecute:block];
}

// Method called from the Score.ccb file
// Method called from the Pause.ccb file
-(void) home {
    // Always resume activity when a button is touched, because apparently the CCDirector is paused if the app was put on the background
    [[CCDirector sharedDirector] resume];

    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];
    
    [self setGameStateLabel:GameNotStarted];
    // Game state label has to be saved so the game is reloaded without entering the title screen
    [[NSUserDefaults standardUserDefaults] setInteger:g.gameState forKey:KEY_GAME_STATE_LABEL];
    
    CCActionCallBlock *block = [CCActionCallBlock actionWithBlock:^{
        // Reload the game
        [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"MainScene"]];
    }];
    
    [self removeOverlayAndExecute:block];
}

// Method called from the Title.ccb file
-(void) infoButton {
    // Always resume activity when a button is touched, because apparently the CCDirector is paused if the app was put on the background
    [[CCDirector sharedDirector] resume];

    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];
    
    CCActionCallBlock *block = [CCActionCallBlock actionWithBlock:^{
        overlayScreen = [self loadOverlay:@"Info"];
    }];
    
    [self removeOverlayAndExecute:block];
}

-(void) facebookLogin {
    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];

    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithReadPermissions:@[@"email"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            // Process error
        } else if (result.isCancelled) {
            // Handle cancellations
        } else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if ([result.grantedPermissions containsObject:@"email"]) {
                // Do work
                _btnFbLogin.visible = false;
                _btnFbLogout.visible = true;
            }
        }
    }];
}

-(void) facebookLogout {
    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];

    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logOut];
    _btnFbLogin.visible = true;
    _btnFbLogout.visible = false;
}

-(void) facebookShare {
    [[OALSimpleAudio sharedInstance] playBg:SOUND_BUTTON loop:NO];

    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://hunt.makeschool.com/posts/104"];
    content.contentTitle = @"My Ninja Sliders Score";
    content.contentDescription = [NSString stringWithFormat:@"I got %@ points!", _lblYourFinalScore.string];
    //content.imageURL = @"assets/slash2.png";
    
    [FBSDKShareDialog showFromViewController:[CCDirector sharedDirector]
                                 withContent:content
                                    delegate:nil];
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
    overlayScreen = [self loadOverlay:@"Score"];
    
    // Show the player's score
    _lblYourFinalScore.string = [NSString stringWithFormat:@"%ld", g.score];
    
    // Show the top scores
    NSArray *topScores = [self getUpdatedTopScores];
    NSMutableString *topScoresString = [NSMutableString stringWithString:@""];
    for (NSNumber *topScore in topScores) {
        [topScoresString appendString: [NSString stringWithFormat:@"%ld\n", [topScore integerValue]]];
    }
    _lblTopScores.string = topScoresString;
    
    // Show share button if user is logged in
    if ([FBSDKAccessToken currentAccessToken].userID == nil) {
        _btnFbShare.visible = false;
    } else {
        _btnFbShare.visible = true;
    }
    
    [self setGameStateLabel:GameNotStarted];
}

@end

