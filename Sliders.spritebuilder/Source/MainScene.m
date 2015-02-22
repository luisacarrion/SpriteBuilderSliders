#import "Enemy.h"
#import "Hero.h"
#import "IntersectedPathGenerator.h"
#import "MainScene.h"


@implementation MainScene {
    IntersectedPathGenerator *_pathGenerator;
    
    NSInteger _currentLevel;
    
    CCNode *_contentNode;
    CCPhysicsNode *_physicsNode;
    NSMutableArray *_heroes;
    NSMutableArray *_enemies;
    NSMutableArray *_enemiesEliminated;
    NSInteger _enemiesEliminatedCounter;
}

- (void) didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    _physicsNode.collisionDelegate = self;
    
    _heroes = [NSMutableArray array];
    _enemies = [NSMutableArray array];
    _enemiesEliminated = [NSMutableArray array];
    _currentLevel = [self getCurrentLevel];
    
    _pathGenerator = [[IntersectedPathGenerator alloc] init];
    _pathGenerator.screenWidth = [CCDirector sharedDirector].viewSize.width;
    _pathGenerator.screenHeight = [CCDirector sharedDirector].viewSize.height;
    _pathGenerator.characterWidth = 100;
    _pathGenerator.characterHeight = 100;
    
    [self loadLevel:_currentLevel];
    
    //_physicsNode.debugDraw = true;
    
}

-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    [self impulseHeroesToPoint:touchLocation];
}

-(void) update:(CCTime)delta {
    
    for (Enemy *enemyEliminated in _enemiesEliminated) {
        [self eliminateEnemy:enemyEliminated];
    }
    _enemiesEliminated = [NSMutableArray array];
    
}

- (void) loadLevel:(NSInteger)level {
    if (level == 1) {
        [_pathGenerator tempGeneratePaths:2];
        
        [self spawnHero:1];
        [self spawnEnemy:1 ofType:@"EnemyBasic"];
        
        [self spawnHero:2];
        [self spawnEnemy:2 ofType:@"EnemyBasic"];
    
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
    _heroes[[_heroes count]] = hero;
    [_physicsNode addChild:hero];
    
    NSLog(@"hero position 1: %@", NSStringFromCGPoint(hero.position));
    // Arreglar el hardcoded 0, y la posicion en el didLoad
    hero.position = [_pathGenerator.heroPositions[counter-1] CGPointValue];
    
    NSLog(@"hero position inside: %@", _pathGenerator.heroPositions[counter-1]);
    NSLog(@"hero position 2: %@", NSStringFromCGPoint(hero.position));
}

-(void) spawnEnemy:(int)counter ofType:(NSString*)enemyType {
    Enemy *enemy = (Enemy *) [CCBReader load:enemyType];
    [_physicsNode addChild:enemy];
    enemy.position = [_pathGenerator.enemyPositions[counter-1] CGPointValue];
}

-(void) eliminateEnemy:(Enemy*)enemy {
    [enemy removeFromParent];
    
    _enemiesEliminatedCounter++;
    NSLog(@"_enemiesEliminatedCounter: %ld", _enemiesEliminatedCounter);
    
}

- (NSInteger) getCurrentLevel {
    // TODO: Add logic to check from the NSUserDefaults if there is a level saved
    return 1;
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

