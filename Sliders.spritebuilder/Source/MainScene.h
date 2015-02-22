
// Enum type = NSInteger
// Enum name = DrawingOrder
typedef NS_ENUM(NSInteger, DrawingOrder) {
    DrawingOrderEnemy,
    DrawingOrderHero
};

@interface MainScene : CCNode <CCPhysicsCollisionDelegate>

@end
