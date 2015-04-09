
#import "HandleEnemy.h"
#import "HandleHero.h"

// Enum type = NSInteger
// Enum name = DrawingOrder
typedef NS_ENUM(NSInteger, DrawingOrder) {
    DrawingOrderBullet,
    DrawingOrderEnemy,
    DrawingOrderHero
};

@interface MainScene : CCNode <CCPhysicsCollisionDelegate, HandleEnemy, HandleHero>

@end
