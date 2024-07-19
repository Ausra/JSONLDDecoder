import Foundation

@propertyWrapper
public struct AdaptiveArrayDecoder<T: NestedObjectProtocol & Decodable & Sendable>: Decodable, Sendable {
    public var wrappedValue: [T]?
    
    public init(wrappedValue: [T]?) {
        self.wrappedValue = wrappedValue
    }
}

public protocol NestedObjectProtocol: Decodable, Sendable {
    var text: String? { get }
    init(text: String?)
}

public struct NestedObject: NestedObjectProtocol, Decodable, Sendable {
    public var text: String?
    
    public init(text: String?) {
        self.text = text
    }
}

extension KeyedDecodingContainer {
    
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
    
    
    
    
    
}
