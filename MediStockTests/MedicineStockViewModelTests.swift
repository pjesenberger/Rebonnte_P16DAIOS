//
//  MediStockTests.swift
//  MediStockTests
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import XCTest
@testable import MediStock

final class MedicineStockViewModelTests: XCTestCase {
    var stockVM: MedicineStockViewModel!

    override func setUp() {
        super.setUp()
        stockVM = MedicineStockViewModel()
    }

    func testAddMedicineLocally() {
        let medicine = Medicine(name: "Name", stock: 5, aisle: "Aisle1")
        stockVM.addMedicineLocally(medicine)
        XCTAssertTrue(stockVM.medicines.contains(where: { $0.name == "Name" }))
    }

    func testDeleteMedicineLocally() {
        var medicine = Medicine(name: "ToDelete", stock: 5, aisle: "Aisle1")
        medicine.id = UUID().uuidString
        stockVM.addMedicineLocally(medicine)
        stockVM.deleteMedicineLocally(medicine)
        XCTAssertFalse(stockVM.medicines.contains(where: { $0.name == "ToDelete" }))
    }

    func testPaginationState() {
        XCTAssertFalse(stockVM.isLoadingMore)
        XCTAssertTrue(stockVM.hasMoreMedicines)
    }
}
