//
//  ParticlesMTKView.m
//  ParticlesOC
//
//  Created by roselzy on 2018/9/5.
//  Copyright © 2018 Rose LZY. All rights reserved.
//

@import AVFoundation;
@import AssetsLibrary;
#import "ParticlesMTKView.h"

struct Vector4 {
    float32_t x;
    float32_t y;
    float32_t z;
    float32_t w;
};

struct Particle {
    struct Vector4 particle;
};

struct ParticleColor {
    float32_t r;
    float32_t g;
    float32_t b;
    float32_t a;
};

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )

@interface ParticlesMTKView ()
@property (nonatomic, assign) NSInteger particlesCount;
@property (nonatomic, copy) NSArray *textPoints;

@property (nonatomic, strong) id<MTLBuffer> widthBuffer;
@property (nonatomic, strong) id<MTLBuffer> heightBuffer;

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipelineState;

@property (nonatomic, assign) NSInteger particlesMemoryByteSize;
@property (nonatomic, strong) id<MTLBuffer> particlesBuffer;
@property (nonatomic, strong) id<MTLBuffer> colorBuffer;
@property (nonatomic, strong) id<MTLBuffer> originParticlesPositionBuffer;
@property (nonatomic, strong) id<MTLBuffer> dislocationParticlesPositionBuffer;
@property (nonatomic, strong) id<MTLBuffer> durationBuffer;

@property (nonatomic, assign) MTLSize threadsPerThreadGroup;
@property (nonatomic, assign) MTLSize threadGroupsPerGrid;

@property (nonatomic, assign) MTLRegion region;
@property (nonatomic, assign) void *blankData;
@property (nonatomic, assign) NSUInteger bytesPerRow;

@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@property (nonatomic, assign) NSInteger particleInterval;
@property (nonatomic, assign) NSUInteger existParticlesCount;

@property (nonatomic, assign) int isFinishHomingAnimation;
@property (nonatomic, assign) int isFinishDiffuseAnimation;
@property (nonatomic, strong) id<MTLBuffer> finishHomingStateBuffer;
@property (nonatomic, strong) id<MTLBuffer> finishDiffuseStateBuffer;

@property (nonatomic, strong) id<MTLBuffer> particleFinishTypeBuffer;

@property (nonatomic, assign) int startDiffuseFlag;
@property (nonatomic, strong) id<MTLBuffer> diffuseFlagBuffer;

@property (nonatomic, assign) BOOL shouldStart;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) float randomDisplacement;
@property (nonatomic, strong) id<MTLBuffer> randomDisplacementBuffer;

@property (nonatomic, strong) UIImageView *testView;
@property (nonatomic, assign) NSInteger renderCount;
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput *writerInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic, copy) NSString *myPathDocs;
@end

@implementation ParticlesMTKView

- (instancetype)initWithBuilder:(void (^)(ParticlesBuilder *))handler {
    ParticlesBuilder *builder = [[ParticlesBuilder alloc] init];
    handler(builder);
    return [builder build];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.concurrentQueue = dispatch_queue_create("concurrent.particles.com", DISPATCH_QUEUE_CONCURRENT);
        self.testView = [[UIImageView alloc] initWithImage:nil];
        self.renderCount = 0;
    }
    return self;
}

- (void)prepareAnimating {
    self.isFinishHomingAnimation = 0;
    self.isFinishDiffuseAnimation = 0;
    self.startDiffuseFlag = 0;
    self.shouldStart = NO;
    self.randomDisplacement = (drand48() - 0.5) * 8;
    self.layer.opaque = NO;
    [self initComponents];
}

- (void)initComponents {
    [self initDevice];
    [self initExtraProperty];
    [self initParticlesColor];
    [self initDrawable];
    [self initPointers];
    [self initParticlesPoints];
    [self initComputePipelineState];
    [self updatePointsPosition];
    [self addSubview:self.testView];
    self.testView.frame = CGRectMake(0, 300, 100, 100);
    self.testView.backgroundColor = [UIColor clearColor];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    self.myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"NES-%d.mov",arc4random() % 1000]];
}

