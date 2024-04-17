//
//  PreferencesView.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 10/25/23.
//

import SwiftUI

#if false

// We currently don't have a preferences view.
//  I left this here in case it's needed in the future.

struct PreferencesView: View {
    var body: some View {
        TabView {
            OtherPreferencesView()
                .tabItem {
                    Label("Other", systemImage: "questionmark")
                }
        }
        .frame(width: 450, height: 250)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}

#endif
