
import Aztec
import Foundation

/// This class takes care of processing HTML as provided by the WP.com and converting it into 100% standard HTML.
/// WP.com HTML coming from Calypso and the older editor is stored with regular newlines (\n and \r\n) instead of
/// using HTML paragraphs and BR nodes.
///
class ParagraphRestoringProcessor: HTMLTreeProcessor {
    func process(_ rootNode: RootNode) {
        processNewlines(in: rootNode)
    }
}

extension ParagraphRestoringProcessor {
    
    func processNewlines(in rootNode: RootNode) {
        processNewlines(in: rootNode, restoreParagraphs: true)
    }
    
    private func processNewlines(in element: ElementNode, restoreParagraphs: Bool) {
        
        var processedNodes = [Node]()
        var textToProcess = ""
        var firstChildProcessed = false
        
        for child in element.children {
            if let textNode = child as? TextNode {
                textToProcess = textToProcess + textNode.text()
                continue
            }
            
            if let nodes = processNewlines(in: textToProcess,
                                           restoreParagraphs: restoreParagraphs,
                                           removeOpeningNewlines: !firstChildProcessed) {
                processedNodes.append(contentsOf: nodes)
                textToProcess = ""
            }
            
            if let element = child as? ElementNode {
                processNewlines(in: element, restoreParagraphs: false)
            }
            
            processedNodes.append(child)
            firstChildProcessed = true
        }
        
        if let nodes = processNewlines(in: textToProcess,
                                       restoreParagraphs: restoreParagraphs,
                                       removeOpeningNewlines: !firstChildProcessed) {
            processedNodes.append(contentsOf: nodes)
            textToProcess = ""
        }
        
        element.children = processedNodes
    }
    
    /// Processes newlines in consecutive text nodes.
    ///
    /// - Parameters:
    ///     - text: the text to process.
    ///     - restoreParagraphs: whether we're going to replace \n\n with paragraphs.  Would be true for text nodes
    ///             at root-level.
    ///     - removeOpeningNewlines: set to true if we should ignore the first character when its a newline.  This is
    ///             the case when the newline would be a prettifying newline.
    ///
    /// - Returns: true if any text was processed.
    ///
    private func processNewlines(in text: String, restoreParagraphs: Bool, removeOpeningNewlines: Bool) -> [Node]? {
        guard text.characters.count > 0 else {
            return nil
        }
        
        return nodes(for: text, restoreParagraphs: restoreParagraphs, removeOpeningNewline: removeOpeningNewlines)
    }
}

extension ParagraphRestoringProcessor {
    func nodes(for text: String, restoreParagraphs: Bool, removeOpeningNewline: Bool) -> [Node] {
        let cleanText = text.replacingOccurrences(of: "\r\n", with: "\n")
        let finalText: String
        
        if removeOpeningNewline && text.characters.count > 0 && text.substring(to: text.index(after: text.startIndex)) == "\n" {
            finalText = cleanText.substring(from: text.index(after: text.startIndex))
        } else {
            finalText = cleanText
        }
        
        if restoreParagraphs {
            return nodesRestoringBreaksAndParagraphs(for: finalText)
        } else {
            return nodesRestoringBreaks(for: finalText)
        }
    }

    private func nodesRestoringBreaksAndParagraphs(for text: String) -> [Node] {
        var nodes = [Node]()
        let paragraphs = text.components(separatedBy: "\n\n")
        
        for (index, paragraph) in paragraphs.enumerated() {
            let children = nodesRestoringBreaks(for: paragraph)
            
            // The last paragraph is not really a paragraph because it's not closed by \n\n.  In fact if it was
            // it would not be the last paragraph in the array. :)
            //
            guard index < paragraphs.count - 1 else {
                nodes.append(contentsOf: children)
                continue
            }
            
            let paragraph = ElementNode(type: .p, attributes: [], children: children)
            nodes.append(paragraph)
        }
        
        return nodes
    }
    
    private func nodesRestoringBreaks(for text: String) -> [Node] {
        var nodes = [Node]()
        let lines = text.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            if index > 0 {
                nodes.append(ElementNode(type: .br))
            }
            
            if line.characters.count > 0 {
                let textNode = TextNode(text: line)
                nodes.append(textNode)
            }
        }
        
        return nodes
    }
 }
