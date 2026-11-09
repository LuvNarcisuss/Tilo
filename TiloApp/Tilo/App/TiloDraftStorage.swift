import Foundation
import CryptoKit

/// Private, account-scoped intent storage. It never replaces acknowledged server content.
@MainActor enum TiloDraftStorage {
    private static func directory(accountID:UUID) throws -> URL {
        let root = URL.applicationSupportDirectory.appendingPathComponent("ToliDrafts",isDirectory:true).appendingPathComponent(accountID.uuidString.lowercased(),isDirectory:true)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        return root
    }
    private static func url(key:String,accountID:UUID) throws -> URL {
        let digest = SHA256.hash(data:Data(key.utf8)).map { String(format:"%02x",$0) }.joined()
        return try directory(accountID:accountID).appendingPathComponent(digest+".json")
    }
    static func save(_ data:Data,key:String,accountID:UUID) throws {
        try data.write(to:url(key:key,accountID:accountID),options:[.atomic,.completeFileProtectionUntilFirstUserAuthentication])
    }
    static func read(key:String,accountID:UUID) throws -> Data? {
        let path = try url(key:key,accountID:accountID)
        guard FileManager.default.fileExists(atPath:path.path) else { return nil }
        return try Data(contentsOf:path)
    }
    static func remove(key:String,accountID:UUID) throws {
        let path = try url(key:key,accountID:accountID)
        if FileManager.default.fileExists(atPath:path.path) { try FileManager.default.removeItem(at:path) }
    }
    static func deleteAccount(_ accountID:UUID) throws {
        let path = try directory(accountID:accountID)
        try FileManager.default.removeItem(at:path)
    }
}
