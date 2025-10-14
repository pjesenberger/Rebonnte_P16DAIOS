//
//  DisabledWhileDeletingModifier.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 14/10/2025.
//

import SwiftUI

struct DisabledWhileDeletingModifier: ViewModifier {
    let isDeleting: Bool
    
    func body(content: Content) -> some View {
        content
            .disabled(isDeleting)
            .opacity(isDeleting ? 0.5 : 1.0)
    }
}

extension View {
    func disabledWhileDeleting(_ isDeleting: Bool) -> some View {
        modifier(DisabledWhileDeletingModifier(isDeleting: isDeleting))
    }
}
