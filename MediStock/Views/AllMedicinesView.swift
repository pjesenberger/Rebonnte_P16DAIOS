import SwiftUI

struct AllMedicinesView: View {
    @ObservedObject var viewModel = MedicineStockViewModel()
    @State private var filterText: String = ""
    @State private var sortOption: SortOption = .none
    @State private var showDeleteAlert = false
    @State private var medicineToDelete: Medicine?
    @State private var showDeleteError = false

    var body: some View {
        NavigationView {
            VStack {
                // Filtrage et Tri
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
                
                // Content avec gestion du loading et des erreurs
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
                        // Liste des Médicaments
                        List {
                            ForEach(filteredAndSortedMedicines, id: \.id) { medicine in
                                NavigationLink(destination: MedicineDetailView(medicine: medicine, viewModel: viewModel)) {
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
                                if let index = indexSet.first {
                                    medicineToDelete = filteredAndSortedMedicines[index]
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
                .navigationBarTitle("All Medicines")
                .navigationBarItems(trailing: Button(action: {
                    viewModel.addRandomMedicine(user: "test_user") // Remplacez par l'utilisateur actuel
                }) {
                    Image(systemName: "plus")
                })
            }
        }
        .onAppear {
            viewModel.fetchMedicines()
        }
    }
    
    var filteredAndSortedMedicines: [Medicine] {
        var medicines = viewModel.medicines

        // Filtrage
        if !filterText.isEmpty {
            medicines = medicines.filter { $0.name.lowercased().contains(filterText.lowercased()) }
        }

        // Tri
        switch sortOption {
        case .name:
            medicines.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .stock:
            medicines.sort { $0.stock < $1.stock }
        case .none:
            break
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
        AllMedicinesView()
    }
}
