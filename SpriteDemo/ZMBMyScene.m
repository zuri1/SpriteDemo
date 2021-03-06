//
//  ZMBMyScene.m
//  SpriteDemo
//
//  Created by Zuri Biringer on 2/17/14.
//  Copyright (c) 2014 Zuri Biringer. All rights reserved.
//

#import "ZMBMyScene.h"

#define kNumAsteroids 8
#define kNumLasers 5

@interface ZMBMyScene () 

{
    int _nextAsteroid;
    double _nextAsteroidSpawn;
    NSMutableArray *_shipLasers;
    int _nextShipLaser;
    int _lives;
    double _gameOverTime;
    bool _gameOver;
    
    BOOL shipIsDamaged;
}

typedef enum {
    kEndReasonWin,
    kEndReasonLose
} EndReason;

@end

@implementation ZMBMyScene

static const uint32_t laserCategory    = 0x1 << 0;
static const uint32_t shipCategory     = 0x1 << 1;
static const uint32_t asteroidCategory = 0x1 << 2;

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        _nextAsteroid = 0;
        
        self.physicsWorld.contactDelegate = self;
        
        [self setupPhysicsWorld];
        
        [self startBackgroundMusic];
        
        [self setupBoundsToScreen];
        
        [self setupShip];
        
        [self setupAsteroids];
        
        [self startTheGame];
        
    }
    return self;
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
    
    if (curTime > _nextAsteroidSpawn) {
        
        float randSeconds = [self randomValueBetween:0.20f andValue:1.0f];
        _nextAsteroidSpawn = randSeconds + curTime;
        
        float randY = [self randomValueBetween:0.0f andValue:self.frame.size.height];
        float randDuration = [self randomValueBetween:5.0f andValue:8.0f];
        
        SKSpriteNode *asteroid = self.asteroidArray[_nextAsteroid];
        _nextAsteroid++;
        
        if (_nextAsteroid >= self.asteroidArray.count) {
            _nextAsteroid = 0;
        }
        
        [asteroid removeAllActions];
        asteroid.position = CGPointMake(self.frame.size.width + asteroid.size.width / 2, randY);
        asteroid.hidden = NO;
        
        CGPoint location = CGPointMake(-600, randY * .3);
        
        SKAction *moveAction = [SKAction moveTo:location duration:randDuration];
        SKAction *doneAction = [SKAction runBlock:^{
            asteroid.hidden = YES;
        }];
        
        SKAction *moveAsteroidWithDone = [SKAction sequence:@[moveAction, doneAction]];
        
        [asteroid runAction:moveAsteroidWithDone];
    }
    
    //COLLISIONS
    for (SKSpriteNode *asteroid in self.asteroidArray) {
        if (asteroid.hidden) {
            continue;
        }
        for (SKSpriteNode *shipLaser in _shipLasers) {
            if (shipLaser.hidden) {
                continue;
            }
            
            if ([shipLaser intersectsNode:asteroid]) {
                shipLaser.hidden = YES;
                asteroid.hidden = YES;
                // Play the asteroid damage sound
                [self playAsteroidHitSound];
                continue;
            }
        }
    }
    
    if (_lives <= 0) {
        [self endTheScene:kEndReasonLose];
    } else if (curTime >= _gameOverTime) {
        [self endTheScene:kEndReasonWin];
    }
}

- (void)setupBoundsToScreen {
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    for (int i = 0; i < 2; i++) {
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"starBackground"];
        bg.anchorPoint = CGPointZero;
        bg.position = CGPointMake(i * bg.size.width, 0);
        bg.name = @"starBackground";
        [self addChild:bg];
    }
}

#pragma mark - Setup ship

