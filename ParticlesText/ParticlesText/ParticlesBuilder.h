//
//  ParticlesBuilder.h
//  ParticlesOC
//
//  Created by roselzy on 2018/9/12.
//  Copyright © 2018 Rose LZY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ParticlesMTKView;

typedef NS_ENUM(int, ParticleFinishType) {
    ParticleFinishTypeStatic  = 0,
    ParticleFinishTypeShake   = 1,
    ParticleFinishTypeDiffuse = 2,
};

@interface ParticlesBuilder : NSObject
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) CGFloat density;
@property (nonatomic, assign) CGFloat dispersionX;
@property (nonatomic, assign) CGFloat dispersionY;
@property (nonatomic, assign) float duration;
@property (nonatomic, copy) NSString *hexColor;
@property (nonatomic, assign) BOOL adjustsFontSizeToFitWidth;
@property (nonatomic, assign) ParticleFinishType particleFinishType;
- (ParticlesMTKView *)build;
@end
