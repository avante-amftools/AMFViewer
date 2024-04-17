//
//  MetadataDetailView.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 8/10/23.
//

import SwiftUI

struct MetadataDetailView: View {
    let detail : MetadataDetail
    
    var body: some View {
        Text(detail.value)
    }
}
