//
//  ViewController.m
//  MLGLTFPlugin
//
//  Created by Malcolm Toon on 5/16/25.
//

#import "ViewController.h"
#import <MapLibre/MapLibre.h>
#import <MapLibreGLTFPlugin/MapLibreGLTFPlugin.h>

@interface ViewController ()

@property MLNMapView *mapView;
@property NSURL *styleURL;
@property GLTFStatsView *statsView;
@property GLTFModelMetadata *animatedModel;
@end

@implementation ViewController

// This will add the plug-in layers.  This is a demo of how
// extensible layers for the style can be added to the map view
-(void)addPluginLayers {

   [self.mapView addPluginLayerType:[MLNGLTFPluginLayer class]];

}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView = [[MLNMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addPluginLayers];
    self.mapView.showsScale = YES;

    self.styleURL = [[NSBundle mainBundle] URLForResource:@"PluginLayerTestStyle.json" withExtension:nil];
    self.mapView.styleURL = self.styleURL;
    
    // Eiffel Tower
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(48.8584,
                                                                    2.2945)
                            zoomLevel:16
                             animated:NO];
    
    
    // Arc De Triomphe
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(48.8738,
                                                                 2.2950)
                            zoomLevel:16
                             animated:NO];
    
    
    
    self.mapView.allowsTilting = YES;
    self.mapView.pitchEnabled = YES;
    self.mapView.minimumPitch = 50;


    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addRasterLayer];
    });
}

-(void)addRasterLayer {
    
    NSString *maptilerKey = @"YOUR KEY HERE";

    NSString *streetsURL = [NSString stringWithFormat:@"https://api.maptiler.com/maps/streets-v2/tiles.json?key=%@", maptilerKey];
    NSString *satURL = [NSString stringWithFormat:@"https://api.maptiler.com/maps/satellite/tiles.json?key=%@", maptilerKey];

    NSURL *rasterURL = [NSURL URLWithString:satURL];
    
    MLNRasterTileSource *rasterTileSource = [[MLNRasterTileSource alloc] initWithIdentifier:@"my-raster-tile-source"
                                                                           configurationURL:rasterURL
                                                                                   tileSize:512];
    [self.mapView.style addSource:rasterTileSource];

    MLNRasterStyleLayer *rasterLayer = [[MLNRasterStyleLayer alloc] initWithIdentifier:@"my-raster-layer" source:rasterTileSource];
    rasterLayer.minimumZoomLevel = 0;
    rasterLayer.maximumZoomLevel = 24;
    rasterLayer.visible = YES;

    MLNStyleLayer *modelLayer = [self.mapView.style layerWithIdentifier:@"model-layer"];
    if (modelLayer) {
        [self.mapView.style insertLayer:rasterLayer belowLayer:modelLayer];
    }
    
    [self addStats];
    
   [self addAnimatedModel];

}

-(void)addStats {

    MLNStyleLayer *modelLayer = [self.mapView.style layerWithIdentifier:@"model-layer"];
    MLNPluginStyleLayer *psl = (MLNPluginStyleLayer *)modelLayer;
    MLNGLTFPluginLayer *pl = (MLNGLTFPluginLayer *)[psl pluginLayer];

    if (!self.statsView) {
        self.statsView = [[GLTFStatsView alloc] initWithPluginLayer:pl];
        [self.view addSubview:self.statsView];
    }
    
    
}

-(void)addAnimatedModel {
    
    MLNStyleLayer *modelLayer = [self.mapView.style layerWithIdentifier:@"model-layer"];
    MLNPluginStyleLayer *psl = (MLNPluginStyleLayer *)modelLayer;
    MLNGLTFPluginLayer *pl = (MLNGLTFPluginLayer *)[psl pluginLayer];
    
    // License for Cab: https://www.turbosquid.com/3d-models/3d-simple-futuristic-cab-2090-toy-car-model-1931586
    NSString *modelName = @"Cab2.glb";
    self.animatedModel = [pl loadModel:modelName
                                   lat:48.8738
                                   lon:2.2950
                           rotationDeg:0
                           scaleFactor:4.0
                            brightness:1.0];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.animatedModel animateToLocation:CLLocationCoordinate2DMake(48.8584,
                                                                         2.2945)
                                     duration:5.0];
    });
    
    
}






@end
