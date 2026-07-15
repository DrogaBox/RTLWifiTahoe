import XCTest

// Standalone test entry point — auto-discovers all XCTestCase subclasses
// via the Objective-C runtime, runs them, and exits with the failure count.
autoreleasepool {
    let suite = XCTestSuite.default()
    suite.run()
    let failures = suite.testRun?.failureCount ?? 0
    if failures > 0 {
        print("FAIL: \(failures) test(s) failed")
        exit(Int32(min(failures, 255)))
    }
    print("OK: all tests passed")
}
