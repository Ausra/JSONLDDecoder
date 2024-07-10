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
public struct StringDecoder: Decodable {
    public var wrappedValue: [String]?

    public init(wrappedValue: [String]?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let singleValueContainer = try? decoder.singleValueContainer()

        if let container = singleValueContainer {
            if let value = try? container.decode(String.self) {
                self.wrappedValue = [value]
            } else if let arrayValue = try? container.decode([String].self) {
                self.wrappedValue = arrayValue
            } else if let intValue = try? container.decode(Int.self) {
                self.wrappedValue = [String(intValue)]
            } else {
                self.wrappedValue = nil
            }
        } else {
            self.wrappedValue = nil
        }
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

    public init(from decoder: Decoder) throws {
        // Attempt to decode nested object
        if let container = try? decoder.container(keyedBy: Keys.self), let wrappedValue = try? ArrayOfNestedObjectsDecoder.decodeNestedContainer(container) {
            self.wrappedValue = wrappedValue
            return
        // Attempt to decode array with nested objects
        } else if var unkeyedContainer = try? decoder.unkeyedContainer(), let value = try? ArrayOfNestedObjectsDecoder.decodeNestedArray(&unkeyedContainer, using: Array(Keys.allCases))  {
            self.wrappedValue = value
            return
        } else if let singleValueContainer = try? decoder.singleValueContainer() {
            // Attempt to decode single string
            if let value = try? singleValueContainer.decode(T.self) {
                self.wrappedValue = [value]
                return
                // Attempt to decode array of strings
            } else if let arrayValue = try? singleValueContainer.decode([T].self) {
                self.wrappedValue = arrayValue
                return
            }
        }
    }

    private static func decodeNestedContainer(_ container: KeyedDecodingContainer<Keys>) throws -> [T]? {
        var nestedContainer = container
        let allKeys = Array(Keys.allCases)
        guard let firstKey = allKeys.first else {
            throw DecodingError.dataCorruptedError(forKey: allKeys.first!, in: container, debugDescription: "No nested keys found.")
        }

        // iterate through key path
        for key in allKeys.dropLast() {
            nestedContainer = try nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: key)
        }

        if let lastKey = allKeys.last {
            // Decode single object within the nested container using last key in the key path
            if let value = try? nestedContainer.decode(T.self, forKey: lastKey) {
                return [value]
            }
        }

        throw DecodingError.dataCorruptedError(forKey: firstKey, in: nestedContainer, debugDescription: "Missing expected key for nested decoding.")
    }

    private static func decodeNestedArray(_ container: inout UnkeyedDecodingContainer, using keys: [Keys]) throws -> [T] {
        var result: [T] = []
        //iterate through array objects
        while !container.isAtEnd {
            var nestedContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self)
            let allKeys = keys

            for key in allKeys.dropLast() {
                nestedContainer = try nestedContainer.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: DynamicCodingKey(stringValue: key.stringValue)!)
            }

            if let lastKey = allKeys.last {
                // Handle single object within the nested container
                if let value = try? nestedContainer.decode(T.self, forKey: DynamicCodingKey(stringValue: lastKey.stringValue)!) {
                    result.append(value)
                }
            }
        }
        return result
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

}

