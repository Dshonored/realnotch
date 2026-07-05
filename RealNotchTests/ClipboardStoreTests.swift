import XCTest
@testable import RealNotch

final class ClipboardStoreTests: XCTestCase {
    private var tempDir: URL!
    private var store: ClipboardStore!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        UserDefaults.standard.removeObject(forKey: "maxItems")
        store = ClipboardStore(storageDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        UserDefaults.standard.removeObject(forKey: "maxItems")
        super.tearDown()
    }

    func testAddInsertsNewestFirst() {
        store.add(ClipboardItem(content: .text("first")))
        store.add(ClipboardItem(content: .text("second")))
        XCTAssertEqual(store.items.map(\.preview), ["second", "first"])
    }

    func testDuplicateContentMovesToTop() {
        store.add(ClipboardItem(content: .text("a")))
        store.add(ClipboardItem(content: .text("b")))
        store.add(ClipboardItem(content: .text("a")))
        XCTAssertEqual(store.items.map(\.preview), ["a", "b"])
        XCTAssertEqual(store.items.count, 2)
    }

    func testCapEvictsOldest() {
        store.maxItems = 10
        for i in 0..<15 {
            store.add(ClipboardItem(content: .text("item \(i)")))
        }
        XCTAssertEqual(store.items.count, 10)
        XCTAssertEqual(store.items.first?.preview, "item 14")
        XCTAssertEqual(store.items.last?.preview, "item 5")
    }

    func testStackToggleAndJoin() {
        let a = ClipboardItem(content: .text("hello"))
        let b = ClipboardItem(content: .text("world"))
        store.add(a)
        store.add(b)

        store.toggleStack(a)
        store.toggleStack(b)
        XCTAssertEqual(store.stack.count, 2)
        XCTAssertEqual(store.stackedText, "hello\nworld")

        store.toggleStack(a)
        XCTAssertEqual(store.stack.count, 1)
        XCTAssertFalse(store.isStacked(a))
    }

    func testPersistenceRoundTrip() {
        store.add(ClipboardItem(content: .text("persist me")))
        store.add(ClipboardItem(content: .fileURLs([URL(fileURLWithPath: "/tmp/x.txt")])))
        store.saveNow()

        let reloaded = ClipboardStore(storageDirectory: tempDir)
        XCTAssertEqual(reloaded.items.count, 2)
        XCTAssertEqual(reloaded.items.map(\.content), store.items.map(\.content))
    }

    func testDeleteRemovesFromHistoryAndStack() {
        let item = ClipboardItem(content: .text("bye"))
        store.add(item)
        store.toggleStack(item)
        store.delete(item)
        XCTAssertTrue(store.items.isEmpty)
        XCTAssertTrue(store.stack.isEmpty)
    }
}
