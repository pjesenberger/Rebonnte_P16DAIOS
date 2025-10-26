import SwiftUI

struct AllMedicinesView: View {
    @ObservedObject var viewModel: MedicineStockViewModel
    @State private var filterText: String = ""
    @State private var sortOption: SortOption = .none
    @State private var showDeleteAlert = false
    @State private var medicineToDelete: Medicine?
    @State private var showDeleteError = false
    @State private var showingAddMedicine = false
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Filter by name", text: $filterText)
                        .customTextField()
                    
                    Spacer()

                    Picker("Sort by", selection: $sortOption) {
                        Text("None").tag(SortOption.none)
                        Text("Name").tag(SortOption.name)
                        Text("Stock").tag(SortOption.stock)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding([.horizontal, .top])
                
                ZStack {
                    if viewModel.isLoading && viewModel.medicines.isEmpty {
                        Spacer()
                        LoadingStateView(message: "Loading medicines...")
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.medicines.isEmpty {
                        Spacer()
                        ErrorStateView(errorMessage: errorMessage) {
                            viewModel.retry()
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach($viewModel.medicines.filter { med in
                                (filterText.isEmpty || med.wrappedValue.name.lowercased().contains(filterText.lowercased()))
                            }, id: \.wrappedValue.id) { $medicine in
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
                                    if medicine.id == filteredAndSortedMedicines.last?.id {
                                        viewModel.loadMoreMedicines(sortedBy: sortOption)
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                if let index = indexSet.first {
                                    medicineToDelete = filteredAndSortedMedicines[index]
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
                .navigationBarTitle("All Medicines")
                .navigationBarItems(trailing: Button(action: {
                    showingAddMedicine = true
                }) {
                    Image(systemName: "plus")
                })
            }
        }
        .sheet(isPresented: $showingAddMedicine) {
            AddMedicineView(stockViewModel: viewModel, session: session)
        }
        .onAppear {
            viewModel.fetchMedicines(sortedBy: sortOption)
        }
        .onChange(of: sortOption) {
            viewModel.fetchMedicines(sortedBy: sortOption)
        }
    }
    
    var filteredAndSortedMedicines: [Medicine] {
        var medicines = viewModel.medicines
        if !filterText.isEmpty {
            medicines = medicines.filter { $0.name.lowercased().contains(filterText.lowercased()) }
        }
        return medicines
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case none
    case name
    case stock

    var id: String { self.rawValue }
}

struct AllMedicinesView_Previews: PreviewProvider {
    static var previews: some View {
        AllMedicinesView(viewModel: MedicineStockViewModel())
    }
}
