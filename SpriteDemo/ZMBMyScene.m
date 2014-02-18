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
    double _gameOverTime;
    bool _gameOver;
}

@property (strong, nonatomic) SKSpriteNode *ship;
@property (strong, nonatomic) NSMutableArray *flappyArray;

#define kNumFlappys 8
#define kNumLasers 5

typedef enum {
    kEndReasonWin,
    kEndReasonLose
} EndReason;

@end

@implementation ZMBMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        _nextFlappy = 0;
        
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        for (int i = 0; i < 2; i++) {
            SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"starBackground"];
            bg.anchorPoint = CGPointZero;
            bg.position = CGPointMake(i * bg.size.width, 0);
            bg.name = @"starBackground";
            [self addChild:bg];
        }
        
        [self setupShip];
        
        self.ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.ship.size];
        self.ship.physicsBody.dynamic = YES;
        self.ship.physicsBody.affectedByGravity = NO;
        self.ship.physicsBody.mass = 0.02;
        
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
        
        [self startTheGame];
        
    }
    return self;
}

- (void)startTheGame
{
    _lives = 3;
    double curTime = CACurrentMediaTime();
    _gameOverTime = curTime + 30.0;
    _gameOver = NO;
    
    self.ship.hidden = NO;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
//    [self.mainCharacter.physicsBody setVelocity:CGVectorMake(0, 7)];
//    [self.mainCharacter.physicsBody applyImpulse:CGVectorMake(0, 7)];
    
    for (UITouch *touch in touches) {
        SKNode *n = [self nodeAtPoint:[touch locationInNode:self]];
        if (n != self && [n.name isEqual:@"restartLabel"]) {
            [[self childNodeWithName:@"restartLabel"] removeFromParent];
            [[self childNodeWithName:@"winLoseLabel"] removeFromParent];
            [self startTheGame];
            return;
        }
    }
    
    if (_gameOver) {
        return;
    }
    
    
    SKSpriteNode *shipLaser = [_shipLasers objectAtIndex:_nextShipLaser];
    _nextShipLaser++;
    if (_nextShipLaser >= _shipLasers.count) {
        _nextShipLaser = 0;
    }
    
    shipLaser.position = CGPointMake(self.ship.position.x + shipLaser.size.width/2, self.ship.position.y+0);
    shipLaser.hidden = NO;
    [shipLaser removeAllActions];
    
    CGPoint location = CGPointMake(self.frame.size.width, self.ship.position.y);
    SKAction *laserMoveAction = [SKAction moveTo:location duration:0.5];
    
    SKAction *laserDoneAction = [SKAction runBlock:(dispatch_block_t)^() {
        shipLaser.hidden = YES;
    }];
    
    SKAction *moveLaserActionWithDone = [SKAction sequence:@[laserMoveAction,laserDoneAction]];
    
    [shipLaser runAction:moveLaserActionWithDone withKey:@"laserFired"];
    
}

- (void)setupShip {
    self.shipFrames = [NSMutableArray array];
    
    SKTextureAtlas *shipAnimatedAtlas = [SKTextureAtlas atlasNamed:@"ship_Center"];
    
    // Add each frame of the ship animation to the ship frames array.
    for (int i = 1; i < shipAnimatedAtlas.textureNames.count + 1; i++) {
        NSString *textName = [NSString stringWithFormat:@"shipCenter_%d.png", i];
        SKTexture *texture = [shipAnimatedAtlas textureNamed:textName];
        [self.shipFrames addObject:texture];
    }
    
    SKTexture *texture = self.shipFrames[0];
    self.ship = [SKSpriteNode spriteNodeWithTexture:texture];
    self.ship.position = CGPointMake(50, CGRectGetMidY(self.frame));
    self.ship.size = CGSizeMake(self.ship.size.width / 2, self.ship.size.height / 2);
    [self addChild:self.ship];
    
    // Animate the ship.
    [self.ship runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:self.shipFrames
                                                                        timePerFrame:0.1f
                                                                              resize:NO
                                                                             restore:YES]] withKey:@"animatingShip"];
}

-(void)update:(CFTimeInterval)currentTime {
    
    [self enumerateChildNodesWithName:@"starBackground" usingBlock:^(SKNode *node, BOOL *stop) {
        
        SKSpriteNode *bg = (SKSpriteNode *)node;
        bg.position = CGPointMake(bg.position.x - 1.5, bg.position.y);
        
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
    
//    for (SKSpriteNode *flappy in _flappyArray) {
//        if (flappy.hidden) {
//            continue;
//        }
//        for (SKSpriteNode *shipLaser in _shipLasers) {
//            if (shipLaser.hidden) {
//                continue;
//            }
//            
//            if ([shipLaser intersectsNode:flappy]) {
//                shipLaser.hidden = YES;
//                flappy.hidden = YES;
//                
//                NSLog(@"you just destroyed a postmodern masterpiece");
//                continue;
//            }
//        }
//        if ([self.ship intersectsNode:flappy]) {
//            flappy.hidden = YES;
//            SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1], [SKAction fadeInWithDuration:0.1]]];
//            SKAction *blinkForTime = [SKAction repeatAction:blink count:4];
//            [self.ship runAction:blinkForTime];
//            _lives--;
//            NSLog(@"your face feels alienated");
//        }
//    }
    
    if (_lives <= 0) {
        NSLog(@"you lose :(");
        [self endTheScene:kEndReasonLose];
    } else if (curTime >= _gameOverTime) {
        NSLog(@"you win!");
        [self endTheScene:kEndReasonWin];
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

- (void)endTheScene:(EndReason)endReason {
    if (_gameOver) {
        return;
    }
    
    [self removeAllActions];
    self.ship.hidden = YES;
    _gameOver = YES;
    
    NSString *message;
    if (endReason == kEndReasonWin) {
        message = @"You win!";
    } else if (endReason == kEndReasonLose) {
        message = @"You Lose!";
    }
    
    SKLabelNode *label;
    label = [[SKLabelNode alloc] initWithFontNamed:@"Helvetica-CondensedMedium"];
    label.name = @"winLoseLabel";
    label.text = message;
    label.scale = 0.1;
    label.position = CGPointMake(self.frame.size.width/2, self.frame.size.height * 0.6);
    label.fontColor = [SKColor yellowColor];
    [self addChild:label];
    
    SKLabelNode *restartLabel;
    restartLabel = [[SKLabelNode alloc] initWithFontNamed:@"Helvetica-CondensedMedium"];
    restartLabel.name = @"restartLabel";
    restartLabel.text = @"Again?";
    restartLabel.scale = 0.5;
    restartLabel.position = CGPointMake(self.frame.size.width/2, self.frame.size.height * 0.4);
    restartLabel.fontColor = [SKColor yellowColor];
    [self addChild:restartLabel];
    
    SKAction *labelScaleAction = [SKAction scaleTo:1.0 duration:0.5];
    
    [restartLabel runAction:labelScaleAction];
    [label runAction:labelScaleAction];
    
}

-(float)randomValueBetween:(float)low andValue:(float)high
{
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

@end























