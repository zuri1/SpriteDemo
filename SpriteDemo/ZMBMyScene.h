//
//  ZMBMyScene.h
//  SpriteDemo
//

//  Copyright (c) 2014 Zuri Biringer. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@import AVFoundation;

@interface ZMBMyScene : SKScene {
    AVAudioPlayer *backgroundAudioPlayer;
}

@property (nonatomic, strong) NSMutableArray *shipFramesCenter;
@property (nonatomic, strong) NSMutableArray *shipFramesUp;
@property (nonatomic, strong) NSMutableArray *shipFramesDown;

- (void)setupShip;

@end
