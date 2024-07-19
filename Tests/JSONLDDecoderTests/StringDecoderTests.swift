import Foundation
import Testing
@testable import JSONLDDecoder

@Suite("StringDecoderTests") struct StringDecoderTests {
    struct RecipeYield: Decodable {
        @StringArrayDecoder
        var recipeYield: [String]?
    }

    let jsonInt = """
{
    "recipeYield": 0
}
""".data(using: .utf8)!

    let jsonArray = """
{
    "recipeYield": ["6", "6 patties"]
}
""".data(using: .utf8)!

    let jsonString = """
{
    "recipeYield": "6"
}
""".data(using: .utf8)!

    let jsonMissingKey = """
{
    "name": "6"
}
""".data(using: .utf8)!

    @Test("Returns array of strings") func testDecoder() async throws {
        let decoder = RecipeJSONLDDecoder()

        do {
            let recipe = try decoder.decode(RecipeYield.self, from: jsonInt)
            #expect(recipe.recipeYield == ["0"])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }

        do {
            let recipe = try decoder.decode(RecipeYield.self, from: jsonArray)
            #expect(recipe.recipeYield == ["6", "6 patties"])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }

        do {
            let recipe = try decoder.decode(RecipeYield.self, from: jsonString)
            #expect(recipe.recipeYield == ["6"])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }

        do {
            let recipe = try decoder.decode(RecipeYield.self, from: jsonMissingKey)
            #expect(recipe.recipeYield == nil)
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

}
