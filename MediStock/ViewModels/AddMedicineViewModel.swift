//
//  AddMedicineViewModel.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 17/10/2025.
//

import Foundation

class AddMedicineViewModel: ObservableObject {
    @Published var name = ""
    @Published var stock = ""
    @Published var aisle = ""
    @Published var showingAlert = false
    @Published var alertMessage = ""

    var stockViewModel: MedicineStockViewModel
    var session: SessionStore

    init(stockViewModel: MedicineStockViewModel, session: SessionStore) {
        self.stockViewModel = stockViewModel
        self.session = session
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !stock.isEmpty &&
        Int(stock) != nil &&
        Int(stock)! >= 0 &&
        !aisle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var nameError: String? {
        guard !name.isEmpty else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Medicine name cannot be empty"
        }
        return nil
    }
    
    var stockError: String? {
        guard !stock.isEmpty else { return nil }
        if let value = Int(stock) {
            if value < 0 {
                return "Stock must be a positive number"
            }
        } else {
            return "Stock must be a valid number"
        }
        return nil
    }
    
    var aisleError: String? {
        guard !aisle.isEmpty else { return nil }
        let trimmed = aisle.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Aisle cannot be empty"
        }
        return nil
    }

    func save(completion: @escaping (Bool) -> Void) {
        guard let stockValue = Int(stock), stockValue >= 0 else {
            alertMessage = "Stock must be a positive number"
            showingAlert = true
            return
        }

        let newMedicine = Medicine(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            stock: stockValue,
            aisle: aisle.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        stockViewModel.addMedicine(newMedicine, user: session.session?.email ?? "unknown_user") { success in
            if !success {
                self.alertMessage = self.stockViewModel.errorMessage ?? "An error occurred while adding the medicine"
                self.showingAlert = true
            }
            completion(success)
        }
    }
}
