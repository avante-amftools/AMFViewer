//
//  AMFModel.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 6/21/23.
//

import Foundation
import RealityKit


class AMFModel : RealityModel
{
    @Published var rootNode = AMFNode()
    
    @Published var selection = Set<AMFNode.ID>()
    {
        didSet
        {
            self.makeSelectedNodes()
            
            // self.updateViewable()
        }
    }

    @Published var selectedNodes: [AMFNode] = []

    private var nodesByID: [AMFNode.ID : AMFNode] = [:]
    
    override init()
    {
        super.init()
        
        DispatchQueue.main.async {
            self.updateViewable()
        }
    }
    
    @MainActor init(rootElement: ModelRootWrapper)
    {
        super.init()
        
        let rootNode = AMFNode(outline: self,
                                elementNode: rootElement,
                                parent: nil)
        
        for object in rootElement.objectNodes
        {
            // Object nodes
            
            let objectNode = AMFNode(outline: self,
                                     elementNode: object,
                                     parent: rootNode)
            
            // Object's mesh node (Always 1 per object)
            
            let amfMesh = object.meshNode
            let meshNode = AMFNode(outline: self,
                                   elementNode: amfMesh,
                                   parent: objectNode)
            
            // Mesh's volume nodes.
            
            for volume in amfMesh.volumeNodes
            {
                _ = AMFNode(outline: self,
                                         elementNode: volume,
                                         parent: meshNode)
            }
        }
        
        // Material nodes
        
        for material in rootElement.materialNodes
        {
            _ = AMFNode(outline: self,
                            elementNode: material,
                            parent: rootNode)
        }
        
        for constellation in rootElement.constellationNodes
        {
            _ = AMFNode(outline: self,
                            elementNode: constellation,
                            parent: rootNode)
        }
        
        DispatchQueue.main.async {
            self.rootNode = rootNode;
            self._updateViewable()
        }
    }
    
    func makeSelectedNodes()
    {
        self.makeNodesByID()
        
        if selection.isEmpty
        {
            self.selectedNodes = [rootNode]
        }
        else
        {
            var selectedNodes: [AMFNode] = []
            for id in selection
            {
                selectedNodes.append(self.nodesByID[id]!)
            }
            
            self.selectedNodes = selectedNodes
        }
    }
    
    func makeNodesByID()
    {
        if self.nodesByID.isEmpty
        {
            var nodesByID: [AMFNode.ID : AMFNode] = [:]
            rootNode.forEachNodeDo({ node in
                nodesByID[node.id] = node
            })
            self.nodesByID = nodesByID
        }
    }
          
    func updateViewable()
    {
        DispatchQueue.main.async
        {
            self._updateViewable()
        }
    }
    
    @MainActor private func _updateViewable()
    {
        if self.rootNode.children != nil
        {
            let viewable = Entity()
            
            self.rootNode.forEachNodeDo
            {
                node in
                if let meshResource = node.meshResource
                {
                    let material = SimpleMaterial(color: .white,
                                                  roughness: 1,
                                                  isMetallic: false)
                    let entity = ModelEntity(mesh: meshResource,
                                             materials: [material])
                    
                    viewable.addChild(entity)
                }
            }
            
            self.viewable = viewable
        }
    }
}
