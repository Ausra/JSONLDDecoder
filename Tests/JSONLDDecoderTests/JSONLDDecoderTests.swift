import Testing
import Foundation
@testable import JSONLDDecoder

struct Recipe: Decodable {
    var name: String?
    @NestedDecodable<String?, AuthorCodingKeys>
    var author: String?

    enum AuthorCodingKeys: String, CodingKey, CaseIterable {
        case name
    }
}

let jsonPersonData = """
{
    "name": "Cupcakes",
    "author": { "@type": "Person", "name": "Mary Cope" },
    "notRelavant": "nothing"
}
""".data(using: .utf8)!

let jsonOrganizationData = """
{
    "name": "Cupcakes",
     "author": {
        "@type": "Organization",
        "name": "Bananaland"
      },
    "notRelavant": "nothing"
}
""".data(using: .utf8)!

@Test("Return nested author name", arguments: [
    jsonPersonData, jsonOrganizationData
])

func testDecoder(jsonData: Data) async throws {
    let decoder = RecipeJSONLDDecoder()

    do {
        let recipe = try decoder.decode(Recipe.self, from: jsonPersonData)
        #expect(recipe.author == "Mary Cope")
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }

    do {
        let recipe = try decoder.decode(Recipe.self, from: jsonOrganizationData)
        #expect(recipe.author == "Bananaland")
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }
}


