
import Aztec
import Foundation

class ParagraphRestoringProcessor: HTMLTreeProcessor {
    func process(_ rootNode: RootNode) -> RootNode {
        removeNewlinesFromChildren(of: rootNode)
        
        return rootNode
    }
}

extension ParagraphRestoringProcessor {
    
    func removeNewlinesFromChildren(of rootNode: RootNode) {
        removeNewlinesFromChildren(of: rootNode, restoreParagraphs: true)
    }
    
    // Recursive
    private func removeNewlinesFromChildren(of element: ElementNode, restoreParagraphs: Bool) {
        
        var processedNodes = [Node]()
        var textToProcess = ""
        var firstChildProcessed = false
        
        for child in element.children {
            guard let textNode = child as? TextNode else {
                if textToProcess.characters.count > 0 {
                    let nodes = self.nodes(for: textToProcess, restoreParagraphs: restoreParagraphs, removeOpeningNewline: !firstChildProcessed)
                    
                    processedNodes.append(contentsOf: nodes)
                    textToProcess = ""
                }
                
                if let element = child as? ElementNode {
                    removeNewlinesFromChildren(of: element, restoreParagraphs: false)
                }
                
                processedNodes.append(child)
                firstChildProcessed = true
                continue
            }
            
            textToProcess = textToProcess + textNode.text()
        }
        
        if textToProcess.characters.count > 0 {
            let nodes = self.nodes(for: textToProcess, restoreParagraphs: restoreParagraphs, removeOpeningNewline: !firstChildProcessed)
            
            processedNodes.append(contentsOf: nodes)
            textToProcess = ""
        }
        
        element.children = processedNodes
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
