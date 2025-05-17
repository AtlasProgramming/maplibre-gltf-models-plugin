//
//  MLNGLTFPluginLayer.m
//  MapLibreGLTFPlugin
//
//  Created by Malcolm Toon on 5/16/25.
//

#import "MLNGLTFPluginLayer.h"
#import <Metal/Metal.h>
//#import "MLNBackendResource.h"
#import <MapLibre/MapLibre.h>
//#import "MLNMapView.h"
#include <memory>
#import "GLTFManagerRenderingEnvironmentMetal.hpp"
#import "GLTFManager.hpp"
#import "GLTFMath.hpp"

using namespace maplibre::gltf;

// This is here to hold the metadata about the model if load is called before
// the layer is created
@interface GLTFModelMetadata : NSObject
@property NSString *modelPath;
@property CLLocationCoordinate2D modelCoordinate;
@property double modelRotation;
@property BOOL modelLoaded;
@property float modelScale;
@property float brightness;

@end







@implementation GLTFModelMetadata
-(id)init {
    if (self = [super init]) {
        self.brightness = 1.0;
    }
    return self;
}
@end

@interface MLNGLTFPluginLayer () {
    std::shared_ptr<GLTFManagerRenderingEnvironmentMetal> _metalEnvironment;
    std::shared_ptr<GLTFManager> _manager;

}

@property NSMutableArray *models;
@property BOOL managerCreated;

// Would be nice to change this to a vec3 or something similar at some point
@property BOOL lightSet;
@property float lightX;
@property float lightY;
@property float lightZ;


@end

simd_float4x4 toSimdMatrix4F(const MLNMatrix4 & mlMatrix) {
    simd_float4x4 tempResult;

    /*
    typedef struct MLNMatrix4 {
      double m00, m01, m02, m03;
      double m10, m11, m12, m13;
      double m20, m21, m22, m23;
      double m30, m31, m32, m33;
    } MLNMatrix4;
*/

    tempResult.columns[0][0] = mlMatrix.m00;
    tempResult.columns[0][1] = mlMatrix.m01;
    tempResult.columns[0][2] = mlMatrix.m02;
    tempResult.columns[0][3] = mlMatrix.m03;
    tempResult.columns[1][0] = mlMatrix.m10;
    tempResult.columns[1][1] = mlMatrix.m11;
    tempResult.columns[1][2] = mlMatrix.m12;
    tempResult.columns[1][3] = mlMatrix.m13;
    tempResult.columns[2][0] = mlMatrix.m20;
    tempResult.columns[2][1] = mlMatrix.m21;
    tempResult.columns[2][2] = mlMatrix.m22;
    tempResult.columns[2][3] = mlMatrix.m23;
    tempResult.columns[3][0] = mlMatrix.m30;
    tempResult.columns[3][1] = mlMatrix.m31;
    tempResult.columns[3][2] = mlMatrix.m32;
    tempResult.columns[3][3] = mlMatrix.m33;


    return tempResult;
}



simd_double4x4 toSimdMatrix4D(const MLNMatrix4 & mlMatrix) {
    simd_double4x4 tempResult;

    /*
    typedef struct MLNMatrix4 {
      double m00, m01, m02, m03;
      double m10, m11, m12, m13;
      double m20, m21, m22, m23;
      double m30, m31, m32, m33;
    } MLNMatrix4;
*/

    tempResult.columns[0][0] = mlMatrix.m00;
    tempResult.columns[0][1] = mlMatrix.m01;
    tempResult.columns[0][2] = mlMatrix.m02;
    tempResult.columns[0][3] = mlMatrix.m03;
    tempResult.columns[1][0] = mlMatrix.m10;
    tempResult.columns[1][1] = mlMatrix.m11;
    tempResult.columns[1][2] = mlMatrix.m12;
    tempResult.columns[1][3] = mlMatrix.m13;
    tempResult.columns[2][0] = mlMatrix.m20;
    tempResult.columns[2][1] = mlMatrix.m21;
    tempResult.columns[2][2] = mlMatrix.m22;
    tempResult.columns[2][3] = mlMatrix.m23;
    tempResult.columns[3][0] = mlMatrix.m30;
    tempResult.columns[3][1] = mlMatrix.m31;
    tempResult.columns[3][2] = mlMatrix.m32;
    tempResult.columns[3][3] = mlMatrix.m33;


    return tempResult;
}

