import UIKit
import XCTest
import VCStepper

class Tests: XCTestCase {
    let stepper: VCStepper = VCStepper()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let rect = CGRect(x: 0, y: 0, width: 200, height: 50)
        stepper.drawRect(rect)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitialValues() {
        XCTAssert(stepper.value == 0, "Initial value should be 1")
    }
}
