//
//  Arcball.swift
//  Arcball
//
//  Created by Ron Aldrich on 1/19/24.
//

import Foundation

import RealityKit

class Arcball
{
    static func rotation(fromNDC: SIMD2<Float>,
                         toNDC: SIMD2<Float>) -> simd_quatf
    {
        let fromArcball = ndcToArcball(fromNDC)
        let toArcball = ndcToArcball(toNDC)
        
        let axis = fromArcball.cross(toArcball).normalized
        // let axis = toArcball.cross(fromArcball).normalized
        
        let angle = acos(max(min(1, fromArcball.dot(toArcball)), -1))
        //let angle = acos(max(min(1, toArcball.dot(fromArcball)), -1))
        
        let rotation = simd_quatf(angle: -angle,
                                  axis: axis)
        
        return rotation
    }
    
    // Return the coordinates on the arcball for a pair
    //  of normalized coordinates on the view.
    
    static func ndcToArcball(_ ndc: SIMD2<Float>) -> SIMD3<Float>
    {
        let length2 = ndc.x * ndc.x + ndc.y * ndc.y
        
        return (length2 <= 1 ?
                SIMD3<Float>(ndc, sqrt(1-length2)) :
                    SIMD3<Float>(ndc.normalized, 0))
    }
    
}
