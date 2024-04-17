//
//  Model.swift
//  Unreality
//
//  Created by Ron Aldrich on 6/17/23.
//

import Foundation
import RealityKit

class UnrealityModel: RealityModel
{
    var meshResources: [MeshResource]
    
    override init()
    {
        meshResources = [MeshResource.generateSphere(radius: 10),
                         MeshResource.generateSphere(radius: 10)]
        
        super.init()
        
        self.makeViewable()
    }

    func makeViewable()
    {
        let viewable = Entity()
        viewable.name = "globe"
        
        var material = SimpleMaterial()
        material.color = .init(tint: .white.withAlphaComponent(1),
                               texture: .init(try! .load(named: "globe")))
        material.metallic = .float(0.1)
        material.roughness = .float(0.5)

        let entity = ModelEntity(mesh: MeshResource.generateSphere(radius: 10),
                                 materials: [material])
        
        entity.name = "sphere"
        
        viewable.addChild(entity)
        
        DispatchQueue.main.async
        {
            self.viewable = viewable
        }
    }
    
}


