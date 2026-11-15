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

        // macOS 15+ Native Apple Intelligence Writing Tools Integration
        if #available(macOS 15.0, *) {
            textView.writingToolsBehavior = .complete
            textView.allowedWritingToolsResultOptions = [.plainText]
        }

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
// 1. Precise checkbox toggle ONLY when clicking on the exact checkbox glyph
// 2. Full cursor placement and editing when clicking on text or empty spaces
// 3. Return / Newline continuation for lists
final class InteractiveChecklistTextView: NSTextView {

    override func mouseDown(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        let fullString = self.string as NSString

        if fullString.length > 0 {
            // Get character index where clicked
            var fraction: CGFloat = 0
            let charIndex = self.layoutManager?.characterIndex(for: point, in: self.textContainer!, fractionOfDistanceBetweenInsertionPoints: &fraction) ?? NSNotFound

            if charIndex != NSNotFound && charIndex < fullString.length {
                let lineRange = fullString.lineRange(for: NSRange(location: charIndex, length: 0))
                let line = fullString.substring(with: lineRange)
                let charInLineIndex = charIndex - lineRange.location

                // 1. Check if line starts with Unicode checkbox: ☐ or ☑
                if let match = line.range(of: #"^(\s*)([☐☑])"#, options: .regularExpression) {
                    let matchedText = String(line[match])
                    // The symbol index in the line
                    let symbolIndex = (line as NSString).range(of: matchedText).location + (line as NSString).range(of: matchedText).length - 1

                    // ONLY toggle if the click is directly on the checkbox character itself!
                    if charInLineIndex == symbolIndex {
                        let isChecked = matchedText.contains("☑")
                        let newSymbol = isChecked ? "☐" : "☑"
                        let replaceRange = NSRange(location: lineRange.location + symbolIndex, length: 1)

                        if self.shouldChangeText(in: replaceRange, replacementString: newSymbol) {
                            self.replaceCharacters(in: replaceRange, with: newSymbol)
                            self.didChangeText()
                            return
                        }
                    }
                }
                // 2. Check if line starts with Markdown checkbox: - [ ] or - [x]
                else if let match = line.range(of: #"^(\s*)-\s\[([ xX])\]"#, options: .regularExpression) {
                    let matchedText = String(line[match])
                    let matchNSRange = (line as NSString).range(of: matchedText)

                    // ONLY toggle if click is inside the bracket bounds
                    if charInLineIndex >= matchNSRange.location && charInLineIndex <= matchNSRange.location + matchNSRange.length {
                        let isChecked = matchedText.contains("[x]") || matchedText.contains("[X]")
                        let newBox = isChecked ? "[ ]" : "[x]"
                        let replaceRange = NSRange(location: lineRange.location + matchNSRange.location + matchNSRange.length - 3, length: 3)

                        if self.shouldChangeText(in: replaceRange, replacementString: newBox) {
                            self.replaceCharacters(in: replaceRange, with: newBox)
                            self.didChangeText()
                            return
                        }
                    }
                }
            }
        }

        // Standard text cursor placement, selection, and editing
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
