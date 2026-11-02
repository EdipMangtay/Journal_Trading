import XCTest
import SwiftData
import AppKit
@testable import LiquidityEdge

final class PersistenceTests: XCTestCase {
    @MainActor func testFreshJournalStartsEmptyAndDemoDoesNotPopulateIt() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Fresh.store")
        let real = try JournalStore(demo: false, storageURL: url)
        XCTAssertFalse(real.isDemo)
        XCTAssertTrue(real.trades.isEmpty)
        XCTAssertTrue(real.setups.isEmpty)
        XCTAssertTrue(real.reviews.isEmpty)
        XCTAssertEqual(try real.context.fetchCount(FetchDescriptor<TradeScreenshot>()), 0)
        let demo = try JournalStore(demo: true)
        XCTAssertEqual(demo.trades.count, 28)
        let reopened = try JournalStore(demo: false, storageURL: url)
        XCTAssertTrue(reopened.trades.isEmpty)
        XCTAssertTrue(reopened.setups.isEmpty)
        XCTAssertTrue(reopened.reviews.isEmpty)
    }
    @MainActor func testCRUDReopenAttachmentsAndRestore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Test.store")
        var trade = TradeRecord(); trade.grossPnL = 505; trade.fees = 5; trade.rMultiple = 2
        let image = NSImage(size: NSSize(width: 20, height: 20)); image.lockFocus(); NSColor.green.setFill(); NSRect(x: 0, y: 0, width: 20, height: 20).fill(); image.unlockFocus()
        let png = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
        let shot = ScreenshotDraft(name: "proof.png", category: "Entry", imageData: png, thumbnailData: png, annotations: [ImageAnnotation(kind: "Arrow", x: 0.1, y: 0.2, endX: 0.8, endY: 0.7)])
        var backup: JournalBackup!
        do {
            let store = try JournalStore(demo: false, storageURL: url)
            try store.save(trade, screenshots: [shot]); XCTAssertEqual(store.trades.count, 1)
            trade.notes.lesson = "Wait for displacement"; trade.tags = ["M1", "Sweep"]; try store.save(trade, screenshots: [shot])
            XCTAssertEqual(store.trades.first?.notes.lesson, trade.notes.lesson)
            XCTAssertEqual(store.model(trade.id)?.screenshots.count, 1)
            backup = try BackupService.decode(BackupService.encode(BackupService.archive(store)))
        }
        let reopened = try JournalStore(demo: false, storageURL: url)
        XCTAssertEqual(reopened.trades.first?.netPnL, 500)
        XCTAssertEqual(reopened.model(trade.id)?.screenshots.first?.imageData, png)
        XCTAssertEqual(reopened.model(trade.id)?.tags.count, 2)
        try reopened.deleteTrade(trade.id)
        XCTAssertEqual(reopened.trades.count, 0)
        XCTAssertEqual(try reopened.context.fetchCount(FetchDescriptor<TradeScreenshot>()), 0)
        try BackupService.restore(backup, into: reopened)
        XCTAssertEqual(reopened.trades.count, 1)
        XCTAssertEqual(try ScreenshotDraft(reopened.model(trade.id)!.screenshots.first!).annotations.count, 1)
        try BackupService.restore(backup, into: reopened)
        XCTAssertEqual(reopened.trades.count, 1); XCTAssertEqual(reopened.model(trade.id)?.screenshots.count, 1)
    }
    @MainActor func testValidationFailureDoesNotMutateAndDemoIsSeparate() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let real = try JournalStore(demo: false, storageURL: directory.appendingPathComponent("Real.store"))
        let demo = try JournalStore(demo: true)
        XCTAssertEqual(demo.trades.count, 28); XCTAssertTrue(real.trades.isEmpty)
        var bad = TradeRecord(); bad.fees = -1
        XCTAssertThrowsError(try real.save(bad, screenshots: [])); XCTAssertTrue(real.trades.isEmpty)
        var backup = try BackupService.archive(demo); backup.trades[0].instrument = ""
        XCTAssertThrowsError(try BackupService.restore(backup, into: real)); XCTAssertTrue(real.trades.isEmpty)
    }
    @MainActor func testThousandTradesPersistAndRefresh() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try JournalStore(demo: false, storageURL: directory.appendingPathComponent("Scale.store"))
        try store.commit { for i in 0..<1000 { var t = TradeRecord(); t.date = Date(timeIntervalSince1970: Double(i) * 3600); t.grossPnL = i % 2 == 0 ? 200 : -100; t.rMultiple = i % 2 == 0 ? 2 : -1; try store.upsert(t) } }
        XCTAssertEqual(store.trades.count, 1000); XCTAssertEqual(AnalyticsEngine.performance(store.trades).totalR, 500)
        let count = try store.context.fetchCount(FetchDescriptor<Trade>()); XCTAssertEqual(count, 1000)
    }
    @MainActor func testFullBackupRelationshipsAndAtomicValidation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = try JournalStore(demo: true)
        try source.commit {
            let review = Review(period: "Weekly", date: Date()); review.adjustment = "Wait for TSMO"; source.context.insert(review)
            source.context.insert(CustomRule(name: "Respect true open"))
            source.context.insert(Instrument(symbol: "YM"))
        }
        let encoded = try BackupService.encode(BackupService.archive(source))
        let backup = try BackupService.decode(encoded)
        let target = try JournalStore(demo: false, storageURL: directory.appendingPathComponent("Restore.store"))
        try BackupService.restore(backup, into: target)
        XCTAssertEqual(target.trades.count, 28)
        XCTAssertEqual(target.setups.count, 4)
        XCTAssertEqual(target.reviews.first?.adjustment, "Wait for TSMO")
        XCTAssertEqual(target.customRules.first?.name, "Respect true open")
        XCTAssertTrue(target.instruments.contains { $0.symbol == "YM" })
        XCTAssertTrue(target.setups.allSatisfy { $0.playbook?.entryRules.isEmpty == false && !$0.trades.isEmpty })
        XCTAssertEqual(target.trades.first?.date, source.trades.first?.date)
        let invalidTrade = target.trades.first { !$0.compliant }!
        XCTAssertEqual(target.model(invalidTrade.id)?.violations.count, invalidTrade.brokenRules.count)
        try target.deleteTrade(invalidTrade.id)
        XCTAssertFalse(try target.context.fetch(FetchDescriptor<RuleViolation>()).contains { $0.trade?.id == invalidTrade.id })
        var invalid = backup; invalid.version = 999
        XCTAssertThrowsError(try BackupService.restore(invalid, into: target))
        XCTAssertEqual(target.trades.count, 27)
        try BackupService.restore(backup, into: target)
        XCTAssertEqual(target.trades.count, 28)
        let setup = target.setups[0]
        let affected = Set(target.trades.filter { $0.setupID == setup.id }.map(\.id))
        try target.deleteSetup(setup)
        XCTAssertTrue(target.trades.filter { affected.contains($0.id) }.allSatisfy { $0.setupID == nil && $0.setupName == "Unassigned" })
    }
    @MainActor func testScreenshotImportValidatesFileAndBuildsThumbnail() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let invalid = directory.appendingPathComponent("invalid.png")
        try Data("not an image".utf8).write(to: invalid)
        XCTAssertThrowsError(try ScreenshotService.load(invalid, category: "Entry"))
        let image = NSImage(size: NSSize(width: 100, height: 50)); image.lockFocus(); NSColor.blue.setFill(); NSRect(x: 0, y: 0, width: 100, height: 50).fill(); image.unlockFocus()
        let valid = directory.appendingPathComponent("chart.png")
        try NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: valid)
        let imported = try ScreenshotService.load(valid, category: "HTF")
        XCTAssertEqual(imported.category, "HTF"); XCTAssertEqual(imported.name, "chart.png")
        XCTAssertNotNil(NSImage(data: imported.thumbnailData))
    }
    @MainActor func testLocalRecoverySnapshotsAreAdditiveAndProtectDeletion() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Durable.store")
        let store = try JournalStore(demo: false, storageURL: url)
        XCTAssertEqual(store.storageURL, url)
        var trade = TradeRecord(); trade.notes.lesson = "Original entry"
        try store.save(trade, screenshots: [])
        let backups = try XCTUnwrap(store.backupDirectoryURL)
        let initialFiles = try FileManager.default.contentsOfDirectory(at: backups, includingPropertiesForKeys: nil)
        XCTAssertEqual(initialFiles.count, 1)
        XCTAssertNotNil(store.lastBackupDate)
        trade.notes.lesson = "Latest saved edit"
        try store.save(trade, screenshots: [])
        // Routine edits do not re-encode screenshots into another complete archive.
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(at: backups, includingPropertiesForKeys: nil).count, 1)
        try store.deleteTrade(trade.id)
        let files = try FileManager.default.contentsOfDirectory(at: backups, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 2)
        XCTAssertTrue(files.contains(initialFiles[0]))
        let recovery = try XCTUnwrap(files.first { $0.lastPathComponent.contains("before-delete-trade") })
        let archive = try BackupService.decode(Data(contentsOf: recovery))
        XCTAssertEqual(archive.trades.first?.notes.lesson, "Latest saved edit")
        let reopened = try JournalStore(demo: false, storageURL: url)
        XCTAssertTrue(reopened.trades.isEmpty)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(at: backups, includingPropertiesForKeys: nil).count, 2)
        XCTAssertNil(try JournalStore(demo: true).createRecoverySnapshot())
    }
    @MainActor func testPreferencesBelongToTheLocalStoreAndSurviveReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Preferences.store")
        let store = try JournalStore(demo: false, storageURL: url)
        store.preferences.accountSize = 123_456
        store.preferences.currency = "EUR"
        store.preferences.theme = "Light"
        try store.savePreferences()
        let reopened = try JournalStore(demo: false, storageURL: url)
        XCTAssertEqual(reopened.preferences.accountSize, 123_456)
        XCTAssertEqual(reopened.preferences.currency, "EUR")
        XCTAssertEqual(reopened.preferences.theme, "Light")
        let isolated = try JournalStore(demo: false, storageURL: directory.appendingPathComponent("Other.store"))
        XCTAssertNotEqual(isolated.preferences.accountSize, 123_456)
    }
    @MainActor func testUndecodableMutationRollsBackBeforeDiskCommit() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Rollback.store")
        let store = try JournalStore(demo: false, storageURL: url)
        var trade = TradeRecord(); trade.notes.lesson = "Keep this saved entry"
        try store.save(trade, screenshots: [])
        XCTAssertThrowsError(try store.commit { store.model(trade.id)?.recordData = Data("invalid-json".utf8) })
        XCTAssertEqual(store.trades.first?.notes.lesson, "Keep this saved entry")
        let reopened = try JournalStore(demo: false, storageURL: url)
        XCTAssertEqual(reopened.trades.first?.notes.lesson, "Keep this saved entry")
    }
    @MainActor func testRestorePreservesAnImmutableCopyOfReplacedRecords() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try JournalStore(demo: false, storageURL: directory.appendingPathComponent("RestoreSafety.store"))
        var trade = TradeRecord(); trade.notes.lesson = "Before import"
        try store.save(trade, screenshots: [])
        var archive = try BackupService.archive(store)
        archive.trades[0].notes.lesson = "Imported edit"
        archive.preferences.currency = "EUR"
        try BackupService.restore(archive, into: store)
        XCTAssertEqual(store.trades.first?.notes.lesson, "Imported edit")
        XCTAssertEqual(store.preferences.currency, "EUR")
        let files = try FileManager.default.contentsOfDirectory(at: XCTUnwrap(store.backupDirectoryURL), includingPropertiesForKeys: nil)
        let preserved = try XCTUnwrap(files.first { $0.lastPathComponent.contains("before-restore") })
        XCTAssertEqual(try BackupService.decode(Data(contentsOf: preserved)).trades.first?.notes.lesson, "Before import")
    }

}
