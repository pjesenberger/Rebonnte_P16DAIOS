//
//  SymbolButton.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 05/10/2025.
//

import SwiftUI

struct SymbolButton: View {
    let systemName: String
    let color: Color
    let font: Font
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(font)
                .foregroundColor(color)
        }
    }
}

#Preview {
    SymbolButton(systemName: "plus.square", color: Color.red, font: Font.body, action: { print("button pressed") })
}
