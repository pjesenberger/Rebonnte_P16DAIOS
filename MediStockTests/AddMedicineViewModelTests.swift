//
//  MediStockTests.swift
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

    override func setUp() {
        super.setUp()
        stockVM = MedicineStockViewModel()
        session = SessionStore()
        addVM = AddMedicineViewModel(stockViewModel: stockVM, session: session)
    }

    func testFormValidation() {
        addVM.name = "Name"
        addVM.stock = "10"
        addVM.aisle = "Aisle1"
        XCTAssertTrue(addVM.isFormValid)

        addVM.name = " "
        XCTAssertFalse(addVM.isFormValid)

        addVM.name = "Name"
        addVM.stock = "-1"
        XCTAssertFalse(addVM.isFormValid)

        addVM.stock = "Aisle1"
        XCTAssertFalse(addVM.isFormValid)
    }

    func testNameError() {
        addVM.name = " "
        XCTAssertEqual(addVM.nameError, "Medicine name cannot be empty")
        addVM.name = "Name"
        XCTAssertNil(addVM.nameError)
    }

    func testStockError() {
        addVM.stock = "-5"
        XCTAssertEqual(addVM.stockError, "Stock must be a positive number")
        addVM.stock = "abc"
        XCTAssertEqual(addVM.stockError, "Stock must be a valid number")
        addVM.stock = "10"
        XCTAssertNil(addVM.stockError)
    }

    func testAisleError() {
        addVM.aisle = " "
        XCTAssertEqual(addVM.aisleError, "Aisle cannot be empty")
        addVM.aisle = "Aisle1"
        XCTAssertNil(addVM.aisleError)
    }
}
