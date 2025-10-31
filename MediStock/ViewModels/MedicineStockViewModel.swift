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
    
    // Firebase Service - Injection de dépendance
    private let firebaseService: FirebaseServiceProtocol
    
    init(firebaseService: FirebaseServiceProtocol = FirebaseService()) {
        self.firebaseService = firebaseService
    }
    
    // MARK: - Medicines funcs
    
    func fetchMedicines(sortedBy sortOption: SortOption = .none) {
        
        isLoading = true
        errorMessage = nil
        lastDocument = nil
        hasMoreMedicines = true
        
        firebaseService.fetchMedicines(sortedBy: sortOption, pageSize: pageSize, lastDocument: nil) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let (medicines, lastDoc)):
                    self.medicines = medicines
                    self.lastDocument = lastDoc
                    self.hasMoreMedicines = medicines.count >= self.pageSize
                    self.errorMessage = nil
                    
                case .failure(let error):
                    print("Error getting documents: \(error)")
                    self.errorMessage = "Failed to load medicines. Please try again."
                }
            }
        }
    }
    
    func loadMoreMedicines(sortedBy sortOption: SortOption = .none) {
        guard !isLoadingMore && hasMoreMedicines, let lastDocument = lastDocument else { return }
        
        isLoadingMore = true
        
        firebaseService.fetchMedicines(sortedBy: sortOption, pageSize: pageSize, lastDocument: lastDocument) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingMore = false
                
                switch result {
                case .success(let (newMedicines, lastDoc)):
                    self.medicines.append(contentsOf: newMedicines)
                    self.lastDocument = lastDoc
                    self.hasMoreMedicines = newMedicines.count >= self.pageSize
                    
                case .failure(let error):
                    print("Error loading more documents: \(error)")
                }
            }
        }
    }
    
    func listenToMedicine(id: String) {
        
        _ = firebaseService.listenToMedicine(id: id) { [weak self] updatedMedicine in
            DispatchQueue.main.async {
                if let index = self?.medicines.firstIndex(where: { $0.id == id }) {
                    self?.medicines[index] = updatedMedicine
                }
            }
        }
    }
    
    func addMedicine(_ medicine: Medicine, user: String, completion: ((Bool) -> Void)? = nil) {
        
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.firebaseService.addMedicine(medicine) { [weak self] success in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if success {
                        let historyEntry = HistoryEntry(
                            medicineId: medicine.id ?? "",
                            user: user,
                            action: "Added \(medicine.name)",
                            details: "New medicine added - Stock: \(medicine.stock), Aisle: \(medicine.aisle)"
                        )
                        self.addHistory(historyEntry)
                        self.errorMessage = nil
                        completion?(true)
                    } else {
                        self.errorMessage = "Failed to add medicine. Please try again."
                        completion?(false)
                    }
                }
            }
        }
    }
    
    // Unused func - conservée pour compatibilité
    func addRandomMedicine(user: String) {
        
        let medicine = Medicine(
            name: "Medicine \(Int.random(in: 1...100))",
            stock: Int.random(in: 1...100),
            aisle: "Aisle \(Int.random(in: 1...10))"
        )
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.firebaseService.addMedicine(medicine) { [weak self] success in
                if success {
                    let historyEntry = HistoryEntry(
                        medicineId: medicine.id ?? "",
                        user: user,
                        action: "Added \(medicine.name)",
                        details: "Added new medicine"
                    )
                    self?.addHistory(historyEntry)
                } else {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to add medicine. Please try again."
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
            self.firebaseService.deleteMedicine(medicine) { [weak self] success in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isDeletingMedicine = false
                    
                    if success {
                        self.medicines.removeAll { $0.id == id }
                        self.errorMessage = nil
                        completion?(true)
                    } else {
                        print("Error removing document")
                        self.errorMessage = "Failed to delete medicine. Please try again."
                        completion?(false)
                    }
                }
            }
        }
    }
    
    func deleteMedicines(at offsets: IndexSet) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            offsets.map { self.medicines[$0] }.forEach { medicine in
                self.firebaseService.deleteMedicine(medicine) { success in
                    if !success {
                        print("Error removing document")
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
        
        firebaseService.fetchAllAisles { [weak self] aisles in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.aisles = aisles
                self?.errorMessage = nil
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
        
        if let index = self.medicines.firstIndex(where: { $0.id == id }) {
            self.medicines[index].stock = newStock
        }
        
        isUpdatingMedicine = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.firebaseService.updateMedicineStock(id, newStock: newStock) { [weak self] success in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isUpdatingMedicine = false
                    
                    if success {
                        if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                            self.medicines[index].stock = newStock
                        }
                        
                        completion?(newStock)
                        
                        let historyEntry = HistoryEntry(
                            medicineId: id,
                            user: user,
                            action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(abs(amount))",
                            details: "Stock changed from \(medicine.stock) to \(newStock)"
                        )
                        self.addHistory(historyEntry)
                    } else {
                        if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                            self.medicines[index].stock = medicine.stock
                        }
                        
                        print("Error updating stock")
                        self.errorMessage = "Failed to update stock. Please try again."
                        
                        completion?(medicine.stock)
                    }
                }
            }
        }
    }
    
    func updateMedicine(_ medicine: Medicine, user: String) {
        guard let id = medicine.id else { return }
        
        isUpdatingMedicine = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.firebaseService.updateMedicine(medicine) { [weak self] success in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isUpdatingMedicine = false
                    
                    if success {
                        let historyEntry = HistoryEntry(
                            medicineId: id,
                            user: user,
                            action: "Updated \(medicine.name)",
                            details: "Updated medicine details"
                        )
                        self.addHistory(historyEntry)
                    } else {
                        print("Error updating document")
                        self.errorMessage = "Failed to update medicine. Please try again."
                    }
                }
            }
        }
    }
    
    // MARK: - History funcs
    
    private func addHistory(_ entry: HistoryEntry) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.firebaseService.addHistory(entry)
        }
    }
    
    func fetchHistory(for medicine: Medicine) {
        guard let medicineId = medicine.id else { return }
        
        lastHistoryDocument = nil
        hasMoreHistory = true
        
        firebaseService.fetchHistory(for: medicineId, pageSize: historyPageSize, lastDocument: nil) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let (history, lastDoc)):
                    self.history = history
                    self.lastHistoryDocument = lastDoc
                    self.hasMoreHistory = history.count >= self.historyPageSize
                    self.errorMessage = nil
                    
                case .failure(let error):
                    print("Error getting history: \(error)")
                    self.errorMessage = "Failed to load history. Please try again."
                }
            }
        }
    }
    
    func loadMoreHistory(for medicine: Medicine) {
        guard !isLoadingMoreHistory && hasMoreHistory,
              let medicineId = medicine.id,
              let lastDocument = lastHistoryDocument else { return }
        
        isLoadingMoreHistory = true
        
        firebaseService.fetchHistory(for: medicineId, pageSize: historyPageSize, lastDocument: lastDocument) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingMoreHistory = false
                
                switch result {
                case .success(let (newHistory, lastDoc)):
                    self.history.append(contentsOf: newHistory)
                    self.lastHistoryDocument = lastDoc
                    self.hasMoreHistory = newHistory.count >= self.historyPageSize
                    
                case .failure(let error):
                    print("Error loading more history: \(error)")
                }
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
