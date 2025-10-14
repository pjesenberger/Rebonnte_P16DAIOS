//
//  ErrorAlertModifier.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 14/10/2025.
//

import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let retryAction: () -> Void
    let cancelAction: () -> Void
    
    init(
        isPresented: Binding<Bool>,
        title: String = "Error",
        message: String,
        onRetry: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.retryAction = onRetry
        self.cancelAction = onCancel
    }
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented, actions: {
                Button("Retry") {
                    retryAction()
                }
                Button("Cancel", role: .cancel) {
                    cancelAction()
                }
            }, message: {
                Text(message)
            })
    }
}

extension View {
    func errorAlert(
        isPresented: Binding<Bool>,
        title: String = "Error",
        message: String,
        onRetry: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        modifier(ErrorAlertModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            onRetry: onRetry,
            onCancel: onCancel
        ))
    }
}
