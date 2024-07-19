import Testing
import Foundation
@testable import JSONLDDecoder

@Suite("NestedObjectsDecoderTests")
struct NestedObjectsDecoderTests {

    struct RecipeAuthor: Decodable {
        @NestedObjectsDecoder<String, AuthorCodingKeys>
        var author: String?

        enum AuthorCodingKeys: String, CodingKey, CaseIterable {
            case name
        }
    }

    let jsonObject =  """
{
    "author":
    {
      "@type": "Person",
      "name": "John Adam"
    }
}
""".data(using: .utf8)!

    let jsonString =  """
{
    "author": "John Adam"
}
""".data(using: .utf8)!

    @Test func testDecoder() async throws {
        let decoder = RecipeJSONLDDecoder()

        do {
            let recipe = try decoder.decode(RecipeAuthor.self, from: jsonObject)
            #expect(recipe.author == "John Adam")
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }

        do {
            let recipe = try decoder.decode(RecipeAuthor.self, from: jsonString)
            #expect(recipe.author == "John Adam")
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }
}
