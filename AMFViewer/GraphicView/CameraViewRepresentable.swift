//
//  CameraViewRepresentable.swift
//  Unreality
//
//  Created by Ron Aldrich on 1/13/24.
//

import SwiftUI
import RealityKit

struct CameraViewRepresentable : NSViewRepresentable
{
    let arView = CameraARView(frame: .init(x: 0, y: 0, width: 1, height: 1))
    
    func makeNSView(context: Context) -> ARView
    {
        let backgroundResource = try! EnvironmentResource.load(named: "Background")
        arView.environment.background = .skybox(backgroundResource)
        
        // arView.debugOptions = .showStatistics
        
        return arView
    }
    
    func updateNSView(_ nsView: ARView, context: Context)
    {
    }
}
