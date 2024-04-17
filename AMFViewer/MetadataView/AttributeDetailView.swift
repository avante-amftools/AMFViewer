//
//  AttributeDetailView.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 8/10/23.
//

import SwiftUI

struct AttributeDetailView: View {
    let detail : AttributeDetail
    
    var body: some View {
        Text(detail.value)
    }
}
