//
//  FirebaseServiceProtocol.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 31/10/2025.
//

import Firebase
import Foundation

protocol FirebaseServiceProtocol {
    var firestore: Firestore { get }
    var auth: Auth { get }
    
    // Medicines
    func addMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void)
    func deleteMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void)
    func updateMedicineStock(_ medicineId: String, newStock: Int, completion: @escaping (Bool) -> Void)
    func updateMedicine(_ medicine: Medicine, completion: @escaping (Bool) -> Void)
    func fetchMedicines(sortedBy sortOption: SortOption, pageSize: Int, lastDocument: DocumentSnapshot?, completion: @escaping (Result<([Medicine], DocumentSnapshot?), Error>) -> Void)
    func fetchAllAisles(completion: @escaping ([String]) -> Void)
    func listenToMedicine(id: String, update: @escaping (Medicine) -> Void) -> ListenerRegistration
    
    // History
    func addHistory(_ entry: HistoryEntry)
    func fetchHistory(for medicineId: String, pageSize: Int, lastDocument: DocumentSnapshot?, completion: @escaping (Result<([HistoryEntry], DocumentSnapshot?), Error>) -> Void)
}
