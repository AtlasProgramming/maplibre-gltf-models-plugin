//
//  MLNGLTFPluginLayer.h
//  MapLibreGLTFPlugin
//
//  Created by Malcolm Toon on 5/16/25.
//

#import <UIKit/UIKit.h>
#import <MapLibre/MapLibre.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLNGLTFPluginLayerStats: NSObject

@property NSUInteger totalMemory;
@property NSUInteger textureMemory;
@property NSUInteger textureCount;
@property NSUInteger vertexMemory;


@end

@interface GLTFModelMetadata: NSObject {
    
}

@property NSString *modelPath;
@property CLLocationCoordinate2D modelCoordinate;
@property double modelRotation;
@property BOOL modelLoaded;
@property float modelScale;
@property float brightness;

-(void)animateToLocation:(CLLocationCoordinate2D)newLocation
                duration:(NSTimeInterval)duration;


@end

@interface MLNGLTFPluginLayer : MLNPluginLayer

// This sets the relative light position for all the models being rendered
// The light position is in meters from the origin of the model.
- (void)setLightPositionX:(float)x y:(float)y z:(float)z;

- (void)loadModelFromJSON:(NSString *)modelMetadataFilename;

- (GLTFModelMetadata *)loadModel:(NSString *)appResourceFilename
                  lat:(double)lat
                  lon:(double)lon
          rotationDeg:(double)rotationDeg
          scaleFactor:(float)scaleFactor
           brightness:(float)brightness;

- (MLNGLTFPluginLayerStats *)getLayerStats;


@end

NS_ASSUME_NONNULL_END
