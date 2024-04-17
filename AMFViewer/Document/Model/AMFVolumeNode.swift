//
//  AMFVolumeNode.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/18/23.
//

import Foundation

import RealityKit
import CoreGraphics

struct SceneVertex : Hashable
{
    var coordinate: simd_float3
    var normal: simd_float3
    var textureCoordinate: simd_float2
    var triColor: TriColor
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.coordinate)
        hasher.combine(self.normal)
        hasher.combine(self.textureCoordinate)
        hasher.combine(self.triColor)
    }
}

class AMFVolumeNode : AMFNode
{
    
    init(volumeNode: ModelVolumeWrapper,
         parent: AMFNode?)
    {
        super.init(elementNode: volumeNode,
                   parent: parent)
    }
    
    var volumeNode: ModelVolumeWrapper
    {
        return self.elementNode as! ModelVolumeWrapper
    }
    
    var parentMeshNode: ModelMeshWrapper
    {
        return self.volumeNode.parentMeshNode
    }

    @MainActor lazy var meshResource2: MeshResource? =
    {
        return nil
    }()
    
    @MainActor lazy var meshTexture: TextureResource? =
    {
        return nil
    }()
    
    lazy var sceneVertices: [SceneVertex : Int] =
    {
        // SceneVertex to Vertex Index map.
        
        // For each unique triangle in the mesh, generate a SceneVertex entry in the map.
        
        var result : [SceneVertex : Int] = [:]
        
        return result
    }()
    
    lazy var modelVertices : UnsafeBufferPointer<VertexData> =
    {
        let meshNode = self.parentMeshNode
        
        let vertexCount = meshNode.vertexCount
        assert(vertexCount > 0)
        
        let vertexData = meshNode.vertexData
        
        return UnsafeBufferPointer<VertexData>(start: vertexData,
                                                 count: Int(vertexCount))
    }()
    
    lazy var modelTriIndices : UnsafeBufferPointer<TriIndex> =
    {
        let volumeNode = self.volumeNode
        
        let vertexTriIndexCount = volumeNode.vertexTriIndexCount
        assert (vertexTriIndexCount > 0)
        
        let vertexTriIndexData = volumeNode.vertexTriIndexData
        
        return UnsafeBufferPointer<TriIndex>(start: vertexTriIndexData,
                                             count: Int(vertexTriIndexCount))
    }()
    
    lazy var modelTriangleColors : UnsafeBufferPointer<simd_double4> =
    {
        let volumeNode = self.volumeNode
        
        let triangleColorCount = volumeNode.triangleColorCount
        assert (triangleColorCount > 0)
        
        let triangleColorData = volumeNode.triangleColorData
        
        return UnsafeBufferPointer<simd_double4>(start: triangleColorData,
                                                 count: Int(triangleColorCount))
    }()
        
}

