//
//  SIMD+Extensions.swift
//  Unreality
//
//  Created by Ron Aldrich on 1/1/24.
//

import Foundation

import simd

extension SIMD2<Float> {
    public func locationInFrame(origin: SIMD3<Float>, xDelta: SIMD3<Float>, yDelta: SIMD3<Float>) -> SIMD3<Float>
    {
        origin + xDelta * x + yDelta * y
    }
    
    public var length: Float
    {
        return sqrt(x*x + y*y)
    }
    
    public var normalized: SIMD2<Float>
    {
        return self / self.length
    }
    
    public func dot(_ rhs: SIMD2<Float>) -> Float
    {
        return self.x * rhs.x + self.y * rhs.y
    }
}

extension SIMD3<Float> {
    public var length: Float
    {
        return sqrt(x * x + y * y + z * z)
    }
    
    public var normalized: SIMD3<Float>
    {
        return self / self.length
    }
    
    public func dot(_ rhs: SIMD3<Float>) -> Float
    {
        return self.x * rhs.x + self.y * rhs.y + self.z * rhs.z
    }
    
    public func cross(_ rhs: SIMD3<Float>) -> SIMD3<Float>
    {
        return SIMD3<Float>(self.y * rhs.z - self.z * rhs.y,
                            self.z * rhs.x - self.x * rhs.z,
                            self.x * rhs.y - self.y * rhs.x)
    }
    
}
