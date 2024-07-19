import Foundation

public struct RecipeJSONLDDecoder: Sendable {
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
}


extension CodingKey where Self: CaseIterable {
    static var lastCase: Self? {
        guard allCases.isEmpty == false else { return nil }
        let lastIndex = allCases.index(allCases.endIndex, offsetBy: -1)
        return allCases[lastIndex]
    }
}

