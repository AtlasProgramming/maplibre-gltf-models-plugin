//
//  GLTFStatsView.m
//  MapLibreGLTFPlugin
//
//  Created by Malcolm Toon on 5/25/25.
//

#import "GLTFStatsView.h"

@interface GLTFStatsView() {
    
}
@property (weak) MLNGLTFPluginLayer *pluginLayer;

@property UILabel *totalVertexBytes;
@property UILabel *totalNumberOfTextures;
@property UILabel *totalTextureBytes;


@end

@implementation GLTFStatsView

-(id)initWithPluginLayer:(MLNGLTFPluginLayer *)pluginLayer {
    if (self = [super initWithFrame:CGRectMake(10,10,300,110)]) {
        self.pluginLayer = pluginLayer;
        [self createUI];
        [self updateStats];
        [self startTimer];
    }
    return self;
}

-(void)createUI {
    self.totalVertexBytes = [[UILabel alloc] initWithFrame:CGRectMake(10,10,300,30)];
    [self addSubview:self.totalVertexBytes];
    
    
    self.totalNumberOfTextures = [[UILabel alloc] initWithFrame:CGRectMake(10,40,300,30)];
    [self addSubview:self.totalNumberOfTextures];
    
    self.totalTextureBytes = [[UILabel alloc] initWithFrame:CGRectMake(10,70,300,30)];
    [self addSubview:self.totalTextureBytes];
    
    self.backgroundColor = [UIColor lightGrayColor];
    self.layer.cornerRadius = 4;
    self.layer.borderColor = [UIColor blackColor].CGColor;
    self.layer.borderWidth = 1;
}

-(void)startTimer {
    __weak GLTFStatsView *weakSelf = self;
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                    repeats:YES
                                      block:^(NSTimer * _Nonnull timer) {
        
        if (!weakSelf) {
            [timer invalidate];
            return;
        }
        
        [weakSelf updateStats];

    }];
}

-(void)updateStats {
    if (!self.pluginLayer) {
        return;
    }
    
    MLNGLTFPluginLayerStats *stats = [self.pluginLayer getLayerStats];
    float vertexMB = (float)stats.vertexMemory / (1024*1024);
    float textureMB = (float)stats.textureMemory / (1024*1024);

    self.totalVertexBytes.text = [NSString stringWithFormat:@"Vertex Memory: %0.2fmb", vertexMB];
    self.totalNumberOfTextures.text = [NSString stringWithFormat:@"Texture Count: %lu", stats.textureCount];
    self.totalTextureBytes.text = [NSString stringWithFormat:@"Texture Memory: %0.2fmb", textureMB];


}

@end
