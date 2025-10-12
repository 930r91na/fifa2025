//
//  APIService.swift
//  fifa2025
//
//  Created by Georgina on 11/10/25.
//

import Foundation

// Custom error enum for better error handling
enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
}

// Protocol for mocking and dependency injection
protocol APIServiceProtocol {
    func request<T: Decodable>(url: URL) async throws -> T
}

// The concrete implementation
class APIService: APIServiceProtocol {
    
    func request<T: Decodable>(url: URL) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                throw APIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.requestFailed(error)
        }
    }
}
