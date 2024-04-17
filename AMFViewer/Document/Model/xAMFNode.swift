//
//  AMFNode.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/7/23.
//

import Foundation

import RealityKit
import CoreGraphics

class xDetail : Identifiable
{
    let type: String
    var value: String
    
    
    init(type: String, value: String) {
        self.type = type
        self.value = value
    }
    
}

class xAttributeDetail : xDetail
{
    let attributeNode: ModelAttributeWrapper
    
    init(attributeNode: ModelAttributeWrapper) {
        self.attributeNode = attributeNode
        super.init(type: attributeNode.identifier,
                   value: attributeNode.value)
    }
    
    override var value: String
    {
        get {
            return super.value
        }
        
        set {
            super.value = newValue
            attributeNode.value = newValue
        }
    }
    
}

class xMetadataDetail : xDetail
{
    let metadataNode: ModelMetadataWrapper
    
    init(metadataNode: ModelMetadataWrapper) {
        self.metadataNode = metadataNode
        super.init(type: metadataNode.type,
                   value: metadataNode.value)
    }
    
    override var value: String
    {
        get {
            return super.value
        }
        
        set {
            super.value = newValue
            metadataNode.value = newValue
        }
    }
}

class xAMFNode: Identifiable
{
    let elementNode: ModelElementWrapper?
    weak var parent: xAMFNode?
    var children: [xAMFNode]?
    var details: [xDetail] =  []
    var isExpanded: Bool = false

    init()
    {
        self.elementNode = nil
        self.parent = nil
    }
    
    init(elementNode: ModelElementWrapper,
         parent: xAMFNode?)
    {
        self.elementNode = elementNode
        self.parent = parent
        
        // We can't build the mesh resource here, because init will be called
        //  on a background thread, while MeshResource.generate methods must
        //  be called on the main thread.
        
        // This is called on a background thread, but MeshResource.generate methods must
        //  be called on the main thread.
        
        // self.meshResource = MeshResource.generateSphere(radius: 1.0)
        
        if parent != nil
        {
            parent!.addChild(self)
        }
        
        var details: [xDetail] = []
        
        for attributeNode in elementNode.attributeNodes
        {
            let detail = xAttributeDetail(attributeNode: attributeNode)
            details.append(detail)
        }
        
        for metadataNode in elementNode.metadataNodes
        {
            let detail = xMetadataDetail(metadataNode: metadataNode)
            details.append(detail)
        }
        
        self.details = details
        
    }
    
    var name: String {
        if elementNode == nil
        {
            return "[none]"
        }
        
        return elementNode!.identifier
    }

    var description: String
    {
        let localName = NSLocalizedString(name.capitalized, tableName: "OutlineView", comment: "");
        
        let icon = (children == nil ?
                    "📄" : children!.isEmpty ?
                    "📁" : "📂")
        
        return String(format: "%@ %@", icon, localName)
    }
    
    func forEachNodeDo(_ doThis: (xAMFNode) -> Void)
    {
        doThis(self)
        
        if (children != nil)
        {
            for child in children!
            {
                child.forEachNodeDo(doThis)
            }
        }
    }

    private func addChild(_ child: xAMFNode)
    {
        if children == nil
        {
            children = []
        }
        self.children!.append(child)
    }
    
    lazy var sceneVertexCoordinates : UnsafeBufferPointer<simd_float3>? =
    {
        // elementNode's sceneVertexCoordinates is an (auto generated)
        //  UnsafeMutablePointer.  We need it as an UnsafeBufferPointer.

        guard let elementNode = self.elementNode else { return nil }
        
        let sceneVertexCount = elementNode.sceneVertexCount
        guard sceneVertexCount > 0 else { return nil }
        
        guard let sceneVertexCoordinates = elementNode.sceneVertexCoordinates
        else { return nil }
        
        return UnsafeBufferPointer<simd_float3>(start: sceneVertexCoordinates,
                                                count: Int(sceneVertexCount))
    }()
    
    lazy var sceneVertexNormals : UnsafeBufferPointer<simd_float3>? =
    {
        // elementNode's sceneVertexNormals is an (auto generated)
        //  UnsafeMutablePointer.  We need it as an UnsafeBufferPointer.

        guard let elementNode = self.elementNode else { return nil }
        
        let sceneVertexCount = elementNode.sceneVertexCount
        guard sceneVertexCount > 0 else { return nil }
        
        guard let sceneVertexNormals = elementNode.sceneVertexNormals
        else { return nil }
        
        return UnsafeBufferPointer<simd_float3>(start: sceneVertexNormals,
                                                count: Int(sceneVertexCount))
    }()
    
    lazy var sceneVertexColors : UnsafeBufferPointer<simd_packed_char4>? =
    {
        // elementNode's sceneVertexColors is an (auto generated)
        //  UnsafeMutablePointer.  We need it as an UnsafeBufferPointer.

        guard let elementNode = self.elementNode else { return nil }
        
        let sceneVertexCount = elementNode.sceneVertexCount
        guard sceneVertexCount > 0 else { return nil }
        
        guard let sceneVertexColors = elementNode.sceneVertexColors else { return nil }

        return UnsafeBufferPointer<simd_packed_char4>(start: sceneVertexColors,
                                                count: Int(sceneVertexCount))
    }()
    
    lazy var sceneTriangleTriIndices : UnsafeBufferPointer<TriIndex>? =
    {
        // elementNode's sceneTriangleTriIndices is an (auto generated)
        //  UnsafeMutablePointer.  We need it as an UnsafeBufferPointer.
        
        guard let elementNode = self.elementNode else { return nil }
        
        let sceneTriangleCount = elementNode.sceneTriangleCount
        guard sceneTriangleCount > 0 else { return nil }

        guard let sceneTriangleTriIndices = elementNode.sceneTriangleTriIndices else { return nil }
        
        return UnsafeBufferPointer<TriIndex>(start: sceneTriangleTriIndices,
                                           count: Int(sceneTriangleCount))
    }()
    
    @MainActor lazy var meshResource: MeshResource? =
    {
        guard let vertexMap = self.vertexMap
        else { return nil }
        
        return vertexMap.meshResource
    }()
    
    @MainActor lazy var triColorTexture : TextureResource? =
    {
        return self.vertexMap!.triColorTexture
    }()
    
    @MainActor lazy var vertexMap : VertexMap? =
    {
        guard let sceneVertexCoordinates = self.sceneVertexCoordinates
        else { return nil }

        guard let sceneVertexNormals = self.sceneVertexNormals
        else { return nil }

        guard let sceneVertexColors = self.sceneVertexColors
        else { return nil }

        guard let sceneTriangleTriIndices = self.sceneTriangleTriIndices
        else { return nil }

        return VertexMap(sceneVertexCoordinates: sceneVertexCoordinates,
                         sceneVertexNormals: sceneVertexNormals,
                         sceneVertexColors: sceneVertexColors,
                         sceneTriangleTriIndices: sceneTriangleTriIndices)
    }()
}
