import Foundation
import XCTest
import WordPress
import Aztec


// MARK: - CalypsoHTMLSerializerTests
//
class CalypsoHTMLSerializerTests: XCTestCase {

    let serializer = CalypsoHTMLSerializer()


    /// Verifies that a single paragraph does not get double newline at it's bottom.
    ///
    func testSingleParagraphDoesNotGetDoubleNewlineAtItsEnd() {
        let text = TextNode(text: "payload")
        let paragraph = ElementNode(type: .p, children: [text])
        let root = RootNode(children: [paragraph])

        let outputHTML = serializer.serialize(root)
        let expectedHTML = "payload"

        XCTAssertEqual(outputHTML, expectedHTML)
    }

    /// Verifies that two paragraphs get sepparated by a double newline.
    ///
    func testParagraphsGetSepparatedByDoubleNewlines() {
        let text = TextNode(text: "payload")
        let paragraph = ElementNode(type: .p, children: [text])
        let root = RootNode(children: [paragraph, paragraph])

        let outputHTML = serializer.serialize(root)
        let expectedHTML = "payload\n\npayload"

        XCTAssertEqual(outputHTML, expectedHTML)
    }

    /// Verifies that a line break is mapped into a single newline.
    ///
    func testLineBreaksGetTranslatedIntoSingleNewline() {
        let text = TextNode(text: "payload")
        let br = ElementNode(type: .br)

        let paragraph = ElementNode(type: .p, children: [text, br, text])
        let root = RootNode(children: [paragraph])

        let outputHTML = serializer.serialize(root)
        let expectedHTML = "payload\npayload"

        XCTAssertEqual(outputHTML, expectedHTML)
    }
}