- (void)initDevice {
    self.device = MTLCreateSystemDefaultDevice();
    self.framebufferOnly = NO;
    self.commandQueue = [self.device newCommandQueue];
}

- (void)initExtraProperty {
    self.finishHomingStateBuffer = [self.device newBufferWithBytes:&_isFinishHomingAnimation length:sizeof(int) options:MTLResourceCPUCacheModeWriteCombined];
    self.finishDiffuseStateBuffer = [self.device newBufferWithBytes:&_isFinishDiffuseAnimation length:sizeof(int) options:MTLResourceCPUCacheModeWriteCombined];
}

- (void)initParticlesColor {
    if([self.hexColor hasPrefix:@"#"]) {
        self.hexColor = [self.hexColor stringByReplacingOccurrencesOfString:@"#" withString:@""];
    }else if ([self.hexColor hasPrefix:@"0x"]) {
        self.hexColor = [self.hexColor stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    }
    unsigned int red, green, blue;
    NSRange range;
    range.length = 2;
    range.location = 0;
    [[NSScanner scannerWithString:[self.hexColor substringWithRange:range]] scanHexInt:&red];
    range.location = 2;
    [[NSScanner scannerWithString:[self.hexColor substringWithRange:range]] scanHexInt:&green];
    range.location = 4;
    [[NSScanner scannerWithString:[self.hexColor substringWithRange:range]] scanHexInt:&blue];
    struct ParticleColor particleColor = {(float)(red / 255.0f), (float)(green / 255.0f), (float)(blue / 255.0f), (float)(1.0)};
    self.colorBuffer = [self.device newBufferWithBytes:&particleColor length:sizeof(struct ParticleColor) options:MTLResourceCPUCacheModeWriteCombined];
    self.particleFinishTypeBuffer = [self.device newBufferWithBytes:&_particleFinishType length:sizeof(int) options:MTLResourceCPUCacheModeWriteCombined];
}

- (void)initDrawable {
    CGFloat scale = [UIScreen mainScreen].scale;
    if (self.window) {
        scale = self.window.screen.scale;
    }
    CGSize drawableSize = self.bounds.size;
    drawableSize.width *= scale;
    drawableSize.height *= scale;
    self.drawableSize = drawableSize;
}

- (void)initPointers {
    CGFloat scale = [UIScreen mainScreen].scale;
    if (self.window) {
        scale = self.window.screen.scale;
    }

    CGSize blankSize = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
    self.region = MTLRegionMake2D(0, 0, blankSize.width, blankSize.height);
    self.blankData = calloc(1, blankSize.width * blankSize.height * 4);
    self.bytesPerRow = 4 * blankSize.width;

    NSUInteger labelWidth = 0;
    NSUInteger labelHeight = 0;
    CGRect rect = [self.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: self.font, NSForegroundColorAttributeName: [UIColor blackColor]} context:nil];
    labelWidth = ceilf(CGRectGetWidth(rect));
    if (labelWidth % 4 != 0) {
        NSInteger mod = labelWidth / 4;
        labelWidth = (mod + 1) * 4;
    }
    labelHeight = CGRectGetHeight(self.bounds);
    UILabel *placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, labelHeight)];
    placeLabel.numberOfLines = 0;
    placeLabel.backgroundColor = [UIColor whiteColor];
    placeLabel.text = self.text;
    placeLabel.font = self.font;
    placeLabel.textColor = [UIColor blackColor];
    if (self.adjustsFontSizeToFitWidth) {
        placeLabel.adjustsFontSizeToFitWidth = YES;
    }
    UIImage *image = [self imageFromView:placeLabel];
    NSUInteger imageWidth = CGImageGetWidth(image.CGImage);
    NSUInteger imageHeight = CGImageGetHeight(image.CGImage);
    uint32_t *pixelData = [self pixelDataFromImage:image];
    NSMutableArray *points = [NSMutableArray arrayWithCapacity:1];
    for (NSInteger i = 0; i < imageHeight; i++) {
        for (NSInteger j = 0; j < imageWidth; j++) {
            uint32_t color = *pixelData;
            CGFloat r = R(color) / 255.0f;
            CGFloat g = G(color) / 255.0f;
            CGFloat b = B(color) / 255.0f;
            if (r == 0.0 && g == 0.0 && b == 0.0) {
                [points addObject:[NSValue valueWithCGPoint:CGPointMake(j + self.frame.origin.x, i)]];
            }
            pixelData++;
        }
    }
    self.textPoints = [points copy];
    
    if (self.density < 1 || self.density > 10) {
        [NSException raise:@"Invalid density value" format:@"Particle density must between 1 and 10"];
    }
    if (self.density == 10) {
        self.particlesCount = self.textPoints.count;
        self.particleInterval = 1;
        self.existParticlesCount = self.particlesCount;
    }else { // 比如是 1  舍弃 90% 的粒子
        self.particlesCount = self.textPoints.count;
        self.particleInterval = 20 / self.density; // 数组越界问题
        NSInteger mod = (self.particlesCount) / self.particleInterval;
        if (mod == 0) {
            self.existParticlesCount = (self.particlesCount) / self.particleInterval;
        }else {
            self.existParticlesCount = (self.particlesCount) / self.particleInterval + 1;
        }
    }
    NSInteger mod = self.existParticlesCount % 4;
    if(mod != 0) {
        self.existParticlesCount = (self.existParticlesCount / 4 + 1) * 4;
    }
    self.particlesMemoryByteSize = self.existParticlesCount * sizeof(struct Particle);
}

