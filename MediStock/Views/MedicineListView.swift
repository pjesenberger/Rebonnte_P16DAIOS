import SwiftUI

struct MedicineListView: View {
    @ObservedObject var viewModel = MedicineStockViewModel()
    var aisle: String
    @State private var showDeleteAlert = false
    @State private var medicineToDelete: Medicine?
    @State private var showDeleteError = false

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.medicines.isEmpty {
                ProgressView("Loading medicines...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.medicines.isEmpty {
                VStack(spacing: 20) {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        viewModel.retry()
                    }) {
                        Text("Retry")
                            .foregroundStyle(Color.white)
                            .padding(12)
                            .padding(.horizontal)
                            .background(Color.green)
                            .cornerRadius(100)
                    }
                }
            } else {
                List {
                    ForEach(viewModel.medicines.filter { $0.aisle == aisle }, id: \.id) { medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                            VStack(alignment: .leading) {
                                Text(medicine.name)
                                    .font(.headline)
                                Text("Stock: \(medicine.stock)")
                                    .font(.subheadline)
                            }
                        }
                        .disabled(viewModel.isDeletingMedicine)
                        .opacity(viewModel.isDeletingMedicine ? 0.5 : 1.0)
                    }
                    .onDelete { indexSet in
                        let filtered = viewModel.medicines.filter { $0.aisle == aisle }
                        if let index = indexSet.first {
                            medicineToDelete = filtered[index]
                            showDeleteAlert = true
                        }
                    }
                    
                    if viewModel.isDeletingMedicine {
                        HStack {
                            Spacer()
                            ProgressView("Deleting...")
                            Spacer()
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Medicine"),
                message: Text("Are you sure you want to delete \(medicineToDelete?.name ?? "")?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let medicine = medicineToDelete {
                        viewModel.deleteMedicine(medicine) { success in
                            if !success {
                                showDeleteError = true
                            }
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete Error", isPresented: $showDeleteError, actions: {
            Button("Retry") {
                if let medicine = medicineToDelete {
                    viewModel.deleteMedicine(medicine) { success in
                        if !success {
                            showDeleteError = true
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.errorMessage = nil
                medicineToDelete = nil
            }
        }, message: {
            Text("Failed to delete \(medicineToDelete?.name ?? "medicine"). Please try again.")
        })
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil && !viewModel.medicines.isEmpty && !showDeleteError), actions: {
            Button("Retry") {
                viewModel.retry()
            }
            Button("Cancel", role: .cancel) {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .navigationBarTitle(aisle)
        .onAppear {
            viewModel.fetchMedicines()
        }
    }
}

struct MedicineListView_Previews: PreviewProvider {
    static var previews: some View {
        MedicineListView(aisle: "Aisle 1").environmentObject(SessionStore())
    }
}
