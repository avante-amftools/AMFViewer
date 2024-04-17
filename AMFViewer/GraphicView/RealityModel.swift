//
//  RealityModel.swift
//  Arcball
//
//  Created by Ron Aldrich on 1/13/24.
//

import SwiftUI
import RealityKit

class RealityModel: ObservableObject
{
    @MainActor @Published var viewable: Entity?
    //  viewable is marked as @MainActor so that changes to the
    //  scene graph will be processed on the main thread.
}
