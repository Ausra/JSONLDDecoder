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