- (void)initParticlesPoints {
    struct Particle *particles = malloc(self.existParticlesCount * sizeof(struct Particle));
    struct Particle *originParticles = malloc(self.existParticlesCount * sizeof(struct Particle));
    struct Particle *dislocationParticles = malloc(self.existParticlesCount * sizeof(struct Particle));
    
    memset(particles, 0, self.existParticlesCount * sizeof(struct Particle));
    memset(originParticles, 0, self.existParticlesCount * sizeof(struct Particle));
    memset(dislocationParticles, 0, self.existParticlesCount * sizeof(struct Particle));
    NSInteger tempParticleIndex = 0;
    for (NSInteger i = 0; i < self.existParticlesCount; i++) {
        CGPoint point = [[self.textPoints objectAtIndex:tempParticleIndex % self.textPoints.count] CGPointValue];
        tempParticleIndex = tempParticleIndex + self.particleInterval;
        struct Particle originParticle = { point.x, point.y, [self rand], [self rand] };
        float32_t randomDisX = [self randomX];
        float32_t randomDisY = [self randomY];
        point.x += randomDisX;
        point.y += randomDisY;
        struct Particle singleParticle = { point.x, point.y, [self rand], [self rand] };
        particles[i] = singleParticle;
        originParticles[i] = originParticle;
        dislocationParticles[i] = singleParticle;
    }
    self.particlesBuffer = [self.device newBufferWithBytes:particles length:self.particlesMemoryByteSize options:MTLResourceCPUCacheModeWriteCombined];
    self.originParticlesPositionBuffer = [self.device newBufferWithBytes:originParticles length:self.particlesMemoryByteSize options:MTLResourceCPUCacheModeWriteCombined];
    self.dislocationParticlesPositionBuffer = [self.device newBufferWithBytes:particles length:self.particlesMemoryByteSize options:MTLResourceCPUCacheModeDefaultCache];
    /// 做资源copy；
    free(particles);
    free(originParticles);
    free(dislocationParticles);
    self.durationBuffer = [self.device newBufferWithBytes:&_duration length:sizeof(float32_t) options:MTLResourceCPUCacheModeWriteCombined];
    self.diffuseFlagBuffer = [self.device newBufferWithBytes:&_startDiffuseFlag length:sizeof(int) options:MTLResourceCPUCacheModeWriteCombined];
    
}

