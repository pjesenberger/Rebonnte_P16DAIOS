//
//  FirebaseService.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 31/10/2025.
//

import Foundation
import Firebase

class FirebaseService: FirebaseServiceProtocol {
    var firestore: Firestore {
        return Firestore.firestore()
    }
    
    var auth: Auth {
        return Auth.auth()
    }
    
    // MARK: - Medicines
    
    func addMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void) {
        do {
            let documentRef = firestore.collection("medicines").document()
            var newMedicine = medicine
            newMedicine.id = documentRef.documentID
            
            try documentRef.setData(from: newMedicine) { error in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func deleteMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void) {
        guard let id = medicine.id else {
            completion(false)
            return
        }
        
        firestore.collection("medicines").document(id).delete { error in
            completion(error == nil)
        }
    }
    
    func updateMedicineStock(_ medicineId: String, newStock: Int, completion: @escaping (Bool) -> Void) {
        firestore.collection("medicines").document(medicineId).updateData([
            "stock": newStock
        ]) { error in
            completion(error == nil)
        }
    }
    
    func updateMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void) {
        guard let id = medicine.id else {
            completion(false)
            return
        }
        
        do {
            try firestore.collection("medicines").document(id).setData(from: medicine) { error in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func fetchMedicines(sortedBy sortOption: SortOption, pageSize: Int, lastDocument: DocumentSnapshot?, completion: @escaping (Result<([Medicine], DocumentSnapshot?), Error>) -> Void) {
        var query: Query = firestore.collection("medicines").limit(to: pageSize)
        
        switch sortOption {
        case .name:
            query = query.order(by: "name", descending: false)
        case .stock:
            query = query.order(by: "stock", descending: false)
        case .none:
            break
        }
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        query.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let medicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                
                completion(.success((medicines, querySnapshot?.documents.last)))
            }
        }
    }
    
    func fetchAllAisles(completion: @escaping ([String]) -> Void) {
        firestore.collection("medicines").addSnapshotListener { querySnapshot, error in
            if error != nil {
                completion([])
            } else {
                let allMedicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                let aisles = Array(Set(allMedicines.map { $0.aisle })).sorted()
                completion(aisles)
            }
        }
    }
    
    func listenToMedicine(id: String, update: @escaping (Medicine) -> Void) -> ListenerRegistration {
        return firestore.collection("medicines").document(id).addSnapshotListener { documentSnapshot, error in
            if let document = documentSnapshot,
               let updatedMedicine = try? document.data(as: Medicine.self) {
                update(updatedMedicine)
            }
        }
    }
    
    // MARK: - History
    
    func addHistory(_ entry: HistoryEntry) {
        do {
            try firestore.collection("history").document(entry.id ?? UUID().uuidString).setData(from: entry)
        } catch {
            print("Error adding history: \(error)")
        }
    }
    
    func fetchHistory(for medicineId: String, pageSize: Int, lastDocument: DocumentSnapshot?, completion: @escaping (Result<([HistoryEntry], DocumentSnapshot?), Error>) -> Void) {
        var query: Query = firestore.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        query.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let history = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: HistoryEntry.self)
                } ?? []
                
                completion(.success((history, querySnapshot?.documents.last)))
            }
        }
    }
}
