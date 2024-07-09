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
public struct StringArrayDecodable: Decodable {
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
public struct NestedDecodable<T: Decodable, Keys: CodingKey & CaseIterable>: Decodable {
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
            self.wrappedValue = try NestedDecodable.decodeFromNestedContainer(container, nestedKeysType: Keys.self)
        }

    }

    private static func decodeFromNestedContainer<NestedKeys: CodingKey & CaseIterable>(_ container: KeyedDecodingContainer<NestedKeys>, nestedKeysType: NestedKeys.Type) throws -> T {
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


