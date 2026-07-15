import Foundation

// MARK: - 数学表达式检测器

final class MathDetector: ContentDetecting {
    let identifier = "math"
    let priority = 9

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3, trimmed.count <= 60 else { return nil }
        guard trimmed.contains(where: { "+-*/^%×÷∗·".contains($0) }) else { return nil }
        guard trimmed.contains(where: { $0.isNumber }) else { return nil }

        let allowed = CharacterSet(charactersIn: "0123456789+-*/^%()., ")
        let disallowed = trimmed.unicodeScalars.filter { !allowed.contains($0) }
        let ratio = trimmed.unicodeScalars.count > 0 ? Double(disallowed.count) / Double(trimmed.unicodeScalars.count) : 0
        guard disallowed.count == 0 || ratio <= 0.15 else { return nil }

        let expr = trimmed
            .replacingOccurrences(of: "（", with: "(")
            .replacingOccurrences(of: "）", with: ")")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "∗", with: "*")
            .replacingOccurrences(of: "·", with: "*")
            .replacingOccurrences(of: "x", with: "*")
            .replacingOccurrences(of: "X", with: "*")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "^", with: "**")
            .replacingOccurrences(of: "％", with: "%")

        guard let result = evaluateMath(expr), result.isFinite, !result.isNaN else { return nil }
        return .mathExpression(text, result)
    }

    // MARK: Recursive Descent Parser

    private func evaluateMath(_ expression: String) -> Double? {
        let filtered = expression.unicodeScalars.filter {
            $0.isASCII && ($0.value >= 32 && $0.value < 127)
        }.map { String(Character($0)) }.joined()
        let expr = filtered.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "**", with: "^")
        guard expr.allSatisfy({ $0.isNumber || "+-*/%^().".contains($0) }) else { return nil }
        let tokens = tokenize(expr)
        guard !tokens.isEmpty else { return nil }
        var pos = 0
        guard let result = parseExpression(tokens, &pos), pos == tokens.count - 1 else { return nil }
        return result
    }

    private enum Token { case number(Double), plus, minus, multiply, divide, modulo, power, leftParen, rightParen, end }

    private func tokenize(_ expr: String) -> [Token] {
        var tokens: [Token] = []; var i = expr.startIndex
        while i < expr.endIndex {
            let c = expr[i]
            if c.isNumber || c == "." {
                var s = ""; var d = false
                while i < expr.endIndex {
                    let ch = expr[i]
                    if ch.isNumber { s.append(ch) } else if ch == ".", !d { s.append(ch); d = true } else { break }
                    i = expr.index(after: i)
                }
                if let v = Double(s) { tokens.append(.number(v)) }; continue
            }
            switch c {
            case "+": tokens.append(.plus); case "-": tokens.append(.minus)
            case "*": tokens.append(.multiply); case "/": tokens.append(.divide)
            case "%": tokens.append(.modulo); case "^": tokens.append(.power)
            case "(": tokens.append(.leftParen); case ")": tokens.append(.rightParen)
            default: return []
            }
            i = expr.index(after: i)
        }
        tokens.append(.end); return tokens
    }

    private func parseExpression(_ t: [Token], _ p: inout Int) -> Double? {
        guard let l = parseTerm(t, &p) else { return nil }; var r = l
        while p < t.count { switch t[p] { case .plus: p += 1; guard let v = parseTerm(t, &p) else { return nil }; r += v
            case .minus: p += 1; guard let v = parseTerm(t, &p) else { return nil }; r -= v; default: return r } }
        return r
    }

    private func parseTerm(_ t: [Token], _ p: inout Int) -> Double? {
        guard let l = parsePower(t, &p) else { return nil }; var r = l
        while p < t.count { switch t[p] {
            case .multiply: p += 1; guard let v = parsePower(t, &p) else { return nil }; r *= v
            case .divide: p += 1; guard let v = parsePower(t, &p), v != 0 else { return nil }; r /= v
            case .modulo: p += 1; guard let v = parsePower(t, &p), v != 0 else { return nil }; r = r.truncatingRemainder(dividingBy: v)
            default: return r } }
        return r
    }

    private func parsePower(_ t: [Token], _ p: inout Int) -> Double? {
        guard let l = parseUnary(t, &p) else { return nil }
        if p < t.count, case .power = t[p] { p += 1; guard let r = parseUnary(t, &p) else { return nil }; return pow(l, r) }
        return l
    }

    private func parseUnary(_ t: [Token], _ p: inout Int) -> Double? {
        if p < t.count { if case .plus = t[p] { p += 1; return parseAtom(t, &p) }
            if case .minus = t[p] { p += 1; guard let v = parseAtom(t, &p) else { return nil }; return -v } }
        return parseAtom(t, &p)
    }

    private func parseAtom(_ t: [Token], _ p: inout Int) -> Double? {
        guard p < t.count else { return nil }
        switch t[p] { case .number(let v): p += 1; return v
        case .leftParen: p += 1; guard let r = parseExpression(t, &p) else { return nil }
            guard p < t.count, case .rightParen = t[p] else { return nil }; p += 1; return r
        default: return nil }
    }
}
