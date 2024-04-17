//
//  MixedVertexMap.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/27/23.
//
//  Because RealityKit doesn't support per-triangle or per-vertex colors, we
//  have to use a texture map to emulate those concepts.
//

import Foundation

import RealityKit
import CoreGraphics

struct MixedVertex : Comparable, Hashable
{
    let coordinate: simd_float3
    let normal : simd_float3
    let textureCoordinate: simd_float2
    
    init(coordinate: simd_float3,
         normal: simd_float3,
         textureCoordinate: simd_float2)
    {
        self.coordinate = coordinate
        self.normal = normal
        self.textureCoordinate = textureCoordinate
    }
    
    static func < (lhs: MixedVertex,
                   rhs: MixedVertex) -> Bool
    {
        return (lhs.coordinate < rhs.coordinate ? true :
                    lhs.normal < rhs.normal ? true :
                    lhs.textureCoordinate < rhs.textureCoordinate)
    }
    
    static func == (lhs: MixedVertex,
                    rhs: MixedVertex) -> Bool
    {
        let result = (lhs.coordinate == rhs.coordinate &&
                      lhs.normal == rhs.normal &&
                      lhs.textureCoordinate == rhs.textureCoordinate)
        
        return result
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.coordinate)
        hasher.combine(self.normal)
        hasher.combine(self.textureCoordinate)
    }
    
    func debugPrint(index: Int)
    {
        print("[", index, "] coordinate: ", coordinate);
        print("      normal: ", normal);
        print("      textureCoordinate: ", textureCoordinate);
    }
    
    func debugPrint()
    {
        print("coordinate: ", coordinate);
        print("normal: ", normal);
        print("textureCoordinate: ", textureCoordinate);
    }

}

class MixedVertexMap
{
    var vertexMap : [MixedVertex : UInt32] = [:]
    
    func addMixedVertex(mixedVertex: MixedVertex)
    {
        if let index = vertexMap.index(forKey: mixedVertex)
        {
            /*
            print("duplicate mixed vertex")
            print(" mixedVertex: ", mixedVertex)
            let found = vertexMap[index].key
            print(" found: ", found)
             */
        }
        else
        {
            vertexMap[mixedVertex] = UInt32(vertexMap.count)
        }
    }
    
    func indexOf(mixedVertex: MixedVertex) -> UInt32
    {
        if vertexMap.index(forKey: mixedVertex) == nil
        {
            print("missing mixed vertex")
            mixedVertex.debugPrint()
            
            for rhs in vertexMap
            {
                if mixedVertex.coordinate == rhs.key.coordinate &&
                    mixedVertex.normal == rhs.key.normal
                {
                    rhs.key.debugPrint(index: Int(rhs.value))
                }
            }
        }

        return vertexMap[mixedVertex]!
    }
}

