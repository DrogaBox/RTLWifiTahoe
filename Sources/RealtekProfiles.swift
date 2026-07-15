// UNUSED — types are inline in WiFiModel.swift
import Foundation

// MARK: - Realtek profile store (ProfilesList.plist + wifiUtility.plist + profile1x.rtl)

enum RealtekProfiles {
    /// PreferrAuth_Encry = 6 → WPA2-PSK (observed from existing profile)
    private static let authWPA2PSK = 6

    /// Wipe saved credentials for an SSID so the next join asks for the password.
    ///
    /// Realtek stores secrets in **two** places:
    /// 1. `ProfilesList.plist` → `Password` (WPA2-PSK path — what Tahoe uses today)
    /// 2. `profile1x.rtl` → `sae_password=` (WPA3 / wpa_supplicant — StatusBarApp only;
    ///    Tahoe join does not use SAE yet; see re/WIP.md, deferred until needed)
    /// Plus `wifiUtility.plist` → `Last Network` (used as "default" in the UI).
    @discardableResult
    static func forget(ssid: String, supportPath: String) -> Bool {
        let target = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return false }

        var profiles = allProfiles(supportPath: supportPath)

        // Exact or case-insensitive key match
        var removedKey: String?
        if profiles[target] != nil {
            removedKey = target
        } else if let hit = profiles.keys.first(where: {
            $0.caseInsensitiveCompare(target) == .orderedSame
        }) {
            removedKey = hit
        }

        if let key = removedKey {
            profiles.removeValue(forKey: key)
            rtlog("forget: drop ProfilesList key=\(key)")
        } else {
            rtlog("forget: SSID not in ProfilesList (still clearing other stores): \(target)")
        }

