#import "Enemy.h"
#import "Hero.h"
#import "PositionGenerator.h"
#import "LevelConfiguration.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "MainScene.h"

// Game constants
static const NSInteger CHARACTER_WIDTH = 100;
static const NSInteger CHARACTER_HEIGHT = 100;

@implementation MainScene {
    
    // CCNodes - code connections with SpriteBuilder
    CCPhysicsNode *_physicsNode;
    CCLabelTTF *_lblScore;
    
    // Game variables
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

- (void) didLoadFromCCB {
    // Initialize game variables
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
    
    // Load the first level
    [self loadLevel:_currentLevel];
    
    // Enable user interaction
    self.userInteractionEnabled = TRUE;
    // Set collisions delegate
    _physicsNode.collisionDelegate = self;
    
    //_physicsNode.debugDraw = true;
    
}

-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    CGPoint touchLocation = [touch locationInNode: self];
    _numberOfKillsInTouch = 0;
    [self impulseHeroesToPoint:touchLocation];
}

-(void) update:(CCTime)delta {
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

-(void) impulseHeroesToPoint:(CGPoint)point {
    for (Hero *hero in _heroes) {
        double impulseX = point.x - hero.position.x;
        double impulseY = point.y - hero.position.y;
        
        [hero.physicsBody  applyImpulse:ccp(impulseX, impulseY)];
    }
}

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

#pragma mark Collision Delegate

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero1 hero:(CCNode*)hero2 {
    // Ignore hero collisions so that they can pass through each other
    return NO;
}

#pragma mark Collision Delegate

-(BOOL)ccPhysicsCollisionSeparate:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero enemy:(CCNode*)enemy {
    // After the physics engine step ends, remove the enemy and increment the score
    [[_physicsNode space] addPostStepBlock:^{
        [(Enemy*)enemy applyDamage:((Hero*)hero).damage];
    }key:enemy];
    return YES;
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
    
    [self show:scoreObtained forEnemyWithPosition:enemy.position];
    
    [self incrementScoreBy:scoreObtained];
}

-(void) show:(NSInteger)scoreObtained forEnemyWithPosition:(CGPoint)position {
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

- (NSInteger) getCurrentLevel {
    // TODO: Add logic to check from the NSUserDefaults if there is a level saved
    return 1;
}

-(void) endGame {
    NSLog(@"Game Completed =)");
    exit(0);
}

@end

