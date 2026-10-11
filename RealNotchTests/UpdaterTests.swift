import XCTest
@testable import RealNotch

final class UpdaterTests: XCTestCase {
    func testPrefixedNewerPatchIsNewer() {
        XCTAssertTrue(Updater.isNewer("v0.8.2", than: "0.8.1"))
    }

    func testEqualVersionsAreNotNewer() {
        XCTAssertFalse(Updater.isNewer("0.8.1", than: "0.8.1"))
        XCTAssertFalse(Updater.isNewer("v0.8.1", than: "0.8.1"))
        XCTAssertFalse(Updater.isNewer("1.0", than: "1.0.0"))
    }

    func testComponentsCompareNumericallyNotLexically() {
        XCTAssertTrue(Updater.isNewer("0.10.0", than: "0.9.9"))
        XCTAssertFalse(Updater.isNewer("0.9.9", than: "0.10.0"))
    }

    func testMissingComponentsCountAsZero() {
        XCTAssertTrue(Updater.isNewer("1.0", than: "0.99.99"))
        XCTAssertFalse(Updater.isNewer("0.8.1", than: "0.8.1.1"))
        XCTAssertTrue(Updater.isNewer("0.8.1.1", than: "0.8.1"))
    }

    func testPreReleaseSuffixIsIgnored() {
        XCTAssertTrue(Updater.isNewer("v1.0.0-beta", than: "0.9.0"))
        XCTAssertFalse(Updater.isNewer("1.0.0-beta", than: "1.0.0"))
    }

    func testGarbageDoesNotCrash() {
        let junk = ["", "v", "vv", "abc", "1..2", ".", "-", "+", "1.x.3", "99999999999999999999999.0",
                    "-1.0", "🙂", " v2.0 "]
        for a in junk {
            for b in junk {
                _ = Updater.isNewer(a, than: b)
            }
        }
        XCTAssertFalse(Updater.isNewer("abc", than: "0"))
        XCTAssertTrue(Updater.isNewer(" v2.0 ", than: "1.x.3"))
    }

    func testDecodesGitHubLatestRelease() throws {
        let json = #"""
        {
          "url": "https://api.github.com/repos/Dshonored/realnotch/releases/349663167",
          "html_url": "https://github.com/Dshonored/realnotch/releases/tag/v0.8.1",
          "id": 349663167,
          "tag_name": "v0.8.1",
          "name": "RealNotch 0.8.1",
          "draft": false,
          "prerelease": false,
          "body": "- Fixed things",
          "author": { "login": "Dshonored" },
          "assets": [
            {
              "name": "RealNotch-0.8.1.dmg",
              "size": 1234567,
              "content_type": "application/x-apple-diskimage",
              "browser_download_url": "https://github.com/Dshonored/realnotch/releases/download/v0.8.1/RealNotch-0.8.1.dmg"
            }
          ]
        }
        """#
        let release = try Updater.decodeRelease(Data(json.utf8))
        XCTAssertEqual(release.tagName, "v0.8.1")
        XCTAssertEqual(release.version, "0.8.1")
        XCTAssertEqual(release.name, "RealNotch 0.8.1")
        XCTAssertEqual(release.body, "- Fixed things")
        XCTAssertFalse(release.draft)
        XCTAssertFalse(release.prerelease)
        XCTAssertEqual(release.htmlURL.absoluteString,
                       "https://github.com/Dshonored/realnotch/releases/tag/v0.8.1")
        XCTAssertEqual(release.dmgAsset?.name, "RealNotch-0.8.1.dmg")
        XCTAssertEqual(release.dmgAsset?.browserDownloadURL.lastPathComponent, "RealNotch-0.8.1.dmg")
    }

    func testDecodesNullNameAndBody() throws {
        let json = #"""
        {"tag_name":"v1.0.0","name":null,"body":null,"html_url":"https://example.com/r",
         "draft":true,"prerelease":false,"assets":[]}
        """#
        let release = try Updater.decodeRelease(Data(json.utf8))
        XCTAssertNil(release.name)
        XCTAssertNil(release.body)
        XCTAssertTrue(release.draft)
        XCTAssertNil(release.dmgAsset)
    }
}
