//
//  RealityKitRenderer.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/27/23.
//
//      Render an AMF volume as RealityKit resources.

import Foundation

import RealityKit
import CoreGraphics

class RealityKitRenderer
{
    // Base color of the model.
    let modelColor: simd_packed_uchar4
    
    // Vertex data.
    
    let modelVertexData: UnsafeBufferPointer<VertexData>
    
    // Triangle data.
    
    let modelTriangleData: UnsafeBufferPointer<TriangleData>
    
    private var triColorMap = TriColorMap()
    private var mixedVertexMap = MixedVertexMap()
    
    init(modelColor: simd_packed_uchar4,
         modelVertexData: UnsafeBufferPointer<VertexData>,
         modelTriangleData: UnsafeBufferPointer<TriangleData>)
    {
        self.modelColor = modelColor
        self.modelVertexData = modelVertexData
        self.modelTriangleData = modelTriangleData
        
        var index = 0
        
        #if true
        for vertexData in modelVertexData
        {
            print("[", index, "] coordinates: ", vertexData.coordinates)
            index += 1
        }
        
        index = 0
        
        for triangleData in modelTriangleData
        {
            print("[", index,
                  "] indices: [", triangleData.indices.0,
                  " ", triangleData.indices.1,
                  " ", triangleData.indices.2, "]")
        }
        
        #endif
        
        // Build the maps.
        
        for triangleData in modelTriangleData
        {
            let triColor = triColorWith(triangleData: triangleData)
            
            triColorMap.addTriColor(triColor: triColor)
        }
        
        for triangleData in modelTriangleData
        {
            for cornerIndex in 0...2
            {
                mixedVertexMap.addMixedVertex(mixedVertex: mixedVertexWith(triangleData: triangleData,
                                                                           cornerIndex: cornerIndex))
            }
        }
        
        #if true
        print("modelTriangleData count: ", modelTriangleData.count)
        print("triColorMap count: ", triColorMap.colorMap.count)
        print("mixedVertexMap count: ", mixedVertexMap.vertexMap.count)
        #endif
    }
    
    @MainActor lazy var textureResource: TextureResource =
    {
        return triColorMap.textureResource
    }()
    
    @MainActor lazy var meshResource: MeshResource =
    {
        var sceneVertexCoordinates : [simd_float3] = Array(repeating: simd_float3(),
                                                           count: mixedVertexMap.vertexMap.count)
        var sceneVertexNormals: [simd_float3] = Array(repeating: simd_float3(),
                                                      count: mixedVertexMap.vertexMap.count)
        var sceneVertexTextureCoordinates: [simd_float2] = Array(repeating: simd_float2(),
                                                                 count: mixedVertexMap.vertexMap.count)
        var sceneTriangleVertexIndices: [UInt32] = []
        sceneTriangleVertexIndices.reserveCapacity(modelTriangleData.count * 3)
        
        for mixedVertex in mixedVertexMap.vertexMap
        {
            sceneVertexCoordinates[Int(mixedVertex.value)] = mixedVertex.key.coordinate
            sceneVertexNormals[Int(mixedVertex.value)] = mixedVertex.key.normal
            sceneVertexTextureCoordinates[Int(mixedVertex.value)] = mixedVertex.key.textureCoordinate
        }
        
        for triangleData in modelTriangleData
        {
            for cornerIndex in 0...2
            {
                let mixedVertex = mixedVertexWith(triangleData: triangleData,
                                                  cornerIndex: cornerIndex)
                let index = mixedVertexMap.indexOf(mixedVertex: mixedVertex)
                
                sceneTriangleVertexIndices.append(index)
            }
        }
        
        // sceneTriangleVertexIndices.remove(atOffsets: [0, 1, 2, 3, 4, 5])
        
        var descriptor = MeshDescriptor()
        
        descriptor.positions = MeshBuffers.Positions(sceneVertexCoordinates)
        descriptor.normals = MeshBuffers.Normals(sceneVertexNormals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(sceneVertexTextureCoordinates)
        descriptor.primitives = .triangles(sceneTriangleVertexIndices)
        
        return try! MeshResource.generate(from: [descriptor])
    }()
            
    private func triColorWith(triangleData: TriangleData) -> TriColor
    {
        let colors = [vertexColorWith(triangleData: triangleData,
                                      cornerIndex: 0),
                      vertexColorWith(triangleData: triangleData,
                                      cornerIndex: 1),
                      vertexColorWith(triangleData: triangleData,
                                      cornerIndex: 2)]
        
        return TriColor(colors: colors)
    }
    
    private func vertexColorWith(triangleData: TriangleData,
                                 cornerIndex: Int) -> simd_packed_uchar4
    {
        if !triangleData.color.w.isNaN
        {
            return eightBitColor(triangleData.color)
        }
                
        let vertexColor = vertexDataFor(triangleData: triangleData,
                                        cornerIndex: cornerIndex).color
        
        if !vertexColor.w.isNaN
        {
            return eightBitColor(vertexColor)
        }
        
        return modelColor
    }
    
    private func eightBitColor(_ value: simd_double4) -> simd_packed_uchar4
    {
        return simd_packed_uchar4(x: UInt8(value.x * 255.0),
                                  y: UInt8(value.y * 255.0),
                                  z: UInt8(value.z * 255.0),
                                  w: UInt8(value.w * 255.0))
    }
    
    private func vertexDataFor(triangleData: TriangleData,
                               cornerIndex: Int) -> VertexData
    {
        let vertexIndex = Int(cornerIndex == 0 ? triangleData.indices.0 :
                                cornerIndex == 1 ? triangleData.indices.1 :
                                triangleData.indices.2)
        
        // If the vertex does not have a normal, use the triangle's face normal instead.
        
        let vertexData = modelVertexData[vertexIndex]
        let vertexNormal = vertexData.normal.x.isNaN ? triangleData.normal : vertexData.normal
        
        let result = VertexData(coordinates: vertexData.coordinates,
                                normal: vertexNormal,
                                color: vertexData.color)
        
        /*
        print("vertexIndex: ", vertexIndex)
        print("coordinate: ", result.coordinates)
        print("normal: ", result.normal)
        print("color: ", result.color)
         */
        
        return result
    }
    
    private func mixedVertexWith(triangleData: TriangleData,
                                 cornerIndex: Int,
                                 triColor: TriColor) -> MixedVertex
    {
        let vertexData = vertexDataFor(triangleData: triangleData,
                                       cornerIndex: cornerIndex)
        
        let textureCoordinate = triColorMap.coordinateOf(triColor: triColor,
                                                         cornerIndex: cornerIndex)
        
        return MixedVertex(coordinate: simd_float3(vertexData.coordinates),
                           normal: simd_float3(vertexData.normal),
                           textureCoordinate: textureCoordinate)
    }
    
    private func mixedVertexWith(triangleData: TriangleData,
                                 cornerIndex: Int) -> MixedVertex
    {
        return mixedVertexWith(triangleData: triangleData,
                               cornerIndex: cornerIndex,
                               triColor: triColorWith(triangleData: triangleData))
    }
}
