//
//  SIMD+Extensions.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/17/23.
//

import Foundation

import CoreGraphics

/*
extension SIMD2 where Scalar : Comparable
{
    public static func < (lhs: SIMD2<Scalar>, rhs: SIMD2<Scalar>) -> Bool
    {
        return (lhs.x < rhs.x ? true :
                    lhs.y < rhs.y)
    }
}

extension SIMD3 where Scalar : Comparable
{
    public static func < (lhs: SIMD3<Scalar>, rhs: SIMD3<Scalar>) -> Bool
    {
        return (lhs.x < rhs.x ? true :
                    lhs.y < rhs.y ? true :
                    lhs.z < rhs.z)
    }
}

extension SIMD4 where Scalar : Comparable
{
    public static func < (lhs: SIMD4<Scalar>, rhs: SIMD4<Scalar>) -> Bool
    {
        return (lhs.x < rhs.x ? true :
                    lhs.y < rhs.y ? true :
                    lhs.z < rhs.z ? true :
                    lhs.w < rhs.w)
    }
}
 */


extension simd_float2 : Comparable
{
    public static func < (lhs: SIMD2<Scalar>, rhs: SIMD2<Scalar>) -> Bool
    {
        return (lhs.x < rhs.x ? true :
                    lhs.y < rhs.y)
    }
    
}

extension simd_float3 : Comparable
{
    public static func < (lhs: SIMD3<Scalar>, rhs: SIMD3<Scalar>) -> Bool
    {
        return (lhs.x < rhs.x ? true :
                    lhs.y < rhs.y ? true :
                    lhs.z < rhs.z)

    }
}

extension simd_packed_uchar4 : Comparable
{
    public static func < (lhs: SIMD4<Scalar>, rhs: SIMD4<Scalar>) -> Bool
    {
        return (lhs.x < rhs.x ? true :
                    lhs.y < rhs.y ? true :
                    lhs.z < rhs.z ? true :
                    lhs.w < rhs.w)
    }
    
}
