//
//  ParticlesMTKView.h
//  ParticlesOC
//
//  Created by roselzy on 2018/9/5.
//  Copyright © 2018 Rose LZY. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import "ParticlesBuilder.h"

static NSString *const ParticlesHomingAnimationFinishedNotification = @"ParticlesHomingAnimationFinishedNotification";
static NSString *const ParticlesDiffuseAnimationFinishedNotification = @"ParticlesDiffuseAnimationFinishedNotification";

@interface ParticlesMTKView : MTKView
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) NSInteger density; // 粒子密度 1 - 10%的粒子数 10 - 100%粒子
@property (nonatomic, assign) CGFloat dispersionX; // 分散度 0 - 不分散 1 - 最大分散
@property (nonatomic, assign) CGFloat dispersionY; // 分散度 0 - 不分散 1 - 最大分散
@property (nonatomic, assign) float32_t duration;  // 粒子效果持续时间
@property (nonatomic, copy) NSString *hexColor; // 粒子颜色
@property (nonatomic, assign) ParticleFinishType particleFinishType; // 粒子完成归位动画后的事件类型
- (instancetype)initWithBuilder:(void(^)(ParticlesBuilder *builder))handler;
- (void)prepareAnimating;
- (void)startAnimating;
@end
