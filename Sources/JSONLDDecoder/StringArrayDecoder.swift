import Foundation

@propertyWrapper
public struct StringArrayDecoder: Decodable, Sendable {
    public var wrappedValue: [String]?
    
    public init(wrappedValue: [String]?) {
        self.wrappedValue = wrappedValue
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
}
