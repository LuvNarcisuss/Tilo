import Foundation

enum TiloBackendConfiguration {
    static let projectURL = URL(string: "https://hdapofqufmxlghmcrftg.supabase.co")!
    static let publishableKey = "sb_publishable_Gu352F4AuzrZXlVZHSd34w_04i-TekV"
    static var termsURL: URL? { URL(string: projectURL.absoluteString + "/storage/v1/object/public/legal/2026-11-03/terms.pdf") }
    static var privacyURL: URL? { URL(string: projectURL.absoluteString + "/storage/v1/object/public/legal/2026-11-03/privacy.pdf") }
    static let agreementVersion = "2026-11-06-99d6afcc3037"
}
