//
//  VertexMap.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/12/23.
//

import Foundation

import RealityKit
import CoreGraphics

struct MixedVertex : Comparable, Hashable
{
    let coordinate: simd_float3
    let normal : simd_float3
    let textureCoordinate: simd_float2
    let triColor : TriColor
    
    init(coordinate: simd_float3,
         normal: simd_float3,
         textureCoordinate: simd_float2,
         triColor: TriColor)
    {
        self.coordinate = coordinate
        self.normal = normal
        self.textureCoordinate = textureCoordinate
        self.triColor = triColor
    }
    
    static func < (lhs: MixedVertex,
                   rhs: MixedVertex) -> Bool
    {
        return (lhs.coordinate < rhs.coordinate ? true :
                    lhs.normal < rhs.normal ? true :
                    lhs.textureCoordinate < rhs.textureCoordinate ? true :
                    lhs.triColor < rhs.triColor)
    }
    
    static func == (lhs: MixedVertex,
                    rhs: MixedVertex) -> Bool
    {
        var result: Bool = (lhs.coordinate == rhs.coordinate &&
                            lhs.normal == rhs.normal &&
                            lhs.textureCoordinate == rhs.textureCoordinate &&
                            lhs.triColor == rhs.triColor)
        
        return result
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.coordinate)
        hasher.combine(self.normal)
        hasher.combine(self.textureCoordinate)
        hasher.combine(self.triColor)
    }
}

class VertexMap
{
    // Because RealityKit does not support per-vertex color,
    //  we have to use a texture map to support that feature
    //  of AMF files.
    //
    // In order to do this, we have to generate a texture map
    //  that provides color data on a per-triangle basis.
    //  This increases the number of vertices needed to render
    //  the mesh, because vertexes are now indirectly associated
    //  to the TriColor that is used by its triangle.
    //
    // For meshes that do not provide vertex normals, we always generate
    //  them, because RealityKit does not do a good job of generating
    //  vertex normals for certain (small? pointy?) triangles.  As a
    //  result, we don't get much reuse of vertices.
    //
    // There is some optimization in meshes that do not use per-vertex
    //  color because only a single TriColor will be generated, with all
    //  of its pixels containing the same color, thus all vertex texture
    //  coordinates will be equal.
    //
    // So, given:
    //      Vertex coordinates,
    //      Vertex normals,
    //      Vertex colors,
    //      Triangle vertex indices and
    //      Triangle colors
    //
    //  Create arrays for:
    //      Vertex Coordinates,
    //      Vertex Normals, and
    //      Vertex Texture coordinates
    //  which are expanded as needed to accomodate the new arrangement.
    
    var sceneVertexCoordinates: UnsafeBufferPointer<simd_float3>
    var sceneVertexNormals: UnsafeBufferPointer<simd_float3>
    var sceneVertexColors: UnsafeBufferPointer<simd_packed_char4>
    var sceneTriangleTriIndices : UnsafeBufferPointer<TriIndex>
    // var sceneTriangleColors : UnsafeBufferPointer<simd_packed_char4>
    
    init(sceneVertexCoordinates: UnsafeBufferPointer<simd_float3>,
         sceneVertexNormals: UnsafeBufferPointer<simd_float3>,
         sceneVertexColors: UnsafeBufferPointer<simd_packed_char4>,
         sceneTriangleTriIndices: UnsafeBufferPointer<TriIndex>)
    {
        self.sceneVertexCoordinates = sceneVertexCoordinates
        self.sceneVertexNormals = sceneVertexNormals
        self.sceneVertexColors = sceneVertexColors
        self.sceneTriangleTriIndices = sceneTriangleTriIndices
        
        print("sceneVertexCoordinates.count: ", sceneVertexCoordinates.count)
        print("sceneVertexNormals.count: ", sceneVertexNormals.count)
        print("sceneTriangleTriIndices.count: ", sceneTriangleTriIndices.count)
    }
    
    // The use of lazy variables here results in a fair amount of repeated code.
    //  This should be reconsidered.  Perhaps all of these arrays
    //  should be generated at initialization, and the entire structure
    //  should be created lazily.
    
    lazy var rkVertexCoordinates: [simd_float3] =
    {
        var result: [simd_float3] = []
        
        for triIndex in sceneTriangleTriIndices
        {
            for vertexIndex in 0...2
            {
                let mixedVertex = mixedVertex(triIndex,
                                              vertexIndex)
                result.append(mixedVertex.coordinate)
            }
        }
        
        print("rkVertexCoordinates.count: ", result.count)
        
        for coordinate in result
        {
            print("    ", coordinate)
        }
        
        return result
    }()
    
