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

    
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(48.8584,
                                                                    2.2945)
                            zoomLevel:16
                             animated:NO];
    
}


@end
