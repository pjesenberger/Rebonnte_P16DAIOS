import Foundation
import Firebase

class MedicineStockViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var history: [HistoryEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDeletingMedicine = false
    
    private var db = Firestore.firestore()

    func fetchMedicines(sortedBy sortOption: SortOption = .none) {
        isLoading = true
        errorMessage = nil
        
        var query: Query = db.collection("medicines")
        
        switch sortOption {
        case .name:
            query = query.order(by: "name", descending: false)
        case .stock:
            query = query.order(by: "stock", descending: false)
        case .none:
            break
        }
        
        query.addSnapshotListener { (querySnapshot, error) in
            self.isLoading = false
            
            if let error = error {
                print("Error getting documents: \(error)")
                self.errorMessage = "Failed to load medicines. Please try again."
            } else {
                self.medicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                self.errorMessage = nil
            }
        }
    }

    func fetchAisles() {
        isLoading = true
        errorMessage = nil
        
        db.collection("medicines").addSnapshotListener { (querySnapshot, error) in
            self.isLoading = false
            
            if let error = error {
                print("Error getting documents: \(error)")
                self.errorMessage = "Failed to load aisles. Please try again."
            } else {
                let allMedicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                self.aisles = Array(Set(allMedicines.map { $0.aisle })).sorted()
                self.errorMessage = nil
            }
        }
    }
    
    func addMedicine(_ medicine: Medicine, user: String, completion: ((Bool) -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let documentRef = self.db.collection("medicines").document()
                var newMedicine = medicine
                newMedicine.id = documentRef.documentID
                
                try documentRef.setData(from: newMedicine) { error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        if let error = error {
                            print("Error adding document: \(error)")
                            self.errorMessage = "Failed to add medicine. Please try again."
                            completion?(false)
                        } else {
                            self.addHistory(
                                action: "Added \(medicine.name)",
                                user: user,
                                medicineId: newMedicine.id ?? "",
                                details: "New medicine added - Stock: \(medicine.stock), Aisle: \(medicine.aisle)"
                            )
                            self.errorMessage = nil
                            completion?(true)
                        }
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error encoding medicine: \(error)")
                    self.errorMessage = "Failed to add medicine. Please try again."
                    completion?(false)
                }
            }
        }
    }

    func addRandomMedicine(user: String) {
        let medicine = Medicine(name: "Medicine \(Int.random(in: 1...100))", stock: Int.random(in: 1...100), aisle: "Aisle \(Int.random(in: 1...10))")
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.db.collection("medicines").document(medicine.id ?? UUID().uuidString).setData(from: medicine)
                self.addHistory(action: "Added \(medicine.name)", user: user, medicineId: medicine.id ?? "", details: "Added new medicine")
            } catch let error {
                DispatchQueue.main.async {
                    print("Error adding document: \(error)")
                    self.errorMessage = "Failed to add medicine. Please try again."
                }
            }
        }
    }

    func deleteMedicines(at offsets: IndexSet) {
        DispatchQueue.global(qos: .userInitiated).async {
            offsets.map { self.medicines[$0] }.forEach { medicine in
                if let id = medicine.id {
                    self.db.collection("medicines").document(id).delete { error in
                        if let error = error {
                            print("Error removing document: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func deleteMedicine(_ medicine: Medicine, completion: ((Bool) -> Void)? = nil) {
        guard let id = medicine.id else {
            completion?(false)
            return
        }
        
        isDeletingMedicine = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.db.collection("medicines").document(id).delete { error in
                DispatchQueue.main.async {
                    self.isDeletingMedicine = false
                    
                    if let error = error {
                        print("Error removing document: \(error)")
                        self.errorMessage = "Failed to delete medicine. Please try again."
                        completion?(false)
                    } else {
                        self.medicines.removeAll { $0.id == id }
                        self.errorMessage = nil
                        completion?(true)
                    }
                }
            }
        }
    }

    func increaseStock(_ medicine: Medicine, user: String, completion: ((Int) -> Void)? = nil) {
        updateStock(medicine, by: 1, user: user, completion: completion)
    }

    func decreaseStock(_ medicine: Medicine, user: String, completion: ((Int) -> Void)? = nil) {
        updateStock(medicine, by: -1, user: user, completion: completion)
    }

    
    private func updateStock(_ medicine: Medicine, by amount: Int, user: String, completion: ((Int) -> Void)? = nil) {
        guard let id = medicine.id else { return }
        let newStock = medicine.stock + amount

        DispatchQueue.global(qos: .userInitiated).async {
            self.db.collection("medicines").document(id).updateData([
                "stock": newStock
            ]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error updating stock: \(error)")
                        self.errorMessage = "Failed to update stock. Please try again."
                    } else {
                        if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                            self.medicines[index].stock = newStock
                            completion?(newStock)
                        }
                        self.addHistory(
                            action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(abs(amount))",
                            user: user,
                            medicineId: id,
                            details: "Stock changed from \(medicine.stock) to \(newStock)"
                        )
                    }
                }
            }
        }
    }

    func updateMedicine(_ medicine: Medicine, user: String) {
        guard let id = medicine.id else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.db.collection("medicines").document(id).setData(from: medicine)
                self.addHistory(action: "Updated \(medicine.name)", user: user, medicineId: id, details: "Updated medicine details")
            } catch let error {
                DispatchQueue.main.async {
                    print("Error updating document: \(error)")
                    self.errorMessage = "Failed to update medicine. Please try again."
                }
            }
        }
    }

    private func addHistory(action: String, user: String, medicineId: String, details: String) {
        let history = HistoryEntry(medicineId: medicineId, user: user, action: action, details: details)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.db.collection("history").document(history.id ?? UUID().uuidString).setData(from: history)
            } catch let error {
                print("Error adding history: \(error)")
            }
        }
    }

    func fetchHistory(for medicine: Medicine) {
        guard let medicineId = medicine.id else { return }
        db.collection("history").whereField("medicineId", isEqualTo: medicineId).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting history: \(error)")
                self.errorMessage = "Failed to load history. Please try again."
            } else {
                self.history = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: HistoryEntry.self)
                } ?? []
            }
        }
    }
    
    func retry() {
        fetchMedicines()
    }
}
