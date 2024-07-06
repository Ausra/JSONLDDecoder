import Testing
import Foundation
@testable import JSONLDDecoder

struct Recipe: Codable {
    let title: String
}

let jsonData = """
        {
            "title": "Cupcakes"
        }
        """.data(using: .utf8)!

@Test("Return name", arguments: [
    jsonData
])

func testDecoder(jsonData: Data) async throws {
    let decoder = RecipeJSONLDDecoder()

    do {
        let recipe = try decoder.decode(Recipe.self, from: jsonData)
        #expect(recipe.title == "Cupcakes")
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }

}



