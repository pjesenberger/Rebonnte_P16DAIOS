//
//  DeleteConfirmationModifier.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 14/10/2025.
//

import SwiftUI

struct DeleteConfirmationModifier: ViewModifier {
    @Binding var showAlert: Bool
    let itemName: String
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Delete Medicine"),
                    message: Text("Are you sure you want to delete \(itemName)?"),
                    primaryButton: .destructive(Text("Delete")) {
                        onDelete()
                    },
                    secondaryButton: .cancel()
                )
            }
    }
}

extension View {
    func deleteConfirmation(
        isPresented: Binding<Bool>,
        itemName: String,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(DeleteConfirmationModifier(
            showAlert: isPresented,
            itemName: itemName,
            onDelete: onDelete
        ))
    }
}
