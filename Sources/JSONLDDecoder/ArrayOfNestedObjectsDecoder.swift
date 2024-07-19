import Foundation

@propertyWrapper
public struct ArrayOfNestedObjectsDecoder<T: Decodable & Sendable, Keys: CodingKey & CaseIterable & Sendable>: Decodable, Sendable {
    public var wrappedValue: [T]?
    
    public init(wrappedValue: [T]?) {
        self.wrappedValue = wrappedValue
    }
}

extension KeyedDecodingContainer {
    public func decode<T, NestedKeys>(_: ArrayOfNestedObjectsDecoder<T, NestedKeys>.Type, forKey key: Key) throws ->  ArrayOfNestedObjectsDecoder<T, NestedKeys>  where T: Decodable & Sendable, NestedKeys: CodingKey & CaseIterable & Sendable {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            if let wrappedValue = stringValue as? T {
                return ArrayOfNestedObjectsDecoder(wrappedValue: [wrappedValue])
            } else {
                throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: [key], debugDescription: "Expected value of type \(T.self) but found a String."))
            }
        } else if let arrayValue = try? decodeIfPresent([String].self, forKey: key) {
            if let wrappedValue = arrayValue as? [T] {
                return ArrayOfNestedObjectsDecoder(wrappedValue: wrappedValue)
            } else {
                throw DecodingError.typeMismatch([T].self, DecodingError.Context(codingPath: [key], debugDescription: "Expected value of type [\(T.self)] but found an array of Strings."))
            }
        } else if let container = try? nestedContainer(keyedBy: NestedKeys.self, forKey: key), let wrappedValue = try? decodeNestedContainer(container) {
            return ArrayOfNestedObjectsDecoder(wrappedValue: wrappedValue)
        } else if var unkeyedContainer = try? nestedUnkeyedContainer(forKey: key), let wrappedValue = try? decodeNestedArray(&unkeyedContainer, using: Array(NestedKeys.allCases)) {
            return ArrayOfNestedObjectsDecoder(wrappedValue: wrappedValue)
        }
        else {
            return ArrayOfNestedObjectsDecoder(wrappedValue: nil)
        }
        
        func decodeNestedContainer<Keys>(_ container: KeyedDecodingContainer<Keys>) throws -> [T]? where Keys: CodingKey & CaseIterable & Sendable {
            let allKeys = Array(Keys.allCases)
            guard let firstKey = allKeys.first else {
                throw DecodingError.dataCorruptedError(forKey: allKeys.first!, in: container, debugDescription: "Missing expected key for nested decoding.")
            }
            
            var nestedContainer = container
            for key in allKeys.dropLast() {
                nestedContainer = try nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: key)
            }
            
            if let lastKey = allKeys.last, let value = try? nestedContainer.decode(T.self, forKey: lastKey) {
                return [value]
            }
            
            throw DecodingError.dataCorruptedError(forKey: firstKey, in: nestedContainer, debugDescription: "Missing expected key for nested decoding.")
        }
        
        func decodeNestedArray<Keys>(_ container: inout UnkeyedDecodingContainer, using keys: [Keys]) throws -> [T] where Keys: CodingKey & CaseIterable & Sendable {
            var result: [T] = []
            while !container.isAtEnd {
                var nestedContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self)
                let allKeys = keys
                
                for key in allKeys.dropLast() {
                    nestedContainer = try nestedContainer.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: DynamicCodingKey(stringValue: key.stringValue)!)
                }
                
                if let lastKey = allKeys.last, let value = try? nestedContainer.decode(T.self, forKey: DynamicCodingKey(stringValue: lastKey.stringValue)!) {
                    result.append(value)
                }
            }
            return result
        }
    }
}


struct DynamicCodingKey: CodingKey, Sendable {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}
