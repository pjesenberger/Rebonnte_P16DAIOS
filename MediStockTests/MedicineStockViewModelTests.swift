//
//  MedicineStockViewModelTests.swift
//  MediStockTests
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import XCTest
@testable import MediStock

final class MedicineStockViewModelTests: XCTestCase {
    var stockVM: MedicineStockViewModel!
    var mockFirebaseService: MockFirebaseService!

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        stockVM = MedicineStockViewModel(firebaseService: mockFirebaseService)
    }

    override func tearDown() {
        stockVM = nil
        mockFirebaseService = nil
        super.tearDown()
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
    
    func testFetchMedicinesSuccess() {
        let medicine1 = Medicine(id: "1", name: "Medicine 1", stock: 10, aisle: "A1")
        let medicine2 = Medicine(id: "2", name: "Paracetamol", stock: 5, aisle: "A2")
        mockFirebaseService.medicines = [medicine1, medicine2]
        mockFirebaseService.shouldSucceed = true
        
        let expectation = self.expectation(description: "Fetch medicines")
        
        stockVM.fetchMedicines()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.mockFirebaseService.fetchMedicinesCalled)
            XCTAssertEqual(self.stockVM.medicines.count, 2)
            XCTAssertFalse(self.stockVM.isLoading)
            XCTAssertNil(self.stockVM.errorMessage)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testFetchMedicinesFailure() {
        mockFirebaseService.shouldSucceed = false
        let expectation = self.expectation(description: "Fetch medicines failure")
        
        stockVM.fetchMedicines()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.mockFirebaseService.fetchMedicinesCalled)
            XCTAssertEqual(self.stockVM.medicines.count, 0)
            XCTAssertNotNil(self.stockVM.errorMessage)
            XCTAssertFalse(self.stockVM.isLoading)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testAddMedicineSuccess() {
        let medicine = Medicine(name: "Ibuprofen", stock: 20, aisle: "B1")
        mockFirebaseService.shouldSucceed = true
        let expectation = self.expectation(description: "Add medicine")
        
        stockVM.addMedicine(medicine, user: "test@example.com") { success in
            XCTAssertTrue(success, "Medicine should be added successfully")
            XCTAssertNil(self.stockVM.errorMessage, "Error message should be nil")
            XCTAssertTrue(self.mockFirebaseService.addMedicineCalled, "addMedicine should be called")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                XCTAssertTrue(self.mockFirebaseService.addHistoryCalled, "addHistory should be called")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testAddMedicineFailure() {
        let medicine = Medicine(name: "FailMedicine", stock: 10, aisle: "X1")
        mockFirebaseService.shouldSucceed = false
        let expectation = self.expectation(description: "Add medicine failure")
        
        stockVM.addMedicine(medicine, user: "test@example.com") { success in
            XCTAssertFalse(success, "Medicine addition should fail")
            XCTAssertNotNil(self.stockVM.errorMessage, "Error message should be set")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testDeleteMedicineSuccess() {
        let medicine = Medicine(id: "123", name: "ToDelete", stock: 5, aisle: "C1")
        stockVM.medicines = [medicine]
        mockFirebaseService.shouldSucceed = true
        let expectation = self.expectation(description: "Delete medicine")
        
        stockVM.deleteMedicine(medicine) { success in
            XCTAssertTrue(success, "Medicine should be deleted successfully")
            XCTAssertEqual(self.stockVM.medicines.count, 0, "Medicines array should be empty")
            XCTAssertTrue(self.mockFirebaseService.deleteMedicineCalled, "deleteMedicine should be called")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testDeleteMedicineFailure() {
        let medicine = Medicine(id: "123", name: "ToDelete", stock: 5, aisle: "C1")
        stockVM.medicines = [medicine]
        mockFirebaseService.shouldSucceed = false
        let expectation = self.expectation(description: "Delete medicine failure")
        
        stockVM.deleteMedicine(medicine) { success in
            XCTAssertFalse(success, "Medicine deletion should fail")
            XCTAssertEqual(self.stockVM.medicines.count, 1, "Medicines array should still contain the medicine")
            XCTAssertNotNil(self.stockVM.errorMessage, "Error message should be set")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testIncreaseStockSuccess() {
        var medicine = Medicine(id: "123", name: "Test", stock: 10, aisle: "D1")
        stockVM.medicines = [medicine]
        medicine.id = "123"
        mockFirebaseService.medicines = [medicine]
        mockFirebaseService.shouldSucceed = true
        let expectation = self.expectation(description: "Increase stock")
        
        stockVM.increaseStock(medicine, user: "test@example.com") { newStock in
            XCTAssertEqual(newStock, 11, "Stock should be increased to 11")
            XCTAssertTrue(self.mockFirebaseService.updateMedicineStockCalled, "updateMedicineStock should be called")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                XCTAssertTrue(self.mockFirebaseService.addHistoryCalled, "addHistory should be called")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testDecreaseStockSuccess() {
        var medicine = Medicine(id: "123", name: "Test", stock: 10, aisle: "D1")
        stockVM.medicines = [medicine]
        medicine.id = "123"
        mockFirebaseService.medicines = [medicine]
        mockFirebaseService.shouldSucceed = true
        let expectation = self.expectation(description: "Decrease stock")
        
        stockVM.decreaseStock(medicine, user: "test@example.com") { newStock in
            XCTAssertEqual(newStock, 9, "Stock should be decreased to 9")
            XCTAssertTrue(self.mockFirebaseService.updateMedicineStockCalled, "updateMedicineStock should be called")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                XCTAssertTrue(self.mockFirebaseService.addHistoryCalled, "addHistory should be called")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testUpdateMedicineSuccess() {
        let medicine = Medicine(id: "123", name: "Original", stock: 10, aisle: "E1")
        let updatedMedicine = Medicine(id: "123", name: "Updated", stock: 15, aisle: "E2")
        mockFirebaseService.medicines = [medicine]
        mockFirebaseService.shouldSucceed = true
        let expectation = self.expectation(description: "Update medicine")
        
        var updateCalled = false
        var historyCalled = false
        
        stockVM.updateMedicine(updatedMedicine, user: "test@example.com")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateCalled = self.mockFirebaseService.updateMedicineCalled
            historyCalled = self.mockFirebaseService.addHistoryCalled
            XCTAssertTrue(updateCalled, "updateMedicine should be called")
            XCTAssertTrue(historyCalled, "addHistory should be called")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testFetchHistorySuccess() {
        let medicine = Medicine(id: "123", name: "Test", stock: 10, aisle: "E1")
        let historyEntry = HistoryEntry(id: "h1", medicineId: "123", user: "test@example.com", action: "Added", details: "Test")
        mockFirebaseService.historyEntries = [historyEntry]
        mockFirebaseService.shouldSucceed = true
        let expectation = self.expectation(description: "Fetch history")
        
        stockVM.fetchHistory(for: medicine)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.mockFirebaseService.fetchHistoryCalled, "fetchHistory should be called")
            XCTAssertEqual(self.stockVM.history.count, 1, "History should contain 1 entry")
            XCTAssertEqual(self.stockVM.history.first?.medicineId, "123", "History entry should have correct medicineId")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testFetchAislesSuccess() {
        let medicine1 = Medicine(id: "1", name: "Med1", stock: 10, aisle: "A1")
        let medicine2 = Medicine(id: "2", name: "Med2", stock: 5, aisle: "B2")
        let medicine3 = Medicine(id: "3", name: "Med3", stock: 8, aisle: "A1")
        mockFirebaseService.medicines = [medicine1, medicine2, medicine3]
        mockFirebaseService.shouldSucceed = true
        let expectation = self.expectation(description: "Fetch aisles")
        
        stockVM.fetchAisles()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.mockFirebaseService.fetchAllAislesCalled, "fetchAllAisles should be called")
            XCTAssertEqual(self.stockVM.aisles.count, 2, "Should have 2 unique aisles")
            XCTAssertTrue(self.stockVM.aisles.contains("A1"), "Should contain aisle A1")
            XCTAssertTrue(self.stockVM.aisles.contains("B2"), "Should contain aisle B2")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testLoadMoreMedicines() {
        let medicine1 = Medicine(id: "1", name: "Med1", stock: 10, aisle: "A1")
        mockFirebaseService.medicines = [medicine1]
        mockFirebaseService.shouldSucceed = true
        stockVM.medicines = []
        stockVM.hasMoreMedicines = true
        
        let expectation = self.expectation(description: "Load more medicines")
        
        stockVM.fetchMedicines()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.stockVM.loadMoreMedicines()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertTrue(self.mockFirebaseService.fetchMedicinesCalled, "fetchMedicines should be called")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
}