        var wroteProfiles = false
        do {
            // Archive as NSDictionary tree — same shape StatusBarApp reads
            let nsProfiles = NSMutableDictionary()
            for (k, v) in profiles {
                nsProfiles[k] = NSDictionary(dictionary: v)
            }
            let root = NSDictionary(dictionary: ["RealtekProfiles": nsProfiles])
            let data = try NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: false)
            try data.write(to: URL(fileURLWithPath: supportPath + "/ProfilesList.plist"), options: .atomic)
            wroteProfiles = true
        } catch {
            rtlog("forget: ProfilesList write failed \(error.localizedDescription)")
        }

        // Always strip wpa_supplicant / SAE secret file
        stripProfile1x(ssid: target, supportPath: supportPath)

        // Always clear Last Network if it points at this SSID
        clearLastNetwork(ifSSID: target, supportPath: supportPath)

        // Verify: must not reappear with a password
        let stillListed = allProfiles(supportPath: supportPath).keys
            .contains { $0.caseInsensitiveCompare(target) == .orderedSame }
        let stillPass = password(for: target, supportPath: supportPath) != nil
            || hasCredentialInProfile1x(ssid: target, supportPath: supportPath)

        if stillListed {
            rtlog("forget: VERIFY fail — still in ProfilesList")
            // Last-resort: rewrite empty if that was the only profile
            if allProfiles(supportPath: supportPath).count == 1 || stillPass {
                try? writeProfilesList([:], supportPath: supportPath)
            }
        }
        if stillPass {
            rtlog("forget: VERIFY fail — credential still present")
        }

        let ok = wroteProfiles && !stillListed && !stillPass
        // If it was never in ProfilesList but we cleared profile1x + last, treat as OK
        if !wroteProfiles && removedKey == nil {
            let okAlt = !hasCredentialInProfile1x(ssid: target, supportPath: supportPath)
            rtlog("forget: alt ok=\(okAlt) for \(target)")
            return okAlt
        }
        rtlog("forget: done \(target) ok=\(ok) removedKey=\(removedKey ?? "-")")
        return ok || (!stillListed && !stillPass)
    }

    private static func writeProfilesList(_ profiles: [String: [String: Any]], supportPath: String) throws {
        let nsProfiles = NSMutableDictionary()
        for (k, v) in profiles {
            nsProfiles[k] = NSDictionary(dictionary: v)
        }
        let root = NSDictionary(dictionary: ["RealtekProfiles": nsProfiles])
        let data = try NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: false)
        try data.write(to: URL(fileURLWithPath: supportPath + "/ProfilesList.plist"), options: .atomic)
    }

    private static func clearLastNetwork(ifSSID ssid: String, supportPath: String) {
        let util = supportPath + "/wifiUtility.plist"
        guard var dict = NSDictionary(contentsOfFile: util) as? [String: Any] else { return }
        let last = (dict["Last Network"] as? String) ?? ""
        guard !last.isEmpty, last.caseInsensitiveCompare(ssid) == .orderedSame else { return }
        dict["Last Network"] = ""
        if let d = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) {
            try? d.write(to: URL(fileURLWithPath: util), options: .atomic)
            rtlog("forget: cleared Last Network (\(last))")
        }
    }

    /// `profile1x.rtl` — wpa_supplicant config with `sae_password="…"`.
    static func hasCredentialInProfile1x(ssid: String, supportPath: String) -> Bool {
        let path = supportPath + "/profile1x.rtl"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8), !text.isEmpty else {
            return false
        }
        for block in profile1xBlocks(in: text) {
            guard blockMatchesSSID(block, ssid: ssid) else { continue }
            if block.contains("sae_password=\"") || block.contains("psk=\"") || block.contains("password=\"") {
                // Empty password does not count
                if block.range(of: #"sae_password="[^"]+""#, options: .regularExpression) != nil { return true }
                if block.range(of: #"psk="[^"]{8,}""#, options: .regularExpression) != nil { return true }
                if block.range(of: #"password="[^"]+""#, options: .regularExpression) != nil { return true }
            }
        }
        return false
    }

    /// Remove `network={…}` blocks for this SSID from profile1x.rtl.
    static func stripProfile1x(ssid: String, supportPath: String) {
        let path = supportPath + "/profile1x.rtl"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8), !text.isEmpty else { return }

        var kept: [String] = []
        var removed = 0
        for block in profile1xBlocks(in: text) {
            if blockMatchesSSID(block, ssid: ssid) {
                removed += 1
            } else {
                kept.append(block)
            }
        }
        guard removed > 0 else {
            // Also handle loose file that is a single network without clean parse
            if text.localizedCaseInsensitiveContains("ssid=\"\(ssid)\"")
                || text.localizedCaseInsensitiveContains("ssid=\(ssid)") {
                try? "".write(toFile: path, atomically: true, encoding: .utf8)
                rtlog("forget: wiped entire profile1x.rtl (ssid match, no blocks kept)")
            }
            return
        }
        let out = kept.joined(separator: "\n")
        try? out.write(toFile: path, atomically: true, encoding: .utf8)
        rtlog("forget: stripped \(removed) network block(s) from profile1x.rtl for \(ssid)")
    }

    private static func blockMatchesSSID(_ block: String, ssid: String) -> Bool {
        // ssid="Name" or ssid=Name
        if block.range(of: "ssid=\"\(ssid)\"", options: .caseInsensitive) != nil { return true }
        // line-based ssid= without quotes
        for line in block.split(whereSeparator: \.isNewline) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.lowercased().hasPrefix("ssid=") {
                var v = String(t.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if v.hasPrefix("\"") && v.hasSuffix("\"") && v.count >= 2 {
                    v = String(v.dropFirst().dropLast())
                }
                if v.caseInsensitiveCompare(ssid) == .orderedSame { return true }
            }
        }
        return false
    }

    /// Split profile1x text into `network={…}` blocks (brace-balanced).
    private static func profile1xBlocks(in text: String) -> [String] {
        var blocks: [String] = []
        var search = text.startIndex
        while search < text.endIndex,
              let start = text.range(of: "network={", range: search..<text.endIndex) {
            var depth = 0
            var i = start.lowerBound
            var end = text.endIndex
            while i < text.endIndex {
                let ch = text[i]
                if ch == "{" { depth += 1 }
                else if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        end = text.index(after: i)
                        break
                    }
                }
                i = text.index(after: i)
            }
            blocks.append(String(text[start.lowerBound..<end]))
            search = end
        }
        return blocks
    }

    /// RealtekProfiles → { SSID: { Password, PreferrAuth_Encry, Channel, … } }
    /// Only dictionary *keys* are SSIDs. Never treat Password values as network names.
    static func allProfiles(supportPath: String) -> [String: [String: Any]] {
        let path = supportPath + "/ProfilesList.plist"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return [:] }

        let allowedClasses: [AnyClass] = [
            NSDictionary.self, NSMutableDictionary.self,
            NSString.self, NSMutableString.self,
            NSNumber.self,
            NSArray.self, NSMutableArray.self
        ]

        guard let root = try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: allowedClasses,
            from: data
        ) as? [String: Any],
              let profs = root["RealtekProfiles"] as? [String: Any] else {
            return [:]
        }

        var result: [String: [String: Any]] = [:]
        for (ssid, val) in profs {
            guard !ssid.isEmpty, ssid.count <= 32 else { continue }
            if ssid == "RealtekProfiles" || ssid == "Password" || ssid == "Channel" { continue }
            if let entry = val as? [String: Any] {
                result[ssid] = entry
            } else if let entry = val as? NSDictionary {
                var plain: [String: Any] = [:]
                for (ek, ev) in entry {
                    if let es = ek as? String { plain[es] = ev }
                }
                result[ssid] = plain
            }
        }
        return result
    }

    static func password(for ssid: String, supportPath: String) -> String? {
        let target = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        let profiles = allProfiles(supportPath: supportPath)
        let entry = profiles[target]
            ?? profiles.first(where: { $0.key.caseInsensitiveCompare(target) == .orderedSame })?.value
        if let pass = entry?["Password"] as? String {
            let t = pass.trimmingCharacters(in: .whitespacesAndNewlines)
            // WPA-PSK length 8…63; empty = open / not stored
            if (8...63).contains(t.count) { return t }
        }
        // Do not fall back to profile1x.rtl for UI prefill after forget —
        // that file is only for wpa_supplicant; Join uses explicit password.
        return nil
    }

    static func setLastNetwork(_ ssid: String, supportPath: String) throws {
        let path = supportPath + "/wifiUtility.plist"
        var dict = (NSDictionary(contentsOfFile: path) as? [String: Any]) ?? [:]
        dict["Last Network"] = ssid
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        try data.write(to: URL(fileURLWithPath: path))
    }

    static func upsert(ssid: String, password: String, supportPath: String) throws {
        var profiles = allProfiles(supportPath: supportPath)
        // Prefer existing key casing if present
        let key = profiles.keys.first(where: { $0.caseInsensitiveCompare(ssid) == .orderedSame }) ?? ssid
        var entry = profiles[key] ?? [:]
        if !password.isEmpty {
            entry["Password"] = password
        } else if entry["Password"] == nil {
            entry["Password"] = ""
        }
        entry["PreferrAuth_Encry"] = entry["PreferrAuth_Encry"] ?? authWPA2PSK
        entry["profilesState"] = 1
        entry["Channel"] = entry["Channel"] ?? 0
        entry["NetworkType"] = false
        profiles[key] = entry
        try writeProfilesList(profiles, supportPath: supportPath)
    }
}
