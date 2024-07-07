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
public struct NestedDecodable<T: Decodable, Keys: CodingKey & CaseIterable>: Decodable {
    public var wrappedValue: T
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

enum ValidationError: Error {
    case noNestedKeys
}

extension KeyedDecodingContainer {
    func decode<T, NestedKeys>(_: NestedDecodable<T, NestedKeys>.Type, forKey key: Key) throws -> NestedDecodable<T, NestedKeys> {
        guard NestedKeys.allCases.isEmpty == false else { throw ValidationError.noNestedKeys }

        var container = try self.nestedContainer(keyedBy: NestedKeys.self, forKey: key)
        for key in NestedKeys.allCases.dropLast() {
            container = try container.nestedContainer(keyedBy: NestedKeys.self, forKey: key)
        }
        let wrappedValue = try container.decode(T.self, forKey: NestedKeys.lastCase!)
        return NestedDecodable(wrappedValue: wrappedValue)
    }
}

extension CaseIterable {
    static var lastCase: Self? {
        guard allCases.isEmpty == false else { return nil }
        let lastIndex = allCases.index(allCases.endIndex, offsetBy: -1)
        return allCases[lastIndex]
    }
}
