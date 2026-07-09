import Foundation

// MARK: - Localization
//
// Source of truth for Crowdin: Resources/en.lproj/Localizable.strings
// Translations: Resources/<lang>.lproj/Localizable.strings
// Config: crowdin.yml
//
// Usage:
//   Text(L10n.Tab.status)
//   Text(L10n.tr("join.count", count, total))
//
// Keys are stable English identifiers. Never use translated text as keys.

enum L10n {
    /// Lookup + optional String(format:) arguments.
    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = Bundle.main.localizedString(forKey: key, value: nil, table: "Localizable")
        // If missing translation, Bundle returns the key — make that obvious in debug
        let resolved = (format == key) ? missing(key) : format
        guard !args.isEmpty else { return resolved }
        return String(format: resolved, locale: Locale.current, arguments: args)
    }

    private static func missing(_ key: String) -> String {
        #if DEBUG
        return "¿\(key)?"
        #else
        return key
        #endif
    }

    // MARK: - Tabs & chrome

    enum Tab {
        static var status: String { tr("tab.status") }
        static var profiles: String { tr("tab.profiles") }
        static var pro: String { tr("tab.pro") }
    }

    enum App {
        static var name: String { tr("app.name") }
        static var refresh: String { tr("app.refresh") }
        static var quit: String { tr("app.quit") }
        static var copyIP: String { tr("app.copy_ip") }
        static var disconnect: String { tr("app.disconnect") }
        static var join: String { tr("app.join") }
        static var router: String { tr("app.router") }
        static var powerOn: String { tr("app.power_on") }
        static var powerOff: String { tr("app.power_off") }
    }

    // MARK: - Status

    enum Status {
        static var active: String { tr("status.badge.active") }
        static var linking: String { tr("status.badge.linking") }
        static var down: String { tr("status.badge.down") }
        static var ip: String { tr("status.ip") }
        static var mask: String { tr("status.mask") }
        static var router: String { tr("status.router") }
        static var internet: String { tr("status.internet") }
        static var mac: String { tr("status.mac") }
        static var dns: String { tr("status.dns") }
        static var nearby: String { tr("status.nearby") }
        static var scanOn: String { tr("status.scan_on") }
        static var scanOff: String { tr("status.scan_off") }
        static var scanDisabled: String { tr("status.scan_disabled") }
        static var scanning: String { tr("status.scanning") }
        static var noNetworks: String { tr("status.no_networks") }
        static var moreNetworks: String { tr("status.more_networks") } // %d
        static var gateway: String { tr("status.gateway") }
        static var internetOK: String { tr("status.internet_ok") }
        static var internetLAN: String { tr("status.internet_lan") }
        static var internetNoRoute: String { tr("status.internet_no_route") }
        static var rx: String { tr("status.rx") }
        static var tx: String { tr("status.tx") }
        static var disconnecting: String { tr("status.disconnecting") }
    }

    // MARK: - Signal

    enum Signal {
        static var none: String { tr("signal.none") }
        static var weak: String { tr("signal.weak") }
        static var fair: String { tr("signal.fair") }
        static var good: String { tr("signal.good") }
        static var excellent: String { tr("signal.excellent") }
        static var linking: String { tr("signal.linking") }
        static var associating: String { tr("signal.associating") }
        static var disconnected: String { tr("signal.disconnected") }
        static var connected: String { tr("signal.connected") }
    }

    // MARK: - Profiles / DNS

    enum Profiles {
        static var title: String { tr("profiles.title") }
        static var empty: String { tr("profiles.empty") }
        static var withPassword: String { tr("profiles.with_password") }
        static var open: String { tr("profiles.open") }
        static var last: String { tr("profiles.last") }
        static var forgetTitle: String { tr("profiles.forget_title") }
        static var forgetAction: String { tr("profiles.forget_action") } // %@
        static var forgetMessage: String { tr("profiles.forget_message") }
        static var cancel: String { tr("profiles.cancel") }
        static var folder: String { tr("profiles.folder") }
        static var forgetHelp: String { tr("profiles.forget_help") } // %@
    }

    enum DNS {
        static var title: String { tr("dns.title") }
        static var dhcp: String { tr("dns.dhcp") }
        static var auto: String { tr("dns.preset.auto") }
        static var cloudflare: String { tr("dns.preset.cloudflare") }
        static var google: String { tr("dns.preset.google") }
        static var quad9: String { tr("dns.preset.quad9") }
        static var adguard: String { tr("dns.preset.adguard") }
        static var opendns: String { tr("dns.preset.opendns") }
        static var cfGoogle: String { tr("dns.preset.cf_google") }
        static var detailAuto: String { tr("dns.detail.auto") }
        static var appliedAuto: String { tr("dns.applied.auto") }
        static var applied: String { tr("dns.applied") } // %@ %@
        static var noService: String { tr("dns.no_service") }
        static var autoDisplay: String { tr("dns.auto_display") }
    }

    // MARK: - Pro

    enum Pro {
        static var theme: String { tr("pro.theme") }
        static var menuBar: String { tr("pro.menu_bar") }
        static var behavior: String { tr("pro.behavior") }
        static var tools: String { tr("pro.tools") }
        static var refresh: String { tr("pro.refresh") }
        static var autoReconnect: String { tr("pro.auto_reconnect") }
        static var autoReconnectSub: String { tr("pro.auto_reconnect_sub") }
        static var scanNearby: String { tr("pro.scan_nearby") }
        static var scanNearbySub: String { tr("pro.scan_nearby_sub") }
        static var launchLogin: String { tr("pro.launch_login") }
        static var launchLoginSub: String { tr("pro.launch_login_sub") }
        static var killClassic: String { tr("pro.kill_classic") }
        static var killClassicSub: String { tr("pro.kill_classic_sub") }
        static var quitClassic: String { tr("pro.quit_classic") }
        static var networkSettings: String { tr("pro.network_settings") }
    }

    enum Theme {
        static var powerGadget: String { tr("theme.power_gadget") }
        static var powerGadgetSub: String { tr("theme.power_gadget_sub") }
        static var classic: String { tr("theme.classic") }
        static var classicSub: String { tr("theme.classic_sub") }
        static var midnight: String { tr("theme.midnight") }
        static var midnightSub: String { tr("theme.midnight_sub") }
        static var ember: String { tr("theme.ember") }
        static var emberSub: String { tr("theme.ember_sub") }
        static var matrix: String { tr("theme.matrix") }
        static var matrixSub: String { tr("theme.matrix_sub") }
        static var rose: String { tr("theme.rose") }
        static var roseSub: String { tr("theme.rose_sub") }
    }

    // MARK: - Join

    enum Join {
        static var title: String { tr("join.title") }
        static var reading: String { tr("join.reading") }
        static var emptyCache: String { tr("join.empty_cache") }
        static var rescan: String { tr("join.rescan") }
        static var noneInBand: String { tr("join.none_in_band") } // %@
        static var noneWifi6: String { tr("join.none_wifi6") }
        static var showAll: String { tr("join.show_all") }
        static var cancel: String { tr("join.cancel") }
        static var otherNetwork: String { tr("join.other_network") }
        static var logs: String { tr("join.logs") }
        static var scan: String { tr("join.scan") }
        static var listHint: String { tr("join.list_hint") }
        static var countSummary: String { tr("join.count_summary") } // %d %d %@ %@
        static var connected: String { tr("join.connected") }
        static var options: String { tr("join.options") }
        static var optionsFor: String { tr("join.options_for") } // %@
        static var networkType: String { tr("join.network_type") }
        static var security: String { tr("join.security") }
        static var wps: String { tr("join.wps") }
        static var password: String { tr("join.password") }
        static var wepKey: String { tr("join.wep_key") }
        static var wpsHint: String { tr("join.wps_hint") }
        static var adhocHint: String { tr("join.adhoc_hint") }
        static var connecting: String { tr("join.connecting") }
        static var join: String { tr("join.join") }
        static var joinWpsPbc: String { tr("join.join_wps_pbc") }
        static var red: String { tr("join.red") } // Red: %@
        static var emptySSID: String { tr("join.empty_ssid") }
        static var shortKey: String { tr("join.short_key") } // %d
        static var adhocAuthNudge: String { tr("join.adhoc_auth_nudge") }
        static var noNetworks: String { tr("join.no_networks") }
        static var logsEmpty: String { tr("join.logs_empty") }
        static var copy: String { tr("join.copy") }
        static var file: String { tr("join.file") }
        static var allBands: String { tr("join.band.all") }
        static var band24: String { tr("join.band.24") }
        static var band5: String { tr("join.band.5") }
        static var wifi6Filter: String { tr("join.wifi6_filter") }
        static var open: String { tr("join.auth.open") }
        static var wpa2: String { tr("join.auth.wpa2") }
        static var wpa: String { tr("join.auth.wpa") }
        static var wpaNone: String { tr("join.auth.wpa_none") }
        static var wep: String { tr("join.auth.wep") }
        static var updatedAgo: String { tr("join.updated_ago") } // %d
        static var updatedMin: String { tr("join.updated_min") } // %d
        static var cacheOld: String { tr("join.cache_old") }
        static var connectingTo: String { tr("join.connecting_to") } // %@
        static var wpsPbcWait: String { tr("join.wps_pbc_wait") } // %@
    }

    enum NetType {
        static var infra: String { tr("nettype.infra") }
        static var infraShort: String { tr("nettype.infra_short") }
        static var adhoc: String { tr("nettype.adhoc") }
        static var auto: String { tr("nettype.auto") }
    }

    enum WPS {
        static var none: String { tr("wps.none") }
        static var pbc: String { tr("wps.pbc") }
        static var pin: String { tr("wps.pin") }
        static var pinField: String { tr("wps.pin_field") }
    }

    enum Auth {
        static var open: String { tr("auth.open") }
        static var wep64: String { tr("auth.wep64") }
        static var wep128: String { tr("auth.wep128") }
        static var wpaPsk: String { tr("auth.wpa_psk") }
        static var wpaPskAes: String { tr("auth.wpa_psk_aes") }
        static var wpa2Tkip: String { tr("auth.wpa2_tkip") }
        static var wpa2: String { tr("auth.wpa2") }
    }

    // MARK: - Model status strings

    enum Model {
        static var disconnected: String { tr("model.disconnected") }
        static var connected: String { tr("model.connected") } // %@
        static var associating: String { tr("model.associating") } // %@
        static var noLink: String { tr("model.no_link") } // %@
        static var driverMissing: String { tr("model.driver_missing") }
        static var radioOff: String { tr("model.radio_off") }
        static var noIface: String { tr("model.no_iface") }
        static var reconnecting: String { tr("model.reconnecting") } // %@
        static var disconnectedOk: String { tr("model.disconnected_ok") }
        static var disconnectFail: String { tr("model.disconnect_fail") }
        static var joinOk: String { tr("model.join_ok") } // %@ %@
        static var joinNoLink: String { tr("model.join_no_link") }
        static var joinFail: String { tr("model.join_fail") } // %@
        static var emptySSID: String { tr("model.empty_ssid") }
        static var driverNotLoaded: String { tr("model.driver_not_loaded") }
        static var radioOnFail: String { tr("model.radio_on_fail") }
        static var radioOffFail: String { tr("model.radio_off_fail") }
        static var forgetFail: String { tr("model.forget_fail") } // %@
        static var forgetPassLeft: String { tr("model.forget_pass_left") } // %@
        static var forgot: String { tr("model.forgot") } // %@
        static var radioOn: String { tr("model.radio_on") }
        static var radioOffStatus: String { tr("model.radio_off_status") }
    }

    // MARK: - Menu bar display modes

    enum MenuBar {
        static var icon: String { tr("menubar.icon") }
        static var ssid: String { tr("menubar.ssid") }
        static var ip: String { tr("menubar.ip") }
        static var speed: String { tr("menubar.speed") }
        static var ssidIp: String { tr("menubar.ssid_ip") }
        static var off: String { tr("menubar.off") }
        static var disconnectedTip: String { tr("menubar.disconnected_tip") }
    }

    // MARK: - Band / generation (short chips often stay universal)

    enum Band {
        static var all: String { tr("band.all") }
        static var g24: String { tr("band.24") }
        static var g5: String { tr("band.5") }
        static var g24Short: String { tr("band.24_short") }
        static var g5Short: String { tr("band.5_short") }
    }

    enum Gen {
        static var wifi4: String { tr("gen.wifi4") }
        static var wifi5: String { tr("gen.wifi5") }
        static var wifi6: String { tr("gen.wifi6") }
        static var wifi7: String { tr("gen.wifi7") }
        static var legacy: String { tr("gen.legacy") }
        static var bg: String { tr("gen.bg") }
    }

    enum Badge {
        static var adhoc: String { tr("badge.adhoc") }
        static var wps: String { tr("badge.wps") }
        static var secured: String { tr("badge.secured") }
        static var open: String { tr("badge.open") }
    }

    enum Notify {
        // use tr() for formatted bodies
    }
}
