import Foundation
import Firebase

class MedicineStockViewModel: ObservableObject {
    // Data arrays
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var history: [HistoryEntry] = []
    
    // Loading and error states
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDeletingMedicine = false
    @Published var isUpdatingMedicine = false
    
    // Lazy Loading of Medicines
    @Published var isLoadingMore = false
    @Published var hasMoreMedicines = true
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    
    // Lazy Loading of History
    @Published var isLoadingMoreHistory = false
    @Published var hasMoreHistory = true
    private var lastHistoryDocument: DocumentSnapshot?
    private let historyPageSize = 10
    
    private var db: Firestore
    
    init() {
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        
        if isRunningTests {
            self.db = Firestore.firestore()
        } else {
            self.db = Firestore.firestore()
        }
    }
    
    // MARK: - Medicines funcs
    
    func fetchMedicines(sortedBy sortOption: SortOption = .none) {
        isLoading = true
        errorMessage = nil
        lastDocument = nil
        hasMoreMedicines = true
        
        var query: Query = db.collection("medicines").limit(to: pageSize)
        
        switch sortOption {
        case .name:
            query = query.order(by: "name", descending: false)
        case .stock:
            query = query.order(by: "stock", descending: false)
        case .none:
            break
        }
        
        query.getDocuments { (querySnapshot, error) in
            self.isLoading = false
            
            if let error = error {
                print("Error getting documents: \(error)")
                self.errorMessage = "Failed to load medicines. Please try again."
            } else {
                self.medicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                
                self.lastDocument = querySnapshot?.documents.last
                self.hasMoreMedicines = (querySnapshot?.documents.count ?? 0) >= self.pageSize
                self.errorMessage = nil
            }
        }
    }
    
    func loadMoreMedicines(sortedBy sortOption: SortOption = .none) {
        guard !isLoadingMore && hasMoreMedicines, let lastDocument = lastDocument else { return }
        
        isLoadingMore = true
        
        var query: Query = db.collection("medicines").limit(to: pageSize)
        
        switch sortOption {
        case .name:
            query = query.order(by: "name", descending: false)
        case .stock:
            query = query.order(by: "stock", descending: false)
        case .none:
            break
        }
        
        query = query.start(afterDocument: lastDocument)
        
        query.getDocuments { (querySnapshot, error) in
            self.isLoadingMore = false
            
            if let error = error {
                print("Error loading more documents: \(error)")
            } else {
                let newMedicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                
                self.medicines.append(contentsOf: newMedicines)
                self.lastDocument = querySnapshot?.documents.last
                self.hasMoreMedicines = (querySnapshot?.documents.count ?? 0) >= self.pageSize
            }
        }
    }
    
    func listenToMedicine(id: String) {
        db.collection("medicines").document(id).addSnapshotListener { documentSnapshot, error in
            if let document = documentSnapshot {
                if let updatedMedicine = try? document.data(as: Medicine.self) {
                    DispatchQueue.main.async {
                        if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                            self.medicines[index] = updatedMedicine
                        }
                    }
                }
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
    
    // Unused func
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
    
    func retry() {
        fetchMedicines()
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
    
    // MARK: - Medicine Updates funcs
    
    func increaseStock(_ medicine: Medicine, user: String, completion: ((Int) -> Void)? = nil) {
        updateStock(medicine, by: 1, user: user, completion: completion)
    }
    
    func decreaseStock(_ medicine: Medicine, user: String, completion: ((Int) -> Void)? = nil) {
        updateStock(medicine, by: -1, user: user, completion: completion)
    }
    
    
    private func updateStock(_ medicine: Medicine, by amount: Int, user: String, completion: ((Int) -> Void)? = nil) {
        guard let id = medicine.id else { return }
        let newStock = medicine.stock + amount
        isUpdatingMedicine = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.db.collection("medicines").document(id).updateData([
                "stock": newStock
            ]) { error in
                DispatchQueue.main.async {
                    self.isUpdatingMedicine = false
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
        isUpdatingMedicine = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.db.collection("medicines").document(id).setData(from: medicine) { error in
                    DispatchQueue.main.async {
                        self.isUpdatingMedicine = false
                        if let error = error {
                            print("Error updating document: \(error)")
                            self.errorMessage = "Failed to update medicine. Please try again."
                        } else {
                            self.addHistory(action: "Updated \(medicine.name)", user: user, medicineId: id, details: "Updated medicine details")
                        }
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    self.isUpdatingMedicine = false
                    print("Error updating document: \(error)")
                    self.errorMessage = "Failed to update medicine. Please try again."
                }
            }
        }
    }
    
    // MARK: - History funcs
    
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
        
        lastHistoryDocument = nil
        hasMoreHistory = true
        
        db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .limit(to: historyPageSize)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting history: \(error)")
                    self.errorMessage = "Failed to load history. Please try again."
                } else {
                    self.history = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: HistoryEntry.self)
                    } ?? []
                    
                    self.lastHistoryDocument = querySnapshot?.documents.last
                    self.hasMoreHistory = (querySnapshot?.documents.count ?? 0) >= self.historyPageSize
                    self.errorMessage = nil
                }
            }
    }
    
    func loadMoreHistory(for medicine: Medicine) {
        guard !isLoadingMoreHistory && hasMoreHistory,
              let medicineId = medicine.id,
              let lastDocument = lastHistoryDocument else { return }
        
        isLoadingMoreHistory = true
        
        db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .start(afterDocument: lastDocument)
            .limit(to: historyPageSize)
            .getDocuments { (querySnapshot, error) in
                self.isLoadingMoreHistory = false
                
                if let error = error {
                    print("Error loading more history: \(error)")
                } else {
                    let newHistory = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: HistoryEntry.self)
                    } ?? []
                    
                    self.history.append(contentsOf: newHistory)
                    self.lastHistoryDocument = querySnapshot?.documents.last
                    self.hasMoreHistory = (querySnapshot?.documents.count ?? 0) >= self.historyPageSize
                }
            }
    }
}

// MARK: - Local testing helpers
extension MedicineStockViewModel {
    func addMedicineLocally(_ medicine: Medicine) {
        var newMedicine = medicine
        if newMedicine.id == nil {
            newMedicine.id = UUID().uuidString
        }
        medicines.append(newMedicine)
    }

    func deleteMedicineLocally(_ medicine: Medicine) {
        guard let id = medicine.id else { return }
        medicines.removeAll { $0.id == id }
    }
}
