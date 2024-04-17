//
//  RealityView.swift
//  Arcball2
//
//  Created by Ron Aldrich on 1/19/24.
//

import SwiftUI

struct RealityView: View {
    @ObservedObject var model: RealityModel
    
    let cameraViewRepresentable = CameraViewRepresentable()
    
    init(model: RealityModel) {
        self.model = model
    }
    
    var body: some View {
        // RealityView is using @ObservedObject to track changes to the RealityModel.
        //  When model is changed, this method is called, and notifies the ARView
        //  of the change.
        
        // This has to be done this way because NSViewRepresentable deletes the body
        //  accessor, and doesn't appear to replace its functionality.
        
        // We bypass CameraViewRepresentable, and notify the ARView directly,
        //  because CameraViewRepresentable is a struct (and therefore non-mutable).
        
        // let _ = print("RealityView.body called");
        
        let _ = cameraViewRepresentable.arView.viewable = model.viewable
        
        cameraViewRepresentable
            .padding()
    }
}
