import Testing
import Foundation
@testable import JSONLDDecoder

struct Recipe: Decodable {
    var name: String?
    @NestedDecodable<String?, AuthorCodingKeys>
    var author: String?
    @NestedDecodable<String?, DescriptionCodingKeys>
    var description: String?

    @StringArrayDecodable
    var ingredients: [String]?

    @StringArrayDecodable
    var recipeYield: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case author
        case description
        case ingredients = "recipeIngredient"
        case recipeYield
    }

    // nested enums to decoded
    enum AuthorCodingKeys: String, CodingKey, CaseIterable {
        case name
    }

    enum DescriptionCodingKeys: String, CodingKey, CaseIterable {
        case description
    }

}

let jsonDataWithStrings = """
{
    "name": "Cupcakes",
    "author": "Mary Cope",
    "notRelavant": "nothing",
    "description": "something",
    "recipeIngredient": "1 banano, 1 kriaus",
    "recipeYield": 0,

}
""".data(using: .utf8)!

let jsonDataWithObjects = """
{
    "name": "Cupcakes",
     "author": {
        "@type": "Organization",
        "name": "Bananaland"
      },
    "notRelavant": "nothing",
    "description": {
        "something": "some",
        "description": "amazing"
    },
    "recipeIngredient": [
        "1 banana",
        "1 pear"
      ],
    "recipeYield": ["6"]


}
""".data(using: .utf8)!

@Test("Returns nested strings", arguments: [
    jsonDataWithStrings, jsonDataWithObjects
])

func testDecoder(jsonData: Data) async throws {
    let decoder = RecipeJSONLDDecoder()

    do {
        let recipe = try decoder.decode(Recipe.self, from: jsonDataWithStrings)
        #expect(recipe.name == "Cupcakes")
        #expect(recipe.author == "Mary Cope")
        #expect(recipe.description == "something")
        #expect(recipe.ingredients == ["1 banano, 1 kriaus"])
        #expect(recipe.recipeYield == ["0"])
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }

    do {
        let recipe = try decoder.decode(Recipe.self, from: jsonDataWithObjects)
        #expect(recipe.name == "Cupcakes")
        #expect(recipe.author == "Bananaland")
        #expect(recipe.description == "amazing")
        #expect(recipe.ingredients == [
            "1 banana",
            "1 pear"
        ])
        #expect(recipe.recipeYield == ["6"])
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }
}