@implementation MLNGLTFPluginLayer {
    // The render pipeline state
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLDepthStencilState> _depthStencilStateWithoutStencil;
    MLNPluginLayerDrawingContext _lastMLNContext;
    BOOL _modelPropertyHandled;
    NSString *_modelPath;
}

// This is the layer type in the style that is used
+(MLNPluginLayerCapabilities *)layerCapabilities {

    MLNPluginLayerCapabilities *tempResult = [[MLNPluginLayerCapabilities alloc] init];
    tempResult.layerID = @"hudhud::gltf-model-layer";
    tempResult.tileKind = MLNPluginLayerTileKindNotRequired;
    tempResult.requiresPass3D = YES;

    // Setup the properties
    tempResult.layerProperties = @[
        // TBD
        // The scale property
        [MLNPluginLayerProperty propertyWithName:@"scale"
                                    propertyType:MLNPluginLayerPropertyTypeSingleFloat]

        // TBD
    ];

    return tempResult;

}


-(void)commonInit {
    self.models = [NSMutableArray array];
}

-(id)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (void)didMoveToMapView:(MLNMapView *)mapView {

}

// This sets the relative light position for all the models being rendered
// The light position is in meters from the origin of the model.
-(void)setLightPositionX:(float)x y:(float)y z:(float)z {

    self.lightSet = YES;
    self.lightX = x;
    self.lightY = y;
    self.lightZ = z;

    if (_metalEnvironment != nullptr) {
        _metalEnvironment->_lightDirection = simd_make_float3(_lightX, _lightY, _lightZ);
    }

}


-(void)loadModels {

    // This goes through the model array and loads whatever hasn't been loaded already
    for (GLTFModelMetadata *m in self.models) {
        [self addModel:m];
    }

}

-(void)loadModelFromJSON:(NSString *)modelMetadataFilename {

    NSError *error = nil;
    NSData *dat = [NSData dataWithContentsOfFile:modelMetadataFilename];
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:dat
                                                      options:0
                                                        error:&error];
    NSArray *models = [d objectForKey:@"models"];
    for (NSDictionary *model in models) {

        NSString *modelFilename = [model objectForKey:@"name"];
        double lat = [[model objectForKey:@"lat"] doubleValue];
        double lon = [[model objectForKey:@"lon"] doubleValue];
        double rot = [[model objectForKey:@"rot"] doubleValue];
        double scale = [[model objectForKey:@"scale_factor"] doubleValue];
        double brightnessCoefficient = [[model objectForKey:@"brightness"] doubleValue];
        if (brightnessCoefficient == 0) {
            brightnessCoefficient = 1.0;
        }
        //NSString *bundleFilename = [[NSBundle mainBundle] pathForResource:modelFilename ofType:nil];
        [self loadModel:modelFilename
                    lat:lat
                    lon:lon
            rotationDeg:rot
            scaleFactor:scale
             brightness:brightnessCoefficient];
    }

}


-(void)loadModel:(NSString *)appResourceFilename
             lat:(double)lat
             lon:(double)lon
        rotationDeg:(double)rotationDeg
     scaleFactor:(float)scaleFactor
      brightness:(float)brightness {

    if (brightness == 0) {
        brightness = 1.0;
    }

    GLTFModelMetadata *modelMetadata = [[GLTFModelMetadata alloc] init];
    modelMetadata.modelPath = appResourceFilename;
    modelMetadata.modelCoordinate = CLLocationCoordinate2DMake(lat, lon);
    modelMetadata.modelRotation = -rotationDeg;
    modelMetadata.modelScale = scaleFactor;
    modelMetadata.brightness = brightness;

    [self.models addObject:modelMetadata];

    if (self.managerCreated) {
        [self addModel:modelMetadata];
    }

}



-(void)addModel:(GLTFModelMetadata *)modelMetadata {

    if (modelMetadata.modelLoaded) {
        return;
    }

    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:modelMetadata.modelPath withExtension:nil];

    std::string modelURL = [[fileURL absoluteString] UTF8String];

    std::shared_ptr<GLTFModel> model = std::make_shared<GLTFModel>();
    model->_referenceLat = modelMetadata.modelCoordinate.latitude;
    model->_referenceLon = modelMetadata.modelCoordinate.longitude;
    model->_modelURL = modelURL;
    model->_rotationDeg = modelMetadata.modelRotation;
    model->_brightness = modelMetadata.brightness;
    model->_scaleFactor = modelMetadata.modelScale;
