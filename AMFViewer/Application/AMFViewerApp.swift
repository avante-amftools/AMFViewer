//
//  AMFViewerApp.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 6/21/23.
//

import SwiftUI

@main
struct AMFViewerApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: AMFViewerDocument()) { file in
            AMFDocumentView(document: file.$document)
        }
        
        /*  Settings view goes here.
        Settings {
            PreferencesView()
        }
         */
    }
    
    init()
    {
        AMFWrapped.initialize()
        AMFWrapped.initializeSTL();
    }
}
