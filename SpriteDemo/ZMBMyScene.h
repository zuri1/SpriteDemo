//
//  ZMBMyScene.h
//  SpriteDemo
//

//  Copyright (c) 2014 Zuri Biringer. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SKShip.h"

@import AVFoundation;

@interface ZMBMyScene : SKScene <SKPhysicsContactDelegate> {
    AVAudioPlayer *backgroundAudioPlayer;
    
    BOOL shouldFire;
    float shipFireRate;
}

@property (strong, nonatomic) SKSpriteNode *ship;
@property (strong, nonatomic) NSMutableArray *asteroidArray;

@property (nonatomic, strong) NSMutableArray *shipFramesCenter;
@property (nonatomic, strong) NSMutableArray *shipFramesUp;
@property (nonatomic, strong) NSMutableArray *shipFramesDown;

- (void)setupShip;

@end
