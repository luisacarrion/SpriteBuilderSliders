#import "Enemy.h"
#import "Hero.h"
#import "IntersectedPathGenerator.h"
#import "LevelConfiguration.h"
#import "MainScene.h"


@implementation MainScene {    
    IntersectedPathGenerator *_pathGenerator;
    
    // Holds configurations of all the levels
    LevelConfiguration *_levelConfig;
    NSInteger _currentLevel;
    
    CCNode *_contentNode;
    CCPhysicsNode *_physicsNode;
    NSMutableArray *_heroes;
    NSMutableArray *_enemies;
    // Set to avoid adding the same enemy when 2 heroes collide with it
    NSMutableSet *_enemiesEliminated;
    NSInteger _levelEnemiesEliminatedCounter;
    NSInteger _totalEnemiesEliminatedCounter;
}

- (void) didLoadFromCCB {
    // Enable user interaction
    self.userInteractionEnabled = TRUE;
    // Set collisions delegate
    _physicsNode.collisionDelegate = self;
    
    // Initialize variables
    _heroes = [NSMutableArray array];
    _enemies = [NSMutableArray array];
    _enemiesEliminated = [NSMutableSet set];
    _levelConfig = [[LevelConfiguration alloc] init];
    _currentLevel = [self getCurrentLevel];
    
    // Initialize path generator object
    _pathGenerator = [[IntersectedPathGenerator alloc] init];
    _pathGenerator.screenWidth = [CCDirector sharedDirector].viewSize.width;
    _pathGenerator.screenHeight = [CCDirector sharedDirector].viewSize.height;
    _pathGenerator.characterWidth = 100;
    _pathGenerator.characterHeight = 100;
    
    // Load the first level
    [self loadLevel:_currentLevel];
    
    //_physicsNode.debugDraw = true;
    
}

-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    [self impulseHeroesToPoint:touchLocation];
}

-(void) update:(CCTime)delta {
    
    // Remove killed enemies
    for (Enemy *enemyEliminated in _enemiesEliminated) {
        [self eliminateEnemy:enemyEliminated];
    }
    _enemiesEliminated = [NSMutableSet set];
    
    // Check if ready for next level
    NSInteger totalLevelEnemies = [[_levelConfig get:KEY_TOTAL_ENEMIES forLevel:_currentLevel]
                                   integerValue];
    //NSLog(@"totalLevelEnemies: %ld", totalLevelEnemies);
    //NSLog(@"_levelEnemiesEliminatedCounter: %ld", _levelEnemiesEliminatedCounter);
    
    if (_levelEnemiesEliminatedCounter >= totalLevelEnemies) {
        _currentLevel++;
        
        NSInteger levelsCount = [_levelConfig getLevelsCount];
        if (_currentLevel <= levelsCount) {
            [self loadLevel:_currentLevel];
        } else {
            [self gameCompleted];
        }
        
    } else {
        // Still enemies to kill in this level
        // If the current ones have been eliminated, spaw the next enemies
        if ([_enemies count] == 0) {
            [self nextStepOfLevel:_currentLevel isFirstStep:NO];
        }
    }
    
}

- (void) loadLevel:(NSInteger)level {
    NSLog(@"Loading level: %ld", level);
    
    _levelEnemiesEliminatedCounter = 0;
    
    [self nextStepOfLevel:level isFirstStep:YES];
}

// Each step of the level is executed when the user kills all the current enemies
-(void) nextStepOfLevel:(NSInteger)level isFirstStep:(BOOL)isFirstStep {
    NSLog(@"nextStepOfLevel: %ld, isFirstStepL %d", level, isFirstStep);
    
    NSInteger enemiesToSpawn = [[_levelConfig get:KEY_ENEMIES_SPAWNED_PER_STEP forLevel:_currentLevel] integerValue];
    NSString *enemyType1 = [_levelConfig get:KEY_ENEMY_TYPE1 forLevel:_currentLevel];
    
    
    // There should always be more enemies than heroes, so we use the enemies value to generate paths
    [_pathGenerator tempGeneratePaths:enemiesToSpawn];
    NSLog(@"enemiesToSpawn: %ld", enemiesToSpawn);
    
    // Heroes are spawned only at the beginning of each level
    if (isFirstStep) {
        NSInteger heroesToSpawn = [[_levelConfig get:KEY_HEROES_SPAWNED_AT_LOAD forLevel:_currentLevel] integerValue];
        for (int i = 0; i < heroesToSpawn; i++) {
            [self spawnHero:i];
        }
    }

    
    for (int i = 0; i < enemiesToSpawn; i++) {
        [self spawnEnemy:i ofType:enemyType1];
    }

}

-(void) impulseHeroesToPoint:(CGPoint)point {
    for (Hero *hero in _heroes) {
        double impulseX = point.x - hero.position.x;
        double impulseY = point.y - hero.position.y;
        
        [hero.physicsBody  applyImpulse:ccp(impulseX, impulseY)];
    }
}

-(void) spawnHero:(int)counter {
    Hero *hero = (Hero *) [CCBReader load:@"Hero"];
    [_heroes addObject:hero];
    [_physicsNode addChild:hero];
    
    NSLog(@"hero position 1: %@", NSStringFromCGPoint(hero.position));
    // Arreglar el hardcoded 0, y la posicion en el didLoad
    hero.position = [_pathGenerator.heroPositions[counter] CGPointValue];
    
    NSLog(@"hero position inside: %@", _pathGenerator.heroPositions[counter]);
    NSLog(@"hero position 2: %@", NSStringFromCGPoint(hero.position));
}

-(void) spawnEnemy:(int)counter ofType:(NSString*)enemyType {
    Enemy *enemy = (Enemy *) [CCBReader load:enemyType];
    [_enemies addObject:enemy];
    [_physicsNode addChild:enemy];
    
    NSLog(@"spawnEnemy counter: %d", counter);
    enemy.position = [_pathGenerator.enemyPositions[counter] CGPointValue];
}

-(void) eliminateEnemy:(Enemy*)enemy {
    [enemy removeFromParent];
    [_enemies removeObject:enemy];
    
    _levelEnemiesEliminatedCounter++;
    _totalEnemiesEliminatedCounter++;
    NSLog(@"_levelEnemiesEliminatedCounter: %ld", _levelEnemiesEliminatedCounter);
    
}

- (NSInteger) getCurrentLevel {
    // TODO: Add logic to check from the NSUserDefaults if there is a level saved
    return 1;
}

-(void) gameCompleted {
    NSLog(@"Game Completed =)");
    exit(0);
}


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero1 hero:(CCNode*)hero2 {
    // Ignore hero collisions, they can pass through each other
    return NO;
}

-(BOOL)ccPhysicsCollisionSeparate:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero enemy:(CCNode*)enemy {
    
    [_enemiesEliminated addObject:enemy];
    
    return YES;
}


/*
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair character:(CCSprite*)character level:(CCNode*)level {
    [self gameOver];
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair character:(CCNode *)character goal:(CCNode *)goal {
    [goal removeFromParent];
    points++;
    _scoreLabel.string = [NSString stringWithFormat:@"%d", points];
    return TRUE;
}*/


@end