    lazy var rkVertexNormals: [simd_float3] =
    {
        var result: [simd_float3] = []
        
        for triIndex in sceneTriangleTriIndices
        {
            for vertexIndex in 0...2
            {
                let mixedVertex = mixedVertex(triIndex,
                                              vertexIndex)
                result.append(mixedVertex.normal)
            }
        }
        
        print("rkVertexNormals.count: ", result.count)
        
        for normal in result
        {
            print("    ", normal)
        }

        return result
    }()
        
    lazy var rkVertexTextureCoordinates: [simd_float2] =
    {
        var result: [simd_float2] = []
        
        for triIndex in sceneTriangleTriIndices
        {
            for vertexIndex in 0...2
            {
                let mixedVertex = mixedVertex(triIndex,
                                              vertexIndex)
                result.append(mixedVertex.textureCoordinate)
            }
        }
        
        print("rkVertexTextureCoordinates.count: ", result.count)
        
        for coordinate in result
        {
            print("    ", coordinate)
        }

        return result
    }()
    
    lazy var rkTriangleVertexIndices: [UInt32] =
    {
        var result: [UInt32] = []
        
        for triIndex in sceneTriangleTriIndices
        {
            for vertexIndex in 0...2
            {
                let key = mixedVertex(triIndex,
                                      vertexIndex)
                result.append(mixedVertexMap[key]!)
            }
        }
                
        print("rkTriangleVertexIndices.count: ", result.count)
        
        return result
    }()
    
    private func mixedVertex(_ triIndex: TriIndex,
                             _ vertexIndex: Int) -> MixedVertex
    {
        let i0 = Int(triIndex.indices.0)
        let i1 = Int(triIndex.indices.1)
        let i2 = Int(triIndex.indices.2)
        
        let coordinates = [sceneVertexCoordinates[i0],
                           sceneVertexCoordinates[i1],
                           sceneVertexCoordinates[i2]]
        
        let normals = [sceneVertexNormals[i0],
                       sceneVertexNormals[i1],
                       sceneVertexNormals[i2]]
        
        #if false
        let colors = [sceneVertexColors[i0],
                      sceneVertexColors[i1],
                      sceneVertexColors[i2]]
        #else
        let colors = [simd_packed_char4(x: -1, y: -1, z: -1, w: -1),
                      simd_packed_char4(x: -1, y: -1, z: -1, w: -1),
                      simd_packed_char4(x: -1, y: -1, z: -1, w: -1)]
        #endif
        
        let triColor = TriColor(colors: colors)
        
        let textureCoordinates = [triColorMap.coordinateOf(triColor: triColor,
                                                           vertexColor: colors[0]),
                                  triColorMap.coordinateOf(triColor: triColor,
                                                           vertexColor: colors[1]),
                                  triColorMap.coordinateOf(triColor: triColor,
                                                           vertexColor: colors[2])]
        
        return MixedVertex(coordinate: coordinates[vertexIndex],
                           normal: normals[vertexIndex],
                           textureCoordinate: textureCoordinates[vertexIndex],
                           triColor: triColor)
    }
        
    
    private lazy var mixedVertexMap: [MixedVertex : UInt32] =
    {
        // Generates a map (dictionary) of MixedVertex structures
        //  for the mesh.  Each structure in the mesh will be only
        //  as unique as required (it's unlikely that one would be
        //  reused, but possible).
        
        var result: [MixedVertex : UInt32] = [:]
                
        let triColorMap = self.triColorMap

        for triIndex in sceneTriangleTriIndices
        {
            for vertexIndex in 0...2
            {
                let mixedVertex = self.mixedVertex(triIndex,
                                                   vertexIndex)
                
                if result.index(forKey: mixedVertex) == nil
                {
                    result[mixedVertex] = UInt32(result.count)
                }
            }
        }
        
        print("mixedVertexMap.count: ", result.count)
        
        return result
    }()
    
    private lazy var triColorMap: TriColorMap =
    {
        return TriColorMap(self.sceneVertexColors,
                           self.sceneTriangleTriIndices)
    }()
    
    @MainActor lazy var meshResource: MeshResource? =
    {
        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffers.Positions(self.rkVertexCoordinates)
        descriptor.normals = MeshBuffers.Normals(self.rkVertexNormals)
        descriptor.primitives = .triangles(Array(self.rkTriangleVertexIndices))

        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(self.rkVertexTextureCoordinates)
        
        return try! MeshResource.generate(from: [descriptor])
    }()
    
    @MainActor lazy var triColorTexture: TextureResource? =
    {
        return self.triColorMap.triColorTexture
    }()
    
}
