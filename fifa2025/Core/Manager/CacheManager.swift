//
//  CacheManager.swift
//  fifa2025
//
//  Created by Georgina on 12/10/25.
//

import Foundation

/// A generic, thread-safe in-memory cache for storing network results or other objects.
class CacheManager<T> {
    private let cache = NSCache<NSString, AnyObject>()
    private let lock = NSLock()

    /// Saves a value to the cache for a given key.
    /// - Parameters:
    ///   - value: The object to cache.
    ///   - key: The unique key to associate with the value.
    func setValue(_ value: T, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(value as AnyObject, forKey: key as NSString)
    }

    /// Retrieves a value from the cache for a given key.
    /// - Parameter key: The key for the value to retrieve.
    /// - Returns: The cached object, or `nil` if it doesn't exist.
    func getValue(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: key as NSString) as? T
    }

    /// Clears the entire cache.
    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
    }
}
