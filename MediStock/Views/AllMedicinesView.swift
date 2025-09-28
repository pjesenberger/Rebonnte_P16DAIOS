import SwiftUI

struct AllMedicinesView: View {
    @ObservedObject var viewModel = MedicineStockViewModel()
    @State private var filterText: String = ""
    @State private var sortOption: SortOption = .none

    var body: some View {
        NavigationView {
            VStack {
                // Filtrage et Tri
                HStack {
                    TextField("Filter by name", text: $filterText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 10)
                    
                    Spacer()

                    Picker("Sort by", selection: $sortOption) {
                        Text("None").tag(SortOption.none)
                        Text("Name").tag(SortOption.name)
                        Text("Stock").tag(SortOption.stock)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.trailing, 10)
                }
                .padding(.top, 10)
                
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
                    }
                }
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
