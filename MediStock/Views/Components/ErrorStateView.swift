//
//  ErrorStateView.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 14/10/2025.
//

import SwiftUI

struct ErrorStateView: View {
    let errorMessage: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(errorMessage)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: retryAction) {
                Text("Retry")
                    .foregroundStyle(Color.white)
                    .padding(12)
                    .padding(.horizontal)
                    .background(Color.green)
                    .cornerRadius(100)
            }
        }
    }
}
