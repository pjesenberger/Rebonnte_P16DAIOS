import SwiftUI

struct MedicineDetailView: View {
    @Binding var medicine: Medicine
    @ObservedObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var session: SessionStore
    @State private var showDeleteAlert = false
    @State private var showDeleteError = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            if viewModel.isDeletingMedicine || viewModel.isUpdatingMedicine {
                VStack(spacing: 20) {
                    ProgressView(viewModel.isDeletingMedicine ? "Deleting medicine..." : "Updating medicine...")
                    Text("Please wait...")
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Label {
                            Text(medicine.name)
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "pill.fill")
                                .foregroundColor(.green)
                        }
                        .font(.largeTitle)
                        .padding(.top, 20)
                        
                        medicineNameSection
                        medicineStockSection
                        medicineAisleSection
                        historySection
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitle("Medicine Details", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SymbolButton(systemName: "trash", color: .red, font: .body) {
                    showDeleteAlert = true
                }
                .disabled(viewModel.isDeletingMedicine || viewModel.isUpdatingMedicine)
            }
        }
        .deleteConfirmation(
            isPresented: $showDeleteAlert,
            itemName: medicine.name
        ) {
            viewModel.deleteMedicine(medicine) { success in
                if success {
                    presentationMode.wrappedValue.dismiss()
                } else {
                    showDeleteError = true
                }
            }
        }
        .errorAlert(
            isPresented: $showDeleteError,
            title: "Delete Error",
            message: "Failed to delete \(medicine.name). Please try again.",
            onRetry: {
                viewModel.deleteMedicine(medicine) { success in
                    if success {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        showDeleteError = true
                    }
                }
            },
            onCancel: {
                viewModel.errorMessage = nil
            }
        )
        .onAppear {
            viewModel.fetchHistory(for: medicine)
            viewModel.listenToMedicine(id: medicine.id!)
        }
    }
}

extension MedicineDetailView {
    private var medicineNameSection: some View {
        VStack(alignment: .leading) {
            Text("Name")
                .font(.headline)
            HStack {
                TextField("Name", text: $medicine.name)
                    .customTextField()
                    .disabled(viewModel.isUpdatingMedicine)
                    .submitLabel(.done)
                    .onSubmit {
                        viewModel.updateMedicine(medicine, user: session.session?.uid ?? "")
                    }
                if viewModel.isUpdatingMedicine {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
    }
    
    private var medicineStockSection: some View {
        VStack(alignment: .leading) {
            Text("Stock")
                .font(.headline)
            
            HStack {
                TextField("Stock", value: $medicine.stock, formatter: NumberFormatter())
                    .customTextField()
                    .disabled(viewModel.isUpdatingMedicine)
                    .submitLabel(.done)
                    .onSubmit {
                        viewModel.updateMedicine(medicine, user: session.session?.uid ?? "")
                    }
                if viewModel.isUpdatingMedicine {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                
                SymbolButton(systemName: "plus.square", color: .green, font: .title) {
                    viewModel.increaseStock(medicine, user: session.session?.uid ?? "")
                }
                .disabled(viewModel.isUpdatingMedicine)
                
                SymbolButton(systemName: "minus.square", color: .red, font: .title) {
                    viewModel.decreaseStock(medicine, user: session.session?.uid ?? "")
                }
                .disabled(viewModel.isUpdatingMedicine)
            }
        }
    }
    
    private var medicineAisleSection: some View {
        VStack(alignment: .leading) {
            Text("Aisle")
                .font(.headline)
            HStack {
                TextField("Aisle", text: $medicine.aisle)
                    .customTextField()
                    .disabled(viewModel.isUpdatingMedicine)
                    .submitLabel(.done)
                    .onSubmit {
                        viewModel.updateMedicine(medicine, user: session.session?.uid ?? "")
                    }
                if viewModel.isUpdatingMedicine {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading) {
            Text("History")
                .font(.headline)
                .padding(.vertical, 20)
            
            let filteredHistory = viewModel.history.filter { $0.medicineId == medicine.id }
            
            if filteredHistory.isEmpty {
                Text("No history")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(filteredHistory, id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(entry.action)
                            .font(.headline)
                        
                        HistoryField(
                            icon: "person.fill",
                            label: "User",
                            value: entry.user
                        )
                        
                        HistoryField(
                            icon: "clock.fill",
                            label: "Date",
                            value: entry.timestamp.formatted()
                        )
                        
                        HistoryField(
                            icon: "doc.text.fill",
                            label: "Details",
                            value: entry.details,
                            isLast: true
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.bottom, 5)
                    .onAppear {
                        if entry.id == filteredHistory.last?.id {
                            viewModel.loadMoreHistory(for: medicine)
                        }
                    }
                }
                
                if viewModel.isLoadingMoreHistory {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
}

struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMedicine = Medicine(id: "1", name: "Paracetamol", stock: 10, aisle: "A1")
        let sampleViewModel = MedicineStockViewModel()
        MedicineDetailView(medicine: .constant(sampleMedicine), viewModel: sampleViewModel)
            .environmentObject(SessionStore())
    }
}
