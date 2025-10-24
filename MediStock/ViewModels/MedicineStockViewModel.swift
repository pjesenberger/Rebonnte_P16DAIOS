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

    func fetchMedicines() {
        isLoading = true
        errorMessage = nil
        
        db.collection("medicines").addSnapshotListener { (querySnapshot, error) in
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
        
        do {
            let documentRef = db.collection("medicines").document()
            var newMedicine = medicine
            newMedicine.id = documentRef.documentID
            
            try documentRef.setData(from: newMedicine) { error in
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
        } catch let error {
            self.isLoading = false
            print("Error encoding medicine: \(error)")
            self.errorMessage = "Failed to add medicine. Please try again."
            completion?(false)
        }
    }

    func addRandomMedicine(user: String) {
        let medicine = Medicine(name: "Medicine \(Int.random(in: 1...100))", stock: Int.random(in: 1...100), aisle: "Aisle \(Int.random(in: 1...10))")
        do {
            try db.collection("medicines").document(medicine.id ?? UUID().uuidString).setData(from: medicine)
            addHistory(action: "Added \(medicine.name)", user: user, medicineId: medicine.id ?? "", details: "Added new medicine")
        } catch let error {
            print("Error adding document: \(error)")
            self.errorMessage = "Failed to add medicine. Please try again."
        }
    }

    func deleteMedicines(at offsets: IndexSet) {
        offsets.map { medicines[$0] }.forEach { medicine in
            if let id = medicine.id {
                db.collection("medicines").document(id).delete { error in
                    if let error = error {
                        print("Error removing document: \(error)")
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
        
        db.collection("medicines").document(id).delete { error in
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

    func increaseStock(_ medicine: Medicine, user: String) {
        updateStock(medicine, by: 1, user: user)
    }

    func decreaseStock(_ medicine: Medicine, user: String) {
        updateStock(medicine, by: -1, user: user)
    }

    private func updateStock(_ medicine: Medicine, by amount: Int, user: String) {
        guard let id = medicine.id else { return }
        let newStock = medicine.stock + amount
        db.collection("medicines").document(id).updateData([
            "stock": newStock
        ]) { error in
            if let error = error {
                print("Error updating stock: \(error)")
                self.errorMessage = "Failed to update stock. Please try again."
            } else {
                if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                    self.medicines[index].stock = newStock
                }
                self.addHistory(action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(amount)", user: user, medicineId: id, details: "Stock changed from \(medicine.stock - amount) to \(newStock)")
            }
        }
    }

    func updateMedicine(_ medicine: Medicine, user: String) {
        guard let id = medicine.id else { return }
        do {
            try db.collection("medicines").document(id).setData(from: medicine)
            addHistory(action: "Updated \(medicine.name)", user: user, medicineId: id, details: "Updated medicine details")
        } catch let error {
            print("Error updating document: \(error)")
            self.errorMessage = "Failed to update medicine. Please try again."
        }
    }

    private func addHistory(action: String, user: String, medicineId: String, details: String) {
        let history = HistoryEntry(medicineId: medicineId, user: user, action: action, details: details)
        do {
            try db.collection("history").document(history.id ?? UUID().uuidString).setData(from: history)
        } catch let error {
            print("Error adding history: \(error)")
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
