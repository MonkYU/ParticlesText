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
@property (nonatomic, assign) CGFloat density; // 粒子密度 0 - 无粒子 1 - 满粒子
@property (nonatomic, assign) CGFloat dispersionX; // 分散度 0 - 不分散 1 - 最大分散
@property (nonatomic, assign) CGFloat dispersionY; // 分散度 0 - 不分散 1 - 最大分散
@property (nonatomic, assign) float duration;  // 粒子效果持续时间
@property (nonatomic, copy) NSString *hexColor; // 粒子颜色
@property (nonatomic, assign) ParticleFinishType particleFinishType; // 粒子完成归位动画后的事件类型
- (ParticlesMTKView *)build;
@end
