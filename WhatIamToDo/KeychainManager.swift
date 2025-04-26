//
//  KeychainManager.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 27.03.2025.
//

import Foundation
import Security

final class KeychainManager {

    /// Сохраняет данные в Keychain под указанным ключом.
    /// Если для данного ключа уже существует запись, она будет перезаписана.
    /// - Parameters:
    ///   - key: Ключ для хранения.
    ///   - data: Данные, которые необходимо сохранить.
    /// - Returns: OSStatus, показывающий результат операции.
    @discardableResult
    class func save(key: String, data: Data) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data
        ]
        
        // Удаляем существующую запись
        SecItemDelete(query as CFDictionary)
        // Добавляем новую запись
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Загружает данные из Keychain по указанному ключу.
    /// - Parameter key: Ключ, по которому нужно получить данные.
    /// - Returns: Данные, если они найдены, иначе nil.
    class func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == noErr {
            return dataTypeRef as? Data
        } else {
            print("Keychain load failed for key \(key) with status: \(status)")
            return nil
        }
    }
    
    /// Удаляет запись из Keychain по указанному ключу.
    /// - Parameter key: Ключ, по которому нужно удалить данные.
    class func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    /// метод для сохранения строки (например, access_token) в Keychain.
    /// - Parameters:
    ///   - key: Ключ для хранения.
    ///   - value: Строка для сохранения.
    /// - Returns: OSStatus операции.
    @discardableResult
    class func saveString(key: String, value: String) -> OSStatus {
        guard let data = value.data(using: .utf8) else { return errSecParam }
        return save(key: key, data: data)
    }
    
    /// метод для загрузки строки из Keychain.
    /// - Parameter key: Ключ, по которому нужно получить строку.
    /// - Returns: Строка, если данные найдены, иначе nil.
    class func loadString(key: String) -> String? {
        if let data = load(key: key) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
