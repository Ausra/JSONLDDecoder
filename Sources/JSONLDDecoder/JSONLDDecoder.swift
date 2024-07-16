import Foundation

public struct RecipeJSONLDDecoder {
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
}

@propertyWrapper
public struct StringArrayDecoder: Decodable {
    public var wrappedValue: [String]?
    
    public init(wrappedValue: [String]?) {
        self.wrappedValue = wrappedValue
    }
}


@propertyWrapper
public struct NestedObjectsDecoder<T: Decodable, Keys: CodingKey & CaseIterable>: Decodable {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        // Attempt to decode the value as a direct string
        if let singleValueContainer = try? decoder.singleValueContainer(), let value = try? singleValueContainer.decode(T.self) {
            self.wrappedValue = value
        } else {
            // If direct decoding fails, attempt to decode as a nested container
            let container = try decoder.container(keyedBy: Keys.self)
            self.wrappedValue = try NestedObjectsDecoder.decodeNestedContainer(container, nestedKeysType: Keys.self)
        }
    }
    
    private static func decodeNestedContainer<NestedKeys: CodingKey & CaseIterable>(_ container: KeyedDecodingContainer<NestedKeys>, nestedKeysType: NestedKeys.Type) throws -> T {
        let allKeys = Array(NestedKeys.allCases)
        guard let firstKey = allKeys.first else {
            throw DecodingError.dataCorruptedError(forKey: allKeys.first!, in: container, debugDescription: "No nested keys found.")
        }
        
        var nestedContainer = container
        for key in allKeys.dropLast() {
            nestedContainer = try nestedContainer.nestedContainer(keyedBy: NestedKeys.self, forKey: key)
        }
        
        if let lastKey = allKeys.last {
            return try nestedContainer.decode(T.self, forKey: lastKey)
        }
        
        throw DecodingError.dataCorruptedError(forKey: firstKey, in: nestedContainer, debugDescription: "Missing expected key for nested decoding.")
    }
}



@propertyWrapper
public struct ArrayOfNestedObjectsDecoder<T: Decodable, Keys: CodingKey & CaseIterable>: Decodable {
    public var wrappedValue: [T]?
    
    public init(wrappedValue: [T]?) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper
public struct AdaptiveArrayDecoder<T: NestedObjectProtocol & Decodable>: Decodable {
    public var wrappedValue: [T]?

    public init(wrappedValue: [T]?) {
        self.wrappedValue = wrappedValue
    }
}

public protocol NestedObjectProtocol: Decodable {
    var text: String? { get }
    init(text: String?)
}

public struct NestedObject: NestedObjectProtocol, Decodable {
    public var text: String?

    public init(text: String?) {
        self.text = text
    }
}

extension KeyedDecodingContainer {
    public func decode(_ type: StringArrayDecoder.Type, forKey key: Key) throws -> StringArrayDecoder {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return StringArrayDecoder(wrappedValue: [stringValue])
        } else if let arrayValue = try? decodeIfPresent([String].self, forKey: key) {
            return StringArrayDecoder(wrappedValue: arrayValue)
        } else if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return StringArrayDecoder(wrappedValue: [String(intValue)])
        } else {
            return StringArrayDecoder(wrappedValue: nil)
        }
    }
   
    public func decode<T: NestedObjectProtocol & Decodable>(_ type: AdaptiveArrayDecoder<T>.Type, forKey key: Key) throws -> AdaptiveArrayDecoder<T> {
        if let singleValue = try? decodeIfPresent(String.self, forKey: key) {
            let nestedObject = T.init(text: singleValue)
            return AdaptiveArrayDecoder(wrappedValue: [nestedObject])
        } else if let arrayOfStringValues = try? decodeIfPresent([String].self, forKey: key) {
            let arrayOfNestedObjects = arrayOfStringValues.map { T.init(text: $0) }
            return AdaptiveArrayDecoder(wrappedValue: arrayOfNestedObjects)
        } else if let nestedObjects = try? decode([T].self, forKey: key) {
            return AdaptiveArrayDecoder(wrappedValue: nestedObjects)
        }
        else {
            return AdaptiveArrayDecoder(wrappedValue: nil)
        }
    }

    public func decode<T, NestedKeys>(_: ArrayOfNestedObjectsDecoder<T, NestedKeys>.Type, forKey key: Key) throws ->  ArrayOfNestedObjectsDecoder<T, NestedKeys> {
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

         func decodeNestedContainer<Keys>(_ container: KeyedDecodingContainer<Keys>) throws -> [T]? where Keys: CodingKey & CaseIterable {
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

        func decodeNestedArray<Keys>(_ container: inout UnkeyedDecodingContainer, using keys: [Keys]) throws -> [T] where Keys: CodingKey & CaseIterable {
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


extension CodingKey where Self: CaseIterable {
    static var lastCase: Self? {
        guard allCases.isEmpty == false else { return nil }
        let lastIndex = allCases.index(allCases.endIndex, offsetBy: -1)
        return allCases[lastIndex]
    }
}

struct DynamicCodingKey: CodingKey {
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
