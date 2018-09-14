# ParticlesText
基于文本的粒子动画 -  Text diffusion animation consist of particles in iOS project

## Overview
* ParticlesText是一个基于指定文本，生成粒子聚合和扩散动画的视图
* 基于Metal
* 支持粒子密度，X轴，Y轴方向扩散程度，动画时长，粒子颜色等设置

## 基本使用
```
	self.particlesMTKView = [[ParticlesMTKView alloc] initWithBuilder:^(ParticlesBuilder *builder) {
        	builder.frame = CGRectMake(0, 160, CGRectGetWidth(self.view.bounds), 300);
        	builder.text = @"天青色等烟雨 而我在等你";
        	builder.font = [UIFont systemFontOfSize:60];
        	builder.density = 10;
        	builder.dispersionX = 2;
        	builder.dispersionY = 2;
        	builder.duration = 2.0;
        	builder.hexColor = @"#1de0f9";
        	builder.particleFinishType = ParticleFinishTypeShake;
    	}];
    [self.view addSubview:self.particlesMTKView];
    [self.particlesMTKView prepareAnimating];
    [self.particlesMTKView startAnimating];
```

## English-Version

## What is ParticlesText
* ParticlesText is a view that generates particle aggregation and diffusion animation based on specified text.
* Based on Metal
* Support particle density, X-axis, Y-axis diffusion degree, animation duration, particle color, etc.

