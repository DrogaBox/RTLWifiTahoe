import Foundation

// MARK: - Assertion failures

struct AssertionFailure: Error, CustomStringConvertible {
    let message: String
    let file: StaticString
    let line: UInt

    var description: String { message }
}

// MARK: - Assertions (mirror XCTest signatures)

func XCTAssertEqual<T: Equatable>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let e1 = try expression1()
    let e2 = try expression2()
    guard e1 == e2 else {
        let suffix = message().isEmpty ? "" : " — \(message())"
        throw AssertionFailure(
            message: "XCTAssertEqual failed: \"\(e1)\" is not equal to \"\(e2)\"\(suffix)",
            file: file, line: line
        )
    }
}

func XCTAssertEqual<T: Equatable>(
    _ expression1: @autoclosure () throws -> T?,
    _ expression2: @autoclosure () throws -> T?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let e1 = try expression1()
    let e2 = try expression2()
    guard e1 == e2 else {
        let suffix = message().isEmpty ? "" : " — \(message())"
        throw AssertionFailure(
            message: "XCTAssertEqual failed: \"\(String(describing: e1))\" is not equal to \"\(String(describing: e2))\"\(suffix)",
            file: file, line: line
        )
    }
}

func XCTAssertTrue(
    _ expression: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let e = try expression()
    guard e else {
        let suffix = message().isEmpty ? "" : " — \(message())"
        throw AssertionFailure(
            message: "XCTAssertTrue failed\(suffix)",
            file: file, line: line
        )
    }
}

func XCTAssertFalse(
    _ expression: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let e = try expression()
    guard !e else {
        let suffix = message().isEmpty ? "" : " — \(message())"
        throw AssertionFailure(
            message: "XCTAssertFalse failed\(suffix)",
            file: file, line: line
        )
    }
}

func XCTAssertNil(
    _ expression: @autoclosure () throws -> Any?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let e = try expression()
    guard e == nil else {
        let suffix = message().isEmpty ? "" : " — \(message())"
        throw AssertionFailure(
            message: "XCTAssertNil failed: value is \(String(describing: e))\(suffix)",
            file: file, line: line
        )
    }
}

func XCTAssertNotNil(
    _ expression: @autoclosure () throws -> Any?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let e = try expression()
    guard e != nil else {
        let suffix = message().isEmpty ? "" : " — \(message())"
        throw AssertionFailure(
            message: "XCTAssertNotNil failed: value is nil\(suffix)",
            file: file, line: line
        )
    }
}

func XCTAssertNotEqual<T: Equatable>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let e1 = try expression1()
    let e2 = try expression2()
    guard e1 != e2 else {
        let suffix = message().isEmpty ? "" : " — \(message())"
        throw AssertionFailure(
            message: "XCTAssertNotEqual failed: \"\(e1)\" is equal to \"\(e2)\"\(suffix)",
            file: file, line: line
        )
    }
}

func XCTAssertGreaterThan<T: Comparable>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) throws {
    let e1 = try expression1()
    let e2 = try expression2()
    guard e1 > e2 else {
        let suffix = message().isEmpty ? "" : " — \(message())"
        throw AssertionFailure(
            message: "XCTAssertGreaterThan failed: \"\(e1)\" is not greater than \"\(e2)\"\(suffix)",
            file: file, line: line
        )
    }
}

// MARK: - Timeout helper

/// Run an async operation with a timeout. If the operation doesn't complete
/// within `seconds`, it is cancelled and `withTestTimeout` throws an error.
///
/// Use in tests that may call real Keychain/IOKit operations to prevent
/// indefinite hangs when running as an unsigned binary.
///
/// ```swift
/// let value = try await withTestTimeout(seconds: 3) {
///     await someSlowThing()
/// }
/// ```
func withTestTimeout<T: Sendable>(
    seconds: TimeInterval = 5,
    operation: @escaping () async throws -> T
) async throws -> T {
    let task = Task {
        try await operation()
    }
    let timeoutTask = Task {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        task.cancel()
    }
    do {
        let result = try await task.value
        timeoutTask.cancel()
        return result
    } catch is CancellationError {
        timeoutTask.cancel()
        throw AssertionFailure(
            message: "withTestTimeout(seconds: \(seconds)) timed out",
            file: #file, line: #line
        )
    } catch {
        timeoutTask.cancel()
        throw error
    }
}

// MARK: - Test runner

/// Convenience type-erased test function.
typealias TestFn = () async throws -> Void

@main
enum TestRunner {
    @MainActor
    static func main() async {
        // Disable system notifications during tests — UNUserNotificationCenter.current()
        // asserts that the process has a valid bundle/entitlements, which a standalone
        // test executable does not.
        UserDefaults.standard.set(false, forKey: "show_notifications")

        let tests = WiFiModelTests()
        let certTests = EnterpriseCertStoreTests()
        let all = tests.allTests() + certTests.allTests()
        var passed = 0
        var failures: [(name: String, error: Error)] = []

        print("Running \(all.count) test(s)…\n")

        for (name, fn) in all {
            print("  \(name)… ", terminator: "")
            fflush(stdout)
            do {
                try await withTestTimeout(seconds: 10) {
                    try await fn()
                }
                passed += 1
                print("✓")
            } catch {
                failures.append((name, error))
                print("✗  \(error)")
            }
        }

        let total = passed + failures.count
        print("\n—————————————————")
        print("\(total) tests — \(passed) passed, \(failures.count) failed")

        if !failures.isEmpty {
            print("\nFailures:")
            for (name, error) in failures {
                print("  ✗ \(name): \(error)")
            }
            exit(1)
        }
    }
}
