//
//  DeletingOverlay.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 14/10/2025.
//

import SwiftUI

struct DeletingOverlay: View {
    let isDeleting: Bool
    
    var body: some View {
        if isDeleting {
            HStack {
                Spacer()
                ProgressView("Deleting...")
                Spacer()
            }
        }
    }
}
