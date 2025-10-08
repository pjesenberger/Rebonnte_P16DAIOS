import SwiftUI

struct MedicineListView: View {
    @ObservedObject var viewModel = MedicineStockViewModel()
    var aisle: String
    @State private var showDeleteAlert = false
    @State private var medicineToDelete: Medicine?

    var body: some View {
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
            }
            .onDelete { indexSet in
                let filtered = viewModel.medicines.filter { $0.aisle == aisle }
                if let index = indexSet.first {
                    medicineToDelete = filtered[index]
                    showDeleteAlert = true
                }
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Medicine"),
                message: Text("Are you sure you want to delete \(medicineToDelete?.name ?? "")?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let medicine = medicineToDelete {
                        viewModel.deleteMedicine(medicine)
                    }
                },
                secondaryButton: .cancel()
            )
        }
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
