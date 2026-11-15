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

        let textView = InteractiveChecklistTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
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
        guard let textView = nsView.documentView as? InteractiveChecklistTextView else { return }

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

// Subclass handling:
// 1. One-click toggle of interactive checkboxes (☐ ↔ ☑ or [ ] ↔ [x])
// 2. Return / Newline continuation for lists
final class InteractiveChecklistTextView: NSTextView {

    override func mouseDown(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        let charIndex = self.characterIndexForInsertion(at: point)
        let fullString = self.string as NSString

        if charIndex < fullString.length {
            let lineRange = fullString.lineRange(for: NSRange(location: charIndex, length: 0))
            let line = fullString.substring(with: lineRange)
            let clickOffsetInLine = charIndex - lineRange.location

            // 1. Check for unicode checkbox at click position: ☐ (U+2610) or ☑ (U+2611) / ☒
            if clickOffsetInLine <= 6 {
                if let match = line.range(of: #"^(\s*)([☐☑])\s"#, options: .regularExpression) {
                    let matchedText = String(line[match])
                    let isChecked = matchedText.contains("☑")
                    let newSymbol = isChecked ? "☐" : "☑"
                    let matchNSRange = (line as NSString).range(of: matchedText)
                    let replaceRange = NSRange(location: lineRange.location + matchNSRange.location, length: matchNSRange.length)
                    let newPrefix = matchedText.replacingOccurrences(of: isChecked ? "☑" : "☐", with: newSymbol)

                    if self.shouldChangeText(in: replaceRange, replacementString: newPrefix) {
                        self.replaceCharacters(in: replaceRange, with: newPrefix)
                        self.didChangeText()
                        return
                    }
                }
                // 2. Also support clicking markdown checkboxes [ ] ↔ [x]
                else if let match = line.range(of: #"^(\s*)-\s\[([ xX])\]\s"#, options: .regularExpression) {
                    let matchedText = String(line[match])
                    let isChecked = matchedText.contains("[x]") || matchedText.contains("[X]")
                    let newBox = isChecked ? "[ ]" : "[x]"
                    let matchNSRange = (line as NSString).range(of: matchedText)
                    let replaceRange = NSRange(location: lineRange.location + matchNSRange.location, length: matchNSRange.length)
                    let newPrefix = (matchedText as NSString).replacingOccurrences(of: isChecked ? "[x]" : "[ ]", with: newBox)

                    if self.shouldChangeText(in: replaceRange, replacementString: newPrefix) {
                        self.replaceCharacters(in: replaceRange, with: newPrefix)
                        self.didChangeText()
                        return
                    }
                }
            }
        }

        super.mouseDown(with: event)
    }

    override func insertNewline(_ sender: Any?) {
        let currentString = self.string as NSString
        let selectedRange = self.selectedRange()
        let lineRange = currentString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let currentLine = currentString.substring(with: lineRange)

        // Strip trailing newline
        let trimmedLine = currentLine.trimmingCharacters(in: .newlines)

        // Empty checklist/bullet patterns to cancel list on double return
        let emptyPatterns = ["☐", "☑", "- [ ]", "- [x]", "- [X]", "*", "-", "•"]
        if emptyPatterns.contains(trimmedLine.trimmingCharacters(in: .whitespaces)) {
            let replaceRange = NSRange(location: lineRange.location, length: min(lineRange.length, (self.string as NSString).length - lineRange.location))
            if self.shouldChangeText(in: replaceRange, replacementString: "") {
                self.replaceCharacters(in: replaceRange, with: "")
                self.didChangeText()
            }
            return
        }

        // Smart continuation checks
        var nextPrefix: String? = nil

        // Unicode checklist: ☐ or ☑
        if let match = trimmedLine.range(of: #"^(\s*)([☐☑])\s"#, options: .regularExpression) {
            let indent = String(trimmedLine[match].prefix(while: { $0.isWhitespace }))
            nextPrefix = "\(indent)☐ "
        }
        // Markdown Checklist: - [ ] or - [x]
        else if let match = trimmedLine.range(of: #"^(\s*)-\s\[([ xX])\]\s"#, options: .regularExpression) {
            let indent = String(trimmedLine[match].prefix(while: { $0.isWhitespace }))
            nextPrefix = "\(indent)- [ ] "
        }
        // Bullet: • or - or *
        else if let match = trimmedLine.range(of: #"^(\s*)([•\-*])\s"#, options: .regularExpression) {
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