- (void)setupShip {
    self.shipFramesCenter = [NSMutableArray array];
    self.shipFramesUp     = [NSMutableArray array];
    self.shipFramesDown   = [NSMutableArray array];
    
    SKTextureAtlas *shipAnimatedCenterAtlas = [SKTextureAtlas atlasNamed:@"ship_Center"];
    SKTextureAtlas *shipAnimatedDownAtlas   = [SKTextureAtlas atlasNamed:@"ship_Down"];
    SKTextureAtlas *shipAnimatedUpAtlas     = [SKTextureAtlas atlasNamed:@"ship_Up"];
    
    // Add each frame of the ship animation to the ship frames array. (Once for each ship position).
    
    // Center frames
    for (int i = 1; i < shipAnimatedCenterAtlas.textureNames.count + 1; i++) {
        NSString *textName = [NSString stringWithFormat:@"shipCenter_%d.png", i];
        SKTexture *texture = [shipAnimatedCenterAtlas textureNamed:textName];
        [self.shipFramesCenter addObject:texture];
    }
    
    // Down frames
    for (int i = 1; i < shipAnimatedDownAtlas.textureNames.count + 1; i++) {
        NSString *textName = [NSString stringWithFormat:@"shipDown_%d.png", i];
        SKTexture *texture = [shipAnimatedDownAtlas textureNamed:textName];
        [self.shipFramesDown addObject:texture];
    }
    
    // Up frames
    for (int i = 1; i < shipAnimatedUpAtlas.textureNames.count + 1; i++) {
        NSString *textName = [NSString stringWithFormat:@"shipUp_%d.png", i];
        SKTexture *texture = [shipAnimatedUpAtlas textureNamed:textName];
        [self.shipFramesUp addObject:texture];
    }
    
    SKTexture *texture = self.shipFramesCenter[0];
    self.ship = [SKSpriteNode spriteNodeWithTexture:texture];
    self.ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.ship.size];
    self.ship.physicsBody.dynamic = YES;
    self.ship.physicsBody.allowsRotation = NO;
    self.ship.physicsBody.affectedByGravity = NO;
    self.ship.physicsBody.categoryBitMask = shipCategory;
    self.ship.physicsBody.collisionBitMask = 0x0;
    self.ship.physicsBody.contactTestBitMask = asteroidCategory;
    self.ship.position = CGPointMake(50, CGRectGetMidY(self.frame));
    self.ship.size = CGSizeMake(self.ship.size.width / 2, self.ship.size.height / 2);
    self.ship.name = @"ship";
    shipIsDamaged = NO;
    shouldFire = NO;
    shipFireRate = 0.5f;
    
    [self addChild:self.ship];
    
    // Animate the ship.
    [self.ship runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:self.shipFramesCenter
                                                                        timePerFrame:0.1f
                                                                              resize:NO
                                                                             restore:YES]] withKey:@"animatingShipCenter"];
    
    [self setupLasers];
}

- (void)setupLasers {
    _shipLasers = [[NSMutableArray alloc] initWithCapacity:kNumLasers];
    for (int i = 0; i < kNumLasers; i++) {
        SKSpriteNode *shipLaser = [SKSpriteNode spriteNodeWithImageNamed:@"laserbeam_blue"];
        shipLaser.hidden = YES;
        shipLaser.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:shipLaser.size];
        shipLaser.physicsBody.dynamic = NO;
        shipLaser.physicsBody.allowsRotation = NO;
        shipLaser.physicsBody.affectedByGravity = NO;
        shipLaser.physicsBody.categoryBitMask = laserCategory;
        shipLaser.physicsBody.collisionBitMask = asteroidCategory;
        shipLaser.physicsBody.contactTestBitMask = asteroidCategory;
        shipLaser.name = @"laser";
        [_shipLasers addObject:shipLaser];
        [self addChild:shipLaser];
    }
    
    for (SKSpriteNode *laser in _shipLasers) {
        laser.hidden = YES;
    }
}

- (void)fireWeapon {
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
    [self playLaserSound];
}

#pragma mark - Setup enemies

- (void)setupAsteroids {
    self.asteroidArray = [[NSMutableArray alloc] initWithCapacity:kNumAsteroids];
    
    for (int i = 0; i < kNumAsteroids; i++) {
        SKSpriteNode *asteroid = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_01"];
        asteroid.position = CGPointMake(700, 100);
        asteroid.hidden = YES;
        
        // Setup the asteroid's physics body.
        asteroid.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:asteroid.size];
        asteroid.physicsBody.dynamic = NO;
        asteroid.physicsBody.allowsRotation = NO;
        asteroid.physicsBody.categoryBitMask  = asteroidCategory;
        asteroid.physicsBody.collisionBitMask =  0x0;
        asteroid.physicsBody.contactTestBitMask = shipCategory | laserCategory;
        asteroid.name = @"asteroid";
        
        [self.asteroidArray addObject:asteroid];
        [self addChild:asteroid];
    }
}

- (void)startTheGame
{
    _lives = 3;
    double curTime = CACurrentMediaTime();
    _gameOverTime = curTime + 30.0;
    _gameOver = NO;
    
    self.ship.hidden = NO;
}

