//
//  AddMedicineView.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 15/10/2025.
//

import SwiftUI

struct AddMedicineView: View {
    @StateObject private var viewModel: AddMedicineViewModel
    @Environment(\.dismiss) var dismiss

    init(stockViewModel: MedicineStockViewModel, session: SessionStore) {
        _viewModel = StateObject(wrappedValue: AddMedicineViewModel(stockViewModel: stockViewModel, session: session))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Information")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Medicine Name", text: $viewModel.name)
                        
                        if let error = viewModel.nameError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Stock", text: $viewModel.stock)
                            .keyboardType(.numberPad)
                        
                        if let error = viewModel.stockError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Aisle", text: $viewModel.aisle)
                        
                        if let error = viewModel.aisleError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { viewModel.save { success in if success { dismiss() } } }
                    .disabled(!viewModel.isFormValid)
            )
            .alert("Error", isPresented: $viewModel.showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .overlay {
                if viewModel.stockViewModel.isLoading {
                    ProgressView().scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

#Preview {
    AddMedicineView(stockViewModel: MedicineStockViewModel(), session: SessionStore())
}
