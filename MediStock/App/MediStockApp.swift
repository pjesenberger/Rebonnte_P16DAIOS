//
//  MediStockApp.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 31/10/2025.
//

import SwiftUI

@main
struct MediStockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let firebaseService: FirebaseServiceProtocol = FirebaseService()
    
    @StateObject private var sessionStore: SessionStore
    @StateObject private var stockViewModel: MedicineStockViewModel

    init() {
        let service = FirebaseService()
        _sessionStore = StateObject(wrappedValue: SessionStore(firebaseService: service))
        _stockViewModel = StateObject(wrappedValue: MedicineStockViewModel(firebaseService: service))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
                .environmentObject(stockViewModel)
                .tint(Color(.green))
        }
    }
}
