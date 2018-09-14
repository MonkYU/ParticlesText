//
//  ViewController.m
//  ParticlesText
//
//  Created by roselzy on 2018/9/14.
//  Copyright © 2018 Rose LZY. All rights reserved.
//

#import "ViewController.h"
#import "NSString+Path.h"
#import "ParticlesMTKView.h"

@interface ViewController ()
@property (nonatomic, strong) ParticlesMTKView *particlesMTKView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homingAnimationFinished) name:ParticlesHomingAnimationFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(diffusingAnimationFinished) name:ParticlesDiffuseAnimationFinishedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.particlesMTKView = [[ParticlesMTKView alloc] initWithBuilder:^(ParticlesBuilder *builder) {
        builder.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 300);
        builder.text = @"天青色等烟雨 而我在等你";
        builder.font = [UIFont systemFontOfSize:60];
        builder.density = 10;
        builder.dispersionX = 2;
        builder.dispersionY = 2;
        builder.duration = 2.0;
        builder.hexColor = @"#1de0f9";
        builder.particleFinishType = ParticleFinishTypeDiffuse;
    }];
    [self.particlesMTKView prepareAnimating];
    [self.view addSubview:self.particlesMTKView];
    [self.particlesMTKView startAnimating];
}

- (void)homingAnimationFinished {
    NSLog(@"homing");
}

- (void)diffusingAnimationFinished {
    NSLog(@"diffusing");
}


@end
