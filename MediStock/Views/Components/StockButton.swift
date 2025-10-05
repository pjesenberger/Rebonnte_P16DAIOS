//
//  StockButton.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 05/10/2025.
//

import SwiftUI

struct StockButton: View {
    let systemName: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(color)
        }
    }
}

#Preview {
    StockButton(systemName: "plus.square", color: Color.red, action: { print("button pressed") })
}
