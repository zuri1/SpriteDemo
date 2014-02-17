//
//  ZMBMyScene.m
//  SpriteDemo
//
//  Created by Zuri Biringer on 2/17/14.
//  Copyright (c) 2014 Zuri Biringer. All rights reserved.
//

#import "ZMBMyScene.h"

@interface ZMBMyScene ()

{
    int _nextFlappy;
    double _nextFlappySpawn;
    NSMutableArray *_shipLasers;
    int _nextShipLaser;
    int _lives;
}

@property (strong, nonatomic) SKSpriteNode *mainCharacter;
@property (strong, nonatomic) NSMutableArray *flappyArray;

#define kNumFlappys 8
#define kNumLasers 5


@end

@implementation ZMBMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        _nextFlappy = 0;
        
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        for (int i = 0; i < 2; i++) {
            SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
            bg.anchorPoint = CGPointZero;
            bg.position = CGPointMake(i * bg.size.width, 0);
            bg.name = @"background";
            [self addChild:bg];
        }
        
        self.mainCharacter = [SKSpriteNode spriteNodeWithImageNamed:@"TaoLinIcon"];
        self.mainCharacter.position = CGPointMake(50, 150);
        [self addChild:self.mainCharacter];
        
        self.mainCharacter.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.mainCharacter.size];
        self.mainCharacter.physicsBody.dynamic = YES;
        self.mainCharacter.physicsBody.affectedByGravity = NO;
        self.mainCharacter.physicsBody.mass = 0.02;
        
        self.flappyArray = [[NSMutableArray alloc] initWithCapacity:kNumFlappys];
        
        for (int i = 0; i < kNumFlappys; i++) {
            SKSpriteNode *flappy = [SKSpriteNode spriteNodeWithImageNamed:@"IJ"];
            flappy.position = CGPointMake(700, 100);
            flappy.hidden = YES;
            [self.flappyArray addObject:flappy];
            [self addChild:flappy];
        }
        
#pragma mark - TBD - Setup the lasers
        
        _shipLasers = [[NSMutableArray alloc] initWithCapacity:kNumLasers];
        for (int i = 0; i < kNumLasers; i++) {
            SKSpriteNode *shipLaser = [SKSpriteNode spriteNodeWithImageNamed:@"laserbeam_blue"];
            shipLaser.hidden = YES;
            [_shipLasers addObject:shipLaser];
            [self addChild:shipLaser];
        }
        
        for (SKSpriteNode *laser in _shipLasers) {
            laser.hidden = YES;
        }
        
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
//    [self.mainCharacter.physicsBody setVelocity:CGVectorMake(0, 7)];
//    [self.mainCharacter.physicsBody applyImpulse:CGVectorMake(0, 7)];
    
    SKSpriteNode *shipLaser = [_shipLasers objectAtIndex:_nextShipLaser];
    _nextShipLaser++;
    if (_nextShipLaser >= _shipLasers.count) {
        _nextShipLaser = 0;
    }
    
    shipLaser.position = CGPointMake(self.mainCharacter.position.x + shipLaser.size.width/2, self.mainCharacter.position.y+0);
    shipLaser.hidden = NO;
    [shipLaser removeAllActions];
    
    CGPoint location = CGPointMake(self.frame.size.width, self.mainCharacter.position.y);
    SKAction *laserMoveAction = [SKAction moveTo:location duration:0.5];
    
    SKAction *laserDoneAction = [SKAction runBlock:(dispatch_block_t)^() {
        shipLaser.hidden = YES;
    }];
    
    SKAction *moveLaserActionWithDone = [SKAction sequence:@[laserMoveAction,laserDoneAction]];
    
    [shipLaser runAction:moveLaserActionWithDone withKey:@"laserFired"];
    
}

-(float)randomValueBetween:(float)low andValue:(float)high
{
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

-(void)update:(CFTimeInterval)currentTime {
    
    [self enumerateChildNodesWithName:@"background" usingBlock:^(SKNode *node, BOOL *stop) {
        
        SKSpriteNode *bg = (SKSpriteNode *)node;
        bg.position = CGPointMake(bg.position.x - 5, bg.position.y);
        
        if (bg.position.x <= -bg.size.width) {
            bg.position = CGPointMake(bg.position.x + bg.size.width * 2, bg.position.y);
        }
        
    }];
    
    double curTime = CACurrentMediaTime();
    
    if (curTime > _nextFlappySpawn) {
        
        float randSeconds = [self randomValueBetween:0.20f andValue:1.0f];
        _nextFlappySpawn = randSeconds + curTime;
        
        float randY = [self randomValueBetween:0.0f andValue:self.frame.size.height];
        float randDuration = [self randomValueBetween:5.0f andValue:8.0f];
        
        SKSpriteNode *flappy = self.flappyArray[_nextFlappy];
        _nextFlappy++;
        
        if (_nextFlappy >= self.flappyArray.count) {
            _nextFlappy = 0;
        }
        
        [flappy removeAllActions];
        flappy.position = CGPointMake(self.frame.size.width + flappy.size.width / 2, randY);
        flappy.hidden = NO;
        
        CGPoint location = CGPointMake(-600, randY);
        
        SKAction *moveAction = [SKAction moveTo:location duration:randDuration];
        SKAction *doneAction = [SKAction runBlock:^{
            flappy.hidden = YES;
        }];
        
        SKAction *moveFlappyActionWithDone = [SKAction sequence:@[moveAction, doneAction]];
        
        [flappy runAction:moveFlappyActionWithDone];
    }
    
//    for (SKSpriteNode *flappy in self.flappyArray) {
//        if ([self.mainCharacter intersectsNode:flappy]) {
//            
//            
//            [self.mainCharacter removeFromParent];
//            
//            NSString *explosionPath = [[NSBundle mainBundle] pathForResource:@"Explosion" ofType:@"sks"];
//            SKEmitterNode *burstNode = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
//            
//            burstNode.position = self.mainCharacter.position;
//            [self addChild:burstNode];
//        }
//    }
    
}

@end
