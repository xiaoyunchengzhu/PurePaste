import Foundation

// MARK: - 文本类检测器（地址 / 快递 / 日期 / JSON / 经纬度 / 富文本）

final class TrackingDetector: ContentDetecting {
    let identifier = "tracking"; let priority = 7

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let cleaned = text.trimmingCharacters(in: .whitespaces)
        let carriers: [(String, String)] = [
            ("SF","顺丰速运"),("YT","圆通速递"),("YTO","圆通速递"),("ZTO","中通快递"),
            ("STO","申通快递"),("JD","京东物流"),("DB","德邦快递"),("EMS","中国邮政"),
        ]
        for (prefix, name) in carriers {
            guard cleaned.hasPrefix(prefix) else { continue }
            let nums = String(cleaned.dropFirst(prefix.count))
            if prefix == "SF", nums.count == 12, nums.allSatisfy({ $0.isNumber }) { return .tracking(cleaned, name) }
            if nums.count >= 10, nums.allSatisfy({ $0.isNumber }) { return .tracking(cleaned, name) }
        }
        return nil
    }
}

final class DatetimeDetector: ContentDetecting {
    let identifier = "datetime"; let priority = 11
    private let formatters: [DateFormatter] = {
        ["yyyy-MM-dd HH:mm:ss","yyyy-MM-dd HH:mm","yyyy/MM/dd HH:mm","yyyy-MM-dd","yyyy/MM/dd",
         "yyyy年M月d日 HH:mm","yyyy年M月d日","M月d日 HH:mm","MM-dd HH:mm","HH:mm"].map {
            let f = DateFormatter(); f.dateFormat = $0; f.locale = Locale(identifier: "zh_CN"); return f
        }
    }()

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        for f in formatters { if let d = f.date(from: text) { return .datetime(d, text) } }
        return nil
    }
}

final class JSONDetector: ContentDetecting {
    let identifier = "json"; let priority = 6

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 2, t.count <= 10000, (t.hasPrefix("{") || t.hasPrefix("[")),
              (t.hasSuffix("}") || t.hasSuffix("]")),
              let data = t.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil
        else { return nil }
        return .jsonContent(t)
    }
}

final class GeoDetector: ContentDetecting {
    let identifier = "geo"; let priority = 10

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let t = text.trimmingCharacters(in: .whitespaces)

        // decimal pair "39.9, 116.4"
        let cp = t.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if cp.count == 2, let a = Double(cp[0]), let b = Double(cp[1]) {
            if abs(a) <= 90, abs(b) <= 180 { return .geoCoordinate(a, b) }
            if abs(b) <= 90, abs(a) <= 180 { return .geoCoordinate(b, a) }
        }
        let sp = t.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if sp.count == 2, let a = Double(sp[0]), let b = Double(sp[1]) {
            if abs(a) <= 90, abs(b) <= 180 { return .geoCoordinate(a, b) }
            if abs(b) <= 90, abs(a) <= 180 { return .geoCoordinate(b, a) }
        }
        // degree with direction
        let dp = "([0-9.]+)\\s*°?\\s*([NnSs]),?\\s*([0-9.]+)\\s*°?\\s*([EeWw])"
        if let r = try? NSRegularExpression(pattern: dp),
           let m = r.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)), m.numberOfRanges == 5 {
            let latS = String(t[Range(m.range(at: 1), in: t)!])
            let latD = String(t[Range(m.range(at: 2), in: t)!]).uppercased()
            let lngS = String(t[Range(m.range(at: 3), in: t)!])
            let lngD = String(t[Range(m.range(at: 4), in: t)!]).uppercased()
            if var lat = Double(latS), var lng = Double(lngS) {
                if latD == "S" { lat = -lat }; if lngD == "W" { lng = -lng }
                if abs(lat) <= 90, abs(lng) <= 180 { return .geoCoordinate(lat, lng) }
            }
        }
        // DMS
        let n = "([0-9.]+)"
        let dms = "\(n)°\\s*\(n)'\\s*\(n)\"?\\s*([NnSs])\\s*,?\\s*\(n)°\\s*\(n)'\\s*\(n)\"?\\s*([EeWw])"
        if let r = try? NSRegularExpression(pattern: dms),
           let m = r.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)), m.numberOfRanges == 9 {
            let ex: [Double] = (1...6).compactMap { i in Double(String(t[Range(m.range(at: i), in: t)!])) }
            if ex.count == 6 {
                let ld = String(t[Range(m.range(at: 7), in: t)!]).uppercased()
                let gd = String(t[Range(m.range(at: 8), in: t)!]).uppercased()
                var lat = ex[0] + ex[1]/60 + ex[2]/3600
                var lng = ex[3] + ex[4]/60 + ex[5]/3600
                if ld == "S" { lat = -lat }; if gd == "W" { lng = -lng }
                if abs(lat) <= 90, abs(lng) <= 180 { return .geoCoordinate(lat, lng) }
            }
        }
        return nil
    }
}

final class AddressDetector: ContentDetecting {
    let identifier = "address"; let priority = 12
    private let provinces = ["北京","天津","上海","重庆","河北","山西","辽宁","吉林","黑龙江","江苏","浙江","安徽","福建","江西","山东","河南","湖北","湖南","广东","海南","四川","贵州","云南","陕西","甘肃","青海","台湾","内蒙古","广西","西藏","宁夏","新疆","香港","澳门"]
    private let keys = ["市","区","县","镇","街道","路","街","巷","号","楼","栋","单元","室","大道"]

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 6 else { return nil }
        var s = 0
        for p in provinces { if t.contains(p) { s += 2; break } }
        var kc = 0; for k in keys { if t.contains(k) { kc += 1 } }
        if kc >= 2 { s += 2 } else if kc >= 1 { s += 1 }
        if t.count >= 15 { s += 1 }
        return s >= 3 ? .address(t) : nil
    }
}

final class RichHTMLDetector: ContentDetecting {
    let identifier = "richHTML"; let priority = 13
    let requiresHTMLData = true

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        guard let data = htmlData, !data.isEmpty else { return nil }
        return .richHTML(text, data)
    }
}
