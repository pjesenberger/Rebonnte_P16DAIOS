//
//  AddMedicineView.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 15/10/2025.
//

import SwiftUI

struct AddMedicineView: View {
    @StateObject private var viewModel = AddMedicineViewModel()
    @EnvironmentObject var stockViewModel: MedicineStockViewModel
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) var dismiss

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
                leading: cancelButton,
                trailing: saveButton
            )
            .alert("Error", isPresented: $viewModel.showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .overlay {
                if stockViewModel.isLoading {
                    loadingOverlay
                }
            }
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            viewModel.save(stockViewModel: stockViewModel, session: session) { success in
                if success {
                    dismiss()
                }
            }
        }
        .disabled(!viewModel.isFormValid)
    }
    
    private var loadingOverlay: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
    }
}

#Preview {
    AddMedicineView()
        .environmentObject(MedicineStockViewModel())
        .environmentObject(SessionStore())
}
