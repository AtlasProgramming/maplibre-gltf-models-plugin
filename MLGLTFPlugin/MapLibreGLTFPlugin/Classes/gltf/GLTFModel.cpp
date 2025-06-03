//
//  GLTFModel.cpp
//  GLTFTestRendering
//
//  Created by Malcolm Toon on 11/25/24.
//

#include "GLTFModel.hpp"

using namespace maplibre::gltf;

void GLTFModel::animateToLocation(double toLatitude,
                             double toLongitude,
                             double durationSeconds) {
    
    _animatingLocation = true;
    _locationAnimationDuration = durationSeconds;
    _locationAnimationRemaining = durationSeconds;
    _locationAnimationStartLatitude = _referenceLat;
    _locationAnimationStartLongitude = _referenceLon;
    _locationAnimationToLatitude = toLatitude;
    _locationAnimationToLongitude = toLongitude;
    
}

void GLTFModel::updateAnimations(double secondsSinceLastRender) {
    
    // Check to see what animations we need to process
    if (_animatingLocation) {
        
        double newAnimationRemaining = _locationAnimationRemaining - secondsSinceLastRender;
        
        // If we're beyond the animation, then clip the remaining and set animation to false
        if (newAnimationRemaining < 0) {
            newAnimationRemaining = 0;
            _animatingLocation = false;
        }
        _locationAnimationRemaining = newAnimationRemaining;
        
        // Calc new location
        double deltaLat = _locationAnimationToLatitude - _locationAnimationStartLatitude;
        double deltaLon = _locationAnimationToLongitude - _locationAnimationStartLongitude;
        
        double animationPctComplete = (_locationAnimationDuration - _locationAnimationRemaining) / _locationAnimationDuration;
        double newLat = _locationAnimationStartLatitude + (deltaLat * animationPctComplete);
        double newLon = _locationAnimationStartLongitude + (deltaLon * animationPctComplete);
        
        _referenceLat = newLat;
        _referenceLon = newLon;
        
    }
    
}

