//
//  AddMedicineViewModelTests.swift
//  MediStockTests
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import XCTest
@testable import MediStock

final class AddMedicineViewModelTests: XCTestCase {
    var stockVM: MedicineStockViewModel!
    var session: SessionStore!
    var addVM: AddMedicineViewModel!
    var mockFirebaseService: MockFirebaseService!

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        stockVM = MedicineStockViewModel(firebaseService: mockFirebaseService)
        session = SessionStore(firebaseService: mockFirebaseService)
        addVM = AddMedicineViewModel()
    }

    override func tearDown() {
        addVM = nil
        stockVM = nil
        session = nil
        mockFirebaseService = nil
        super.tearDown()
    }

    func testFormValidation() {
        addVM.name = "Name"
        addVM.stock = "10"
        addVM.aisle = "Aisle1"
        XCTAssertTrue(addVM.isFormValid, "Form should be valid with all correct values")

        addVM.name = " "
        XCTAssertFalse(addVM.isFormValid, "Form should be invalid with empty name")

        addVM.name = "Name"
        addVM.stock = "-1"
        XCTAssertFalse(addVM.isFormValid, "Form should be invalid with negative stock")

        addVM.stock = "abc"
        XCTAssertFalse(addVM.isFormValid, "Form should be invalid with non-numeric stock")
        
        addVM.stock = "10"
        XCTAssertTrue(addVM.isFormValid, "Form should be valid again")
    }

    func testNameError() {
        addVM.name = " "
        XCTAssertEqual(addVM.nameError, "Medicine name cannot be empty", "Should show error for empty name")
        
        addVM.name = "Name"
        XCTAssertNil(addVM.nameError, "Should have no error for valid name")
        
        addVM.name = ""
        XCTAssertNil(addVM.nameError, "Should have no error before user starts typing")
    }

    func testStockError() {
        addVM.stock = "-5"
        XCTAssertEqual(addVM.stockError, "Stock must be a positive number", "Should show error for negative stock")
        
        addVM.stock = "abc"
        XCTAssertEqual(addVM.stockError, "Stock must be a valid number", "Should show error for non-numeric stock")
        
        addVM.stock = "10"
        XCTAssertNil(addVM.stockError, "Should have no error for valid stock")
        
        addVM.stock = ""
        XCTAssertNil(addVM.stockError, "Should have no error before user starts typing")
    }

    func testAisleError() {
        addVM.aisle = " "
        XCTAssertEqual(addVM.aisleError, "Aisle cannot be empty", "Should show error for empty aisle")
        
        addVM.aisle = "Aisle1"
        XCTAssertNil(addVM.aisleError, "Should have no error for valid aisle")
        
        addVM.aisle = ""
        XCTAssertNil(addVM.aisleError, "Should have no error before user starts typing")
    }
    
    func testSaveSuccess() {
        addVM.name = "Medicine 1"
        addVM.stock = "50"
        addVM.aisle = "A1"
        session.session = User(uid: "test123", email: "test@example.com")
        mockFirebaseService.shouldSucceed = true
        let expectation = self.expectation(description: "Save medicine")

        addVM.save(stockViewModel: stockVM, session: session) { success in
            XCTAssertTrue(success, "Save should succeed")
            XCTAssertFalse(self.addVM.showingAlert, "Alert should not be shown on success")
            XCTAssertTrue(self.mockFirebaseService.addMedicineCalled, "addMedicine should be called")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }
    
    func testSaveFailure() {
        addVM.name = "Medicine 1"
        addVM.stock = "50"
        addVM.aisle = "A1"
        session.session = User(uid: "test123", email: "test@example.com")
        mockFirebaseService.shouldSucceed = false
        let expectation = self.expectation(description: "Save medicine failure")
        
        addVM.save(stockViewModel: stockVM, session: session) { success in
            XCTAssertFalse(success, "Save should fail")
            XCTAssertTrue(self.addVM.showingAlert, "Alert should be shown on failure")
            XCTAssertFalse(self.addVM.alertMessage.isEmpty, "Alert message should not be empty")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSaveWithInvalidStock() {
        addVM.name = "Medicine 1"
        addVM.stock = "-10"
        addVM.aisle = "A1"
        session.session = User(uid: "test123", email: "test@example.com")
        let expectation = self.expectation(description: "Save with invalid stock")
        
        addVM.save(stockViewModel: stockVM, session: session) { success in
            XCTAssertFalse(success, "Save should fail with invalid stock")
            XCTAssertTrue(self.addVM.showingAlert, "Alert should be shown")
            XCTAssertEqual(self.addVM.alertMessage, "Stock must be a positive number", "Should show correct error message")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSaveWithNonNumericStock() {
        addVM.name = "Medicine 1"
        addVM.stock = "abc"
        addVM.aisle = "A1"
        session.session = User(uid: "test123", email: "test@example.com")
        let expectation = self.expectation(description: "Save with non-numeric stock")
        
        addVM.save(stockViewModel: stockVM, session: session) { success in
            XCTAssertFalse(success, "Save should fail with non-numeric stock")
            XCTAssertTrue(self.addVM.showingAlert, "Alert should be shown")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
}
