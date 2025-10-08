import SwiftUI

struct MedicineDetailView: View {
    @State var medicine: Medicine
    @ObservedObject var viewModel = MedicineStockViewModel()
    @EnvironmentObject var session: SessionStore
    @State private var showDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Label(medicine.name, systemImage: "pill.fill")
                    .font(.largeTitle)
                    .padding(.top, 20)
                
                // Medicine Name
                medicineNameSection
                
                // Medicine Stock
                medicineStockSection
                
                // Medicine Aisle
                medicineAisleSection
                
                // History Section
                historySection
            }
            .padding()
        }
        .navigationBarTitle("Medicine Details", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SymbolButton(systemName: "trash", color: .red, font: .body) {
                    showDeleteAlert = true
                }
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Medicine"),
                message: Text("Are you sure you want to delete \(medicine.name)?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteMedicine(medicine)
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            viewModel.fetchHistory(for: medicine)
        }
        .onChange(of: medicine) { oldValue, newValue in
            viewModel.updateMedicine(medicine, user: session.session?.uid ?? "")
        }
    }
}

extension MedicineDetailView {
    private var medicineNameSection: some View {
        VStack(alignment: .leading) {
            Text("Name")
                .font(.headline)
            TextField("Name", text: $medicine.name, onCommit: {
                viewModel.updateMedicine(medicine, user: session.session?.uid ?? "")
            })
            .customTextField()
        }
    }
    
    private var medicineStockSection: some View {
        VStack(alignment: .leading) {
            Text("Stock")
                .font(.headline)
            
            HStack {
                TextField("Stock", value: $medicine.stock, formatter: NumberFormatter(), onCommit: {
                    viewModel.updateMedicine(medicine, user: session.session?.uid ?? "")
                })
                .customTextField()
                
                SymbolButton(systemName: "plus.square", color: .green, font: .title) {
                    viewModel.increaseStock(medicine, user: session.session?.uid ?? "")
                }
                
                SymbolButton(systemName: "minus.square", color: .red, font: .title) {
                    viewModel.decreaseStock(medicine, user: session.session?.uid ?? "")
                }
            }
        }
    }
    
    private var medicineAisleSection: some View {
        VStack(alignment: .leading) {
            Text("Aisle")
                .font(.headline)
            TextField("Aisle", text: $medicine.aisle, onCommit: {
                viewModel.updateMedicine(medicine, user: session.session?.uid ?? "")
            })
            .customTextField()
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
                }
            }
        }
    }
}

struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMedicine = Medicine(name: "Sample", stock: 10, aisle: "Aisle 1")
        let sampleViewModel = MedicineStockViewModel()
        MedicineDetailView(medicine: sampleMedicine, viewModel: sampleViewModel).environmentObject(SessionStore())
    }
}
