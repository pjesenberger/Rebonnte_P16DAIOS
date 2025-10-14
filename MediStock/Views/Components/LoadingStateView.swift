//
//  LoadingStateView.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 14/10/2025.
//

import SwiftUI

struct LoadingStateView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        ProgressView(message)
    }
}