- (void)initComputePipelineState {
    self.library = [self.device newDefaultLibrary];
    id<MTLFunction> kernelFunction = [self.library newFunctionWithName:@"particleRendererShader"];
    NSError *error;
    self.computePipelineState = [self.device newComputePipelineStateWithFunction:kernelFunction error:&error];
    if (error) {
        NSLog(@"newComputePipelineStateWithFunction error");
    }
    float32_t width = self.drawableSize.width;
    float32_t height = self.drawableSize.height;
    
    NSUInteger threadExecutionWidth = self.computePipelineState.threadExecutionWidth;
    self.threadsPerThreadGroup = MTLSizeMake(threadExecutionWidth, 1, 1);
    self.threadGroupsPerGrid = MTLSizeMake(self.existParticlesCount / threadExecutionWidth, 1, 1);
    NSLog(@"width: %f height: %f",width, height);
    self.widthBuffer = [self.device newBufferWithBytes:&width length:sizeof(float32_t) options:MTLResourceOptionCPUCacheModeWriteCombined];
    self.heightBuffer = [self.device newBufferWithBytes:&height length:sizeof(float32_t) options:MTLResourceOptionCPUCacheModeWriteCombined];
    self.randomDisplacementBuffer = [self.device newBufferWithBytes:&_randomDisplacement length:sizeof(float32_t) options:MTLResourceOptionCPUCacheModeWriteCombined];
}

- (void)updatePointsPosition {
    [self update];
}

- (void)update {
    @autoreleasepool {
        id<CAMetalDrawable> nextDrawable = self.currentDrawable;
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        [computeEncoder setComputePipelineState:self.computePipelineState];
        [computeEncoder setBuffer:self.particlesBuffer offset:0 atIndex:0];
        [computeEncoder setBuffer:self.particlesBuffer offset:0 atIndex:1];
        [computeEncoder setBuffer:self.originParticlesPositionBuffer offset:0 atIndex:2];
        [computeEncoder setBuffer:self.widthBuffer offset:0 atIndex:3];
        [computeEncoder setBuffer:self.heightBuffer offset:0 atIndex:4];
        [computeEncoder setBuffer:self.colorBuffer offset:0 atIndex:5];
        [computeEncoder setBuffer:self.durationBuffer offset:0 atIndex:6];
        [computeEncoder setBuffer:self.dislocationParticlesPositionBuffer offset:0 atIndex:7];
        [computeEncoder setBuffer:self.finishHomingStateBuffer offset:0 atIndex:8];
        [computeEncoder setBuffer:self.finishHomingStateBuffer offset:0 atIndex:9];
        [computeEncoder setBuffer:self.finishDiffuseStateBuffer offset:0 atIndex:9];
        [computeEncoder setBuffer:self.particleFinishTypeBuffer offset:0 atIndex:10];
        [computeEncoder setBuffer:self.diffuseFlagBuffer offset:0 atIndex:11];
        [computeEncoder setBuffer:self.randomDisplacementBuffer offset:0 atIndex:12];
        [nextDrawable.texture replaceRegion:self.region mipmapLevel:0 withBytes:self.blankData bytesPerRow:self.bytesPerRow];
        [computeEncoder setTexture:nextDrawable.texture atIndex:0];
        [computeEncoder dispatchThreadgroups:self.threadGroupsPerGrid threadsPerThreadgroup:self.threadsPerThreadGroup];
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull commandBuffer) {
            id<MTLTexture> texture = nextDrawable.texture;
            CIImage *ciimage = [CIImage imageWithMTLTexture:texture options:nil];
            UIImage *image = [UIImage imageWithCIImage:ciimage];
            [self writeToFile:texture];
            self.renderCount += 1;
        }];
        
        [computeEncoder endEncoding];
        [commandBuffer presentDrawable:nextDrawable];
        [commandBuffer commit];
    }
}

