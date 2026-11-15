import AppKit
import SwiftUI

struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var textColor: NSColor

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = ListCapableTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.font = font
        textView.textColor = textColor
        textView.allowsUndo = true
        textView.isRichText = false
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? ListCapableTextView else { return }
        
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            if selectedRange.location <= (text as NSString).length {
                textView.setSelectedRange(selectedRange)
            }
        }
        
        if textView.font != font {
            textView.font = font
        }
        if textView.textColor != textColor {
            textView.textColor = textColor
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextEditor

        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
    }
}

// Subclass handling Return / Newline for Smart Lists (- [ ], -, •, 1.)
final class ListCapableTextView: NSTextView {
    override func insertNewline(_ sender: Any?) {
        let currentString = self.string as NSString
        let selectedRange = self.selectedRange()
        let lineRange = currentString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let currentLine = currentString.substring(with: lineRange)
        
        // Strip trailing newline from currentLine
        let trimmedLine = currentLine.trimmingCharacters(in: .newlines)
        
        // Check for empty bullet/checklist/number to cancel list on double return
        let emptyChecklistPatterns = ["- [ ]", "- [x]", "- [X]", "*", "-", "•"]
        if emptyChecklistPatterns.contains(trimmedLine.trimmingCharacters(in: .whitespaces)) {
            // Remove the empty bullet
            let replaceRange = NSRange(location: lineRange.location, length: min(lineRange.length, (self.string as NSString).length - lineRange.location))
            if self.shouldChangeText(in: replaceRange, replacementString: "") {
                self.replaceCharacters(in: replaceRange, with: "")
                self.didChangeText()
            }
            return
        }

        // Smart continuation checks
        var nextPrefix: String? = nil

        // Checklist: - [ ] or - [x]
        if let match = trimmedLine.range(of: #"^(\s*)-\s\[([ xX])\]\s"#, options: .regularExpression) {
            let indent = String(trimmedLine[match].prefix(while: { $0.isWhitespace }))
            nextPrefix = "\(indent)- [ ] "
        }
        // Bullet: - or * or •
        else if let match = trimmedLine.range(of: #"^(\s*)([-*•])\s"#, options: .regularExpression) {
            let prefixStr = String(trimmedLine[match])
            nextPrefix = prefixStr
        }
        // Numbered list: 1. , 2. etc.
        else if let match = trimmedLine.range(of: #"^(\s*)(\d+)\.\s"#, options: .regularExpression) {
            let matchedText = String(trimmedLine[match])
            var indent = ""
            if let firstChar = matchedText.first, firstChar.isWhitespace {
                indent = String(matchedText.prefix(while: { $0.isWhitespace }))
            }
            let digits = matchedText.filter { $0.isNumber }
            if let currentNum = Int(digits) {
                nextPrefix = "\(indent)\(currentNum + 1). "
            }
        }

        if let prefix = nextPrefix {
            super.insertNewline(sender)
            self.insertText(prefix, replacementRange: self.selectedRange())
        } else {
            super.insertNewline(sender)
        }
    }
}
