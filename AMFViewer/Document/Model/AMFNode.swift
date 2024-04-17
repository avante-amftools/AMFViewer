//
//  AMFNode.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/25/23.
//

import Foundation

import RealityKit
import CoreGraphics



class AMFNode: Identifiable
{
    let id = UUID()
    let elementNode: ModelElementWrapper?
    weak var parent: AMFNode?
    var children: [AMFNode]?
    var details: [Detail] =  []
    var isExpanded: Bool = false
    
    init()
    {
        self.elementNode = nil
        self.parent = nil
    }

    init(elementNode: ModelElementWrapper,
         parent: AMFNode?)
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
        
        var details: [Detail] = []
        
        for detailNode in elementNode.detailNodes
        {            
            if let colorNode = detailNode as? ModelColorWrapper
            {
                let detail = ColorDetail(colorNode: colorNode)
                details.append(detail)
            }
            else if let metadataNode = detailNode as? ModelMetadataWrapper
            {
                let detail = MetadataDetail(metadataNode: metadataNode)
                details.append(detail)
            }
            else if let attributeNode = detailNode as? ModelAttributeWrapper
            {
                let detail = AttributeDetail(attributeNode: attributeNode)
                details.append(detail)
            }
        }
        
        let foo: AnyClass? = object_getClass(self.elementNode)
        let fooName = NSStringFromClass(foo!)
        
        // print("Class = \(fooName)")

        // print(details.debugDescription)
        
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
        let localName = NSLocalizedString(name,
                                          tableName: "OutlineView",
                                          comment: "")
        
        let icon = (children == nil ?
                    "📄" : children!.isEmpty ?
                    "📁" : "📂")
        
        return String(format: "%@ %@", icon, localName.capitalized)
    }
    
    func forEachNodeDo(_ doThis: (AMFNode) -> Void)
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
    
    private func addChild(_ child: AMFNode)
    {
        if children == nil
        {
            children = []
        }
        self.children!.append(child)
    }
        
    
    @MainActor lazy var sceneMesh: MeshResource? =
    {
        guard let renderer = self.renderer
        else { return nil }
        
        return renderer.meshResource
    }()
    
    @MainActor lazy var sceneTexture: TextureResource? =
    {
        guard let renderer = self.renderer
        else { return nil }
        
        return renderer.textureResource
    }()
    
    lazy var renderer: RealityKitRenderer? =
    {
        guard let modelVertexData = self.modelVertexData
        else { return nil }
        
        guard let modelTriangleData = self.modelTriangleData
        else { return nil }
        
        return RealityKitRenderer(modelColor: self.modelColor,
                                  modelVertexData: modelVertexData,
                                  modelTriangleData: modelTriangleData)
    }()
    
    private lazy var modelColor: simd_packed_uchar4 =
    {
        return simd_packed_uchar4(x: 255, y: 255, z: 255, w: 255)
    }()
    
    private lazy var modelVertexData: UnsafeBufferPointer<VertexData>? =
    {
        guard let vertexData = self.elementNode?.vertexData
        else { return nil }
        
        guard let vertexCount = self.elementNode?.vertexCount
        else { return nil }
        
        
        return UnsafeBufferPointer<VertexData>(start: vertexData,
                                               count: Int(vertexCount))
    }()
    
    private lazy var modelTriangleData : UnsafeBufferPointer<TriangleData>? =
    {
        guard let triangleData = self.elementNode?.triangleData
        else { return nil }
        
        guard let triangleCount = self.elementNode?.triangleCount
        else { return nil }
        
        return UnsafeBufferPointer<TriangleData>(start: triangleData,
                                                 count: Int(triangleCount))
    }()
}