- (void)startAnimating {
    self.shouldStart = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.duration * 1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isFinishHomingAnimation = 1;
        self.finishHomingStateBuffer = [self.device newBufferWithBytes:&self->_isFinishHomingAnimation length:sizeof(int) options:MTLResourceCPUCacheModeWriteCombined];
        [[NSNotificationCenter defaultCenter] postNotificationName:ParticlesHomingAnimationFinishedNotification object:nil];
        if (self.particleFinishType == ParticleFinishTypeStatic) {
            self.shouldStart = NO;
        }else if (self.particleFinishType == ParticleFinishTypeShake) {
            self.shouldStart = YES;
        }else if (self.particleFinishType == ParticleFinishTypeDiffuse) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.startDiffuseFlag = 1;
                self.diffuseFlagBuffer = [self.device newBufferWithBytes:&self->_startDiffuseFlag length:sizeof(int) options:MTLResourceCPUCacheModeWriteCombined];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.isFinishDiffuseAnimation = 1;
                    self.finishDiffuseStateBuffer = [self.device newBufferWithBytes:&self->_isFinishDiffuseAnimation length:sizeof(int) options:MTLResourceCPUCacheModeWriteCombined];
                    [[NSNotificationCenter defaultCenter] postNotificationName:ParticlesDiffuseAnimationFinishedNotification object:nil];
                    self.shouldStart = NO;
                });
            });
        }
    });
}

- (void)startParticlesEffect {
    [self updatePointsPosition];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    self.randomDisplacement = (drand48() - 0.5) * 4;
    self.randomDisplacementBuffer = [self.device newBufferWithBytes:&_randomDisplacement length:sizeof(float32_t) options:MTLResourceOptionCPUCacheModeWriteCombined];
    if(self.shouldStart) {
        [self startParticlesEffect];
    }
}

- (float32_t)randomDisplacement {
    return (drand48() - 0.5) * arc4random_uniform(20);
}

- (float32_t)rand {
    return (drand48() - 0.5) * 0.005;
}

- (float32_t)randomX {
    return (drand48() - 0.5) * [UIScreen mainScreen].bounds.size.width * self.dispersionX;
}

- (float32_t)randomY {
    return (drand48() - 0.5) * [UIScreen mainScreen].bounds.size.height * self.dispersionY;
}

- (UIImage *)imageFromView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (uint32_t *)pixelDataFromImage:(UIImage *)image {
    NSData *pixelData = CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage)));
    uint32_t *bytes = (uint32_t *)pixelData.bytes;
    return bytes;
}

- (void)writeToFile:(id<MTLTexture>)texture {
    if (self.renderCount == 1) {
        NSError *error;
        self.videoWriter = [[AVAssetWriter alloc] initWithURL: [NSURL fileURLWithPath:self.myPathDocs] fileType:AVFileTypeQuickTimeMovie error:&error];
        if(error) {
            NSLog(@"error creating AssetWriter: %@",[error description]);
        }
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecTypeH264, AVVideoCodecKey,
                                       [NSNumber numberWithInteger:[texture width]], AVVideoWidthKey,
                                       [NSNumber numberWithInteger:[texture height]], AVVideoHeightKey,
                                       nil];
        AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                           assetWriterInputWithMediaType:AVMediaTypeVideo
                                           outputSettings:videoSettings];
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
        [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        [attributes setObject:[NSNumber numberWithInteger:[texture width]] forKey:(NSString*)kCVPixelBufferWidthKey];
        [attributes setObject:[NSNumber numberWithInteger:[texture height]] forKey:(NSString*)kCVPixelBufferHeightKey];
        self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:attributes];
        [self.videoWriter addInput:writerInput];
        self.writerInput.expectsMediaDataInRealTime = YES;
        BOOL start = [self.videoWriter startWriting];
        [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    }
    
}

- (void)finishWriting {
    [self.writerInput markAsFinished];
    [self.videoWriter finishWritingWithCompletionHandler:^{
        
    }];
    
    CVPixelBufferPoolRelease(self.adaptor.pixelBufferPool);
    
    NSURL *outputURL = [NSURL URLWithString:self.myPathDocs];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            });
        }];
    }
}

@end