//    model->_scaleFactor = 1.0; // Models are in meters

    _manager->addModel(model);

    modelMetadata.modelLoaded = YES;

}

-(void)onUpdateLayer:(MLNPluginLayerDrawingContext)drawingContext {
    _lastMLNContext = drawingContext;
}


//- (void)drawInMapView:(MLNMapView *)mapView
//          withContext:(MLNStyleLayerDrawingContext)context {
-(void)onRenderLayer:(MLNMapView *)mapView
       renderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder {

    MLNBackendResource* resource = [mapView backendResource];

    bool loadModels = false;

    if (_manager == nullptr) {

        // Setup the metal environment for the model rendering
        _metalEnvironment = std::make_shared<GLTFManagerRenderingEnvironmentMetal>();

        if (self.lightSet) {
            _metalEnvironment->_lightDirection = simd_make_float3(_lightX, _lightY, _lightZ);
        }

        // Create the GLTF Manager
        _manager = std::make_shared<GLTFManager>(RenderingEnvironmentMetal);
        _manager->setRenderingEnvironmentVariables(_metalEnvironment);

        _manager->setProjectionCallback(^Cartesian3D(const Coordinate2D & coordinate){
            Cartesian3D tempResult;

            tempResult._x = 5198170.102753558;
            tempResult._y = 2832006.4886368043;
            tempResult._z = 0;

            tempResult._x = coordinate._lon * DEG_RAD;
            double lat = coordinate._lat * DEG_RAD;
            tempResult._y = log((1.0f+sin(lat))/cos(lat));

            double metersScale = 20037508.34;
            tempResult._x = tempResult._x * metersScale / M_PI;
            tempResult._y = tempResult._y * metersScale / M_PI;
            return tempResult;
        });

        loadModels = true;
    }

    _metalEnvironment->_currentFOVDEG = _lastMLNContext.fieldOfView * RAD_DEG;
    // TODO: Look into if we need this nearclipped matrix
//    _metalEnvironment->_currentProjectionMatrix = toSimdMatrix4D(_lastMLNContext.nearClippedProjMatrix);
    _metalEnvironment->_currentProjectionMatrix = toSimdMatrix4D(_lastMLNContext.projectionMatrix);
    _metalEnvironment->_currentZoomLevel = _lastMLNContext.zoomLevel;
    
    _metalEnvironment->_currentCommandEncoder = renderEncoder;
    _metalEnvironment->_currentCommandBuffer = resource.commandBuffer;
    _metalEnvironment->_metalDevice = resource.mtkView.device;
    _metalEnvironment->_currentDrawable = resource.mtkView.currentDrawable;
    _metalEnvironment->_currentRenderPassDescriptor = resource.mtkView.currentRenderPassDescriptor;
    _metalEnvironment->_depthStencilTexture = resource.mtkView.currentRenderPassDescriptor.depthAttachment.texture;
    _metalEnvironment->_colorTexture = resource.mtkView.currentRenderPassDescriptor.colorAttachments[0].texture;

    if (self.lightSet) {
        _metalEnvironment->_lightDirection = simd_make_float3(_lightX, _lightY, _lightZ);
    }

    // TODO: Remove this..  This is legacy
    _manager->setRenderingEnvironmentVariables(_metalEnvironment);

    if (loadModels) {
        
        if (_modelPropertyHandled) {
            [self loadModelFromJSON:_modelPath];

        }
        
        [self loadModels];
    }

    vector_uint2 _viewportSize;
    _viewportSize.x = resource.mtkView.drawableSize.width;
    _viewportSize.y = resource.mtkView.drawableSize.height;
    _manager->setDrawableSize(_viewportSize.x, _viewportSize.y);

    float timestep = (1 / 60.0f);
    _manager->updateScene(timestep);

    // Render the image
    _manager->render();
}

-(void)onUpdateLayerProperties:(NSDictionary *)layerProperties {
    
    if (!_modelPropertyHandled) {
        NSString *modelFilename = [layerProperties objectForKey:@"model-source-resource"];
        NSString *fullPath = [[NSBundle mainBundle] pathForResource:modelFilename
                                                             ofType:nil];
        _modelPath = fullPath;
        _modelPropertyHandled = true;
    }
    
}

-(void)dealloc {
    NSLog(@"Destroying");
}

- (void)willMoveFromMapView:(MLNMapView *)mapView {
    // Clean up
}

@end
