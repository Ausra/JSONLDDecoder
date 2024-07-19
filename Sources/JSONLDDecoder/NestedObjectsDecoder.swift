import Foundation

@propertyWrapper
public struct NestedObjectsDecoder<T: Decodable & Sendable, Keys: CodingKey & CaseIterable & Sendable>: Decodable, Sendable {
    public var wrappedValue: T?
    
    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
}

extension KeyedDecodingContainer {
    public func decode<T, NestedKeys>(_: NestedObjectsDecoder<T, NestedKeys>.Type, forKey key: Key) throws -> NestedObjectsDecoder<T, NestedKeys> where T: Decodable & Sendable, NestedKeys: CodingKey & CaseIterable & Sendable {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            if let wrappedValue = stringValue as? T {
                return NestedObjectsDecoder(wrappedValue: wrappedValue)
            } else {
                throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: [key], debugDescription: "Expected value of type \(T.self) but found a String."))
            }
        } else if let container = try? nestedContainer(keyedBy: NestedKeys.self, forKey: key), let wrappedValue = try? decodeNestedContainer(container) {
            return NestedObjectsDecoder(wrappedValue: wrappedValue)
        } else {
            return NestedObjectsDecoder(wrappedValue: nil)
        }
        
        func decodeNestedContainer<Keys>(_ container: KeyedDecodingContainer<Keys>) throws -> T? where Keys: CodingKey & CaseIterable & Sendable {
            let allKeys = Array(Keys.allCases)
            guard let firstKey = allKeys.first else {
                throw DecodingError.dataCorruptedError(forKey: allKeys.first!, in: container, debugDescription: "Missing expected key for nested decoding.")
            }
            
            var nestedContainer = container
            for key in allKeys.dropLast() {
                nestedContainer = try nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: key)
            }
            
            if let lastKey = allKeys.last, let value = try? nestedContainer.decode(T.self, forKey: lastKey) {
                return value
            }
            
            throw DecodingError.dataCorruptedError(forKey: firstKey, in: nestedContainer, debugDescription: "Missing expected key for nested decoding.")
        }
    }
}
