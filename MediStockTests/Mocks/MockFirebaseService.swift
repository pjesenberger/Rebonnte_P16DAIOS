//
//  MockFirebaseService.swift
//  MediStockTests
//
//  Created by Pascal Jesenberger on 31/10/2025.
//

import Foundation
import Firebase
@testable import MediStock

class MockFirebaseService: FirebaseServiceProtocol {
    // Mock storage
    var medicines: [Medicine] = []
    var historyEntries: [HistoryEntry] = []
    var aisles: [String] = []
    
    // Mock responses
    var shouldSucceed = true
    var errorToThrow: Error?
    
    // Call tracking
    var addMedicineCalled = false
    var deleteMedicineCalled = false
    var updateMedicineStockCalled = false
    var updateMedicineCalled = false
    var fetchMedicinesCalled = false
    var fetchAllAislesCalled = false
    var addHistoryCalled = false
    var fetchHistoryCalled = false
    
    // Firebase properties (not used in tests but required by protocol)
    private lazy var mockFirestore: Firestore = {
        fatalError("Should not access Firestore in tests")
    }()

    var firestore: Firestore {
        return mockFirestore
    }
    
    var auth: Auth {
        return Auth.auth()
    }
    
    // MARK: - Medicines
    
    func addMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void) {
        addMedicineCalled = true
        
        if shouldSucceed {
            var newMedicine = medicine
            newMedicine.id = newMedicine.id ?? UUID().uuidString
            medicines.append(newMedicine)
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func deleteMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void) {
        deleteMedicineCalled = true
        
        if shouldSucceed {
            medicines.removeAll { $0.id == medicine.id }
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func updateMedicineStock(_ medicineId: String, newStock: Int, completion: @escaping (Bool) -> Void) {
        updateMedicineStockCalled = true
        
        if shouldSucceed {
            if let index = medicines.firstIndex(where: { $0.id == medicineId }) {
                medicines[index].stock = newStock
            }
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func updateMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void) {
        updateMedicineCalled = true
        
        if shouldSucceed {
            if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
                medicines[index] = medicine
            }
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func fetchMedicines(sortedBy sortOption: SortOption, pageSize: Int, lastDocument: DocumentSnapshot?, completion: @escaping (Result<([Medicine], DocumentSnapshot?), Error>) -> Void) {
        fetchMedicinesCalled = true
        
        if let error = errorToThrow {
            completion(.failure(error))
            return
        }
        
        if shouldSucceed {
            var sortedMedicines = medicines
            
            switch sortOption {
            case .name:
                sortedMedicines.sort { $0.name < $1.name }
            case .stock:
                sortedMedicines.sort { $0.stock < $1.stock }
            case .none:
                break
            }
            
            let limitedMedicines = Array(sortedMedicines.prefix(pageSize))
            completion(.success((limitedMedicines, nil)))
        } else {
            let error = NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock fetch failed"])
            completion(.failure(error))
        }
    }
    
    func fetchAllAisles(completion: @escaping ([String]) -> Void) {
        fetchAllAislesCalled = true
        
        if shouldSucceed {
            let uniqueAisles = Array(Set(medicines.map { $0.aisle })).sorted()
            completion(uniqueAisles)
        } else {
            completion([])
        }
    }
    
    func listenToMedicine(id: String, update: @escaping (Medicine) -> Void) -> ListenerRegistration {
        return MockListenerRegistration()
    }
    
    // MARK: - History
    
    func addHistory(_ entry: HistoryEntry) {
        addHistoryCalled = true
        
        var newEntry = entry
        newEntry.id = newEntry.id ?? UUID().uuidString
        historyEntries.append(newEntry)
    }
    
    func fetchHistory(for medicineId: String, pageSize: Int, lastDocument: DocumentSnapshot?, completion: @escaping (Result<([HistoryEntry], DocumentSnapshot?), Error>) -> Void) {
        fetchHistoryCalled = true
        
        if let error = errorToThrow {
            completion(.failure(error))
            return
        }
        
        if shouldSucceed {
            let filtered = historyEntries.filter { $0.medicineId == medicineId }
            let sorted = filtered.sorted { $0.timestamp > $1.timestamp }
            let limited = Array(sorted.prefix(pageSize))
            completion(.success((limited, nil)))
        } else {
            let error = NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock history fetch failed"])
            completion(.failure(error))
        }
    }
}

// Mock listener registration - hérite de NSObject pour conformer au protocole
class MockListenerRegistration: NSObject, ListenerRegistration {
    func remove() {
        // Do nothing in mock - just a placeholder
    }
}
