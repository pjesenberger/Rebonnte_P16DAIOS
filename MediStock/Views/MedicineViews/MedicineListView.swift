import SwiftUI

struct MedicineListView: View {
    @ObservedObject var viewModel: MedicineStockViewModel
    var aisle: String
    @State private var showDeleteAlert = false
    @State private var medicineToDelete: Medicine?
    @State private var showDeleteError = false

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.medicines.isEmpty {
                LoadingStateView(message: "Loading medicines...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.medicines.isEmpty {
                ErrorStateView(errorMessage: errorMessage) {
                    viewModel.retry()
                }
            } else {
                List {
                    ForEach($viewModel.medicines.filter { $0.wrappedValue.aisle == aisle }, id: \.wrappedValue.id) { $medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: $medicine, viewModel: viewModel)) {
                            VStack(alignment: .leading) {
                                Text(medicine.name)
                                    .font(.headline)
                                Text("Stock: \(medicine.stock)")
                                    .font(.subheadline)
                            }
                        }
                        .disabledWhileDeleting(viewModel.isDeletingMedicine)
                        .onAppear {
                            let filtered = viewModel.medicines.filter { $0.aisle == aisle }
                            if medicine.id == filtered.last?.id {
                                viewModel.loadMoreMedicines()
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let filtered = viewModel.medicines.filter { $0.aisle == aisle }
                        if let index = indexSet.first {
                            medicineToDelete = filtered[index]
                            showDeleteAlert = true
                        }
                    }
                    
                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                    
                    DeletingOverlay(isDeleting: viewModel.isDeletingMedicine)
                }
            }
        }
        .deleteConfirmation(
            isPresented: $showDeleteAlert,
            itemName: medicineToDelete?.name ?? ""
        ) {
            if let medicine = medicineToDelete {
                viewModel.deleteMedicine(medicine) { success in
                    if !success {
                        showDeleteError = true
                    }
                }
            }
        }
        .errorAlert(
            isPresented: $showDeleteError,
            title: "Delete Error",
            message: "Failed to delete \(medicineToDelete?.name ?? "medicine"). Please try again.",
            onRetry: {
                if let medicine = medicineToDelete {
                    viewModel.deleteMedicine(medicine) { success in
                        if !success {
                            showDeleteError = true
                        }
                    }
                }
            },
            onCancel: {
                viewModel.errorMessage = nil
                medicineToDelete = nil
            }
        )
        .errorAlert(
            isPresented: .constant(viewModel.errorMessage != nil && !viewModel.medicines.isEmpty && !showDeleteError),
            message: viewModel.errorMessage ?? "",
            onRetry: {
                viewModel.retry()
            },
            onCancel: {
                viewModel.errorMessage = nil
            }
        )
        .navigationBarTitle(aisle)
        .onAppear {
            viewModel.fetchMedicines()
        }
    }
}

struct MedicineListView_Previews: PreviewProvider {
    static var previews: some View {
        MedicineListView(viewModel: MedicineStockViewModel(), aisle: "Aisle 1").environmentObject(SessionStore())
    }
}
