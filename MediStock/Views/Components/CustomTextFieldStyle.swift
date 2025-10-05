//
//  CustomTextFieldStyle.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 05/10/2025.
//

import SwiftUI

struct CustomTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(6)
    }
}

extension View {
    func customTextField() -> some View {
        self.modifier(CustomTextFieldStyle())
    }
}
