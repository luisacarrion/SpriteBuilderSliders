//
//  GameState.m
//  Sliders
//
//  Created by Maria Luisa on 3/30/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "GameState.h"

@implementation GameState

+(id)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

@end