#pragma mark - Touch Methods

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    CGPoint positionInScene  = [touch locationInNode:self];
    CGPoint previousPosition = [touch previousLocationInNode:self];
    CGPoint translation = CGPointMake(positionInScene.x - previousPosition.x,
                                      positionInScene.y - previousPosition.y);
    
    // Animate the ship up or down based on finger position.
    [self moveShipWithTranslation:translation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // When the user releases the screen, the ship should stop firing.
    shouldFire = NO;
    
    [self.ship removeActionForKey:@"animatingShipUp"];
    [self.ship removeActionForKey:@"animatingShipDown"];
    [self.ship runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:self.shipFramesCenter
                                                                        timePerFrame:0.1f
                                                                              resize:NO
                                                                             restore:YES]] withKey:@"animatingShipCenter"];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        SKNode *n = [self nodeAtPoint:[touch locationInNode:self]];
        if (n != self && [n.name isEqual:@"restartLabel"]) {
            [[self childNodeWithName:@"restartLabel"] removeFromParent];
            [[self childNodeWithName:@"winLoseLabel"] removeFromParent];
            [self startTheGame];
            return;
        }
    }
    
    // When the user touches the screen, the ship should start firing.
    shouldFire = YES;
    
    if (_gameOver) {
        return;
    }
    
    [self fireWeapon];
}

#pragma mark - Run Loop

- (void)moveShipWithTranslation:(CGPoint)translation {
    // Animate the ship up or down based on finger position.
    
    [self.ship runAction:[SKAction sequence:@[[SKAction moveByX:0 y:translation.y duration:0.4f]]]];
    
    // Change the animation based on up or down movement.
    if (translation.y >= 0) {
        [self.ship removeActionForKey:@"animatingShipCenter"];
        [self.ship runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:self.shipFramesUp
                                                                            timePerFrame:0.1f
                                                                                  resize:NO
                                                                                 restore:YES]] withKey:@"animatingShipUp"];
    } else if (translation.y < 0) {
        [self.ship removeActionForKey:@"animatingShipCenter"];
        [self.ship runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:self.shipFramesDown
                                                                            timePerFrame:0.1f
                                                                                  resize:NO
                                                                                 restore:YES]] withKey:@"animatingShipDown"];
    }
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

#pragma mark - Physic World Delegate

- (void)setupPhysicsWorld {
    self.physicsWorld.contactDelegate   = self;
    self.physicsBody.contactTestBitMask = 0x0;
    self.physicsBody.collisionBitMask   = 0x0;
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody, *secondBody;
    NSLog(@"contact: %@", contact);
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
        
        NSLog(@"firstBody: %@", firstBody);
        NSLog(@"secondBody: %@", secondBody);
        
        // If the first body is the ship.
        if ((firstBody.categoryBitMask == shipCategory || secondBody.categoryBitMask == shipCategory) && shipIsDamaged == NO && !secondBody.node.hidden) {
            if (!firstBody.node.hidden || !secondBody.node.hidden) {
                [self shipTookDamage];
            }
            
            
            // If second body is an asteroid
            if (secondBody.categoryBitMask == asteroidCategory) {
                secondBody.node.hidden = YES;
            }
        }
        
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
        NSLog(@"firstBody: %@", firstBody);
        NSLog(@"secondBody: %@", secondBody);
    }
    
    if ((firstBody.categoryBitMask & laserCategory) != 0) {
        
    }
}

- (void)shipTookDamage {
    shipIsDamaged = YES;
    
    SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1], [SKAction fadeInWithDuration:0.1]]];
    SKAction *blinkForTime = [SKAction repeatAction:blink count:4];
    [self.ship runAction:blinkForTime completion:^{
        shipIsDamaged = NO;
    }];
//    _lives--;
    [self playShipDamageSound];
}

#pragma -
#pragma mark - Music

- (void)startBackgroundMusic {
    NSError *error;
    NSURL *file = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"spaceTheme" ofType:@"mp3"]];
    
    backgroundAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:&error];
    if (error) {
        NSLog(@"error in audio player: %@", error.localizedDescription);
        return;
    }
    
    [backgroundAudioPlayer prepareToPlay];
    
    // This will play the music infinitely
    backgroundAudioPlayer.numberOfLoops = -1;
    [backgroundAudioPlayer setVolume:1.0];
    [backgroundAudioPlayer play];
}

#pragma mark - Sound Effects

- (void)playAsteroidHitSound {
    [self runAction:[SKAction playSoundFileNamed:@"hurt_asteroid_01.wav" waitForCompletion:NO]];
}

- (void)playLaserSound {
    [self runAction:[SKAction playSoundFileNamed:@"laser_shoot_01.wav" waitForCompletion:NO]];
}

- (void)playShipDamageSound {
    [self runAction:[SKAction playSoundFileNamed:@"hurt_ship_01.wav" waitForCompletion:NO]];
}

-(float)randomValueBetween:(float)low andValue:(float)high
{
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

@end























