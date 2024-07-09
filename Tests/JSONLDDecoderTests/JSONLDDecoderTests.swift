import Testing
import Foundation
@testable import JSONLDDecoder

struct Recipe: Decodable {
    var name: String?

    @ArrayNestedDecodable<String, ImageCodingKeys>
    var images: [String]?

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
        case images = "image"
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
    enum ImageCodingKeys: String, CodingKey, CaseIterable {
        case url
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
    "image": "https://www.aspicyperspective.com/wp-content/uploads/2020/07/best-hamburger-patties-1.jpg",

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
    "recipeYield": ["6"],
     "image": [
        "https://www.aspicyperspective.com/wp-content/uploads/2020/07/best-hamburger-patties-1.jpg",
        "https://www.aspicyperspective.com/wp-content/uploads/2020/07/best-hamburger-patties-1-500x500.jpg"
      ],


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
        #expect(recipe.description == "something")
        #expect(recipe.ingredients == ["1 banano, 1 kriaus"])
        #expect(recipe.recipeYield == ["0"])
        #expect(recipe.images == ["https://www.aspicyperspective.com/wp-content/uploads/2020/07/best-hamburger-patties-1.jpg"])
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
        #expect(recipe.images == [
            "https://www.aspicyperspective.com/wp-content/uploads/2020/07/best-hamburger-patties-1.jpg",
            "https://www.aspicyperspective.com/wp-content/uploads/2020/07/best-hamburger-patties-1-500x500.jpg"
        ])
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }
}



struct RecipeImages: Decodable {
    var name: String?

    @ArrayNestedDecodable<String, ImageCodingKeys>
    var images: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case images = "image"
    }

    enum ImageCodingKeys: String, CodingKey, CaseIterable {
        case url
    }

}

let jsonImageString = """
{
    "image": "https://www.images.com/",

}
""".data(using: .utf8)!

let jsonImageArray = """
{
     "image": [
        "https://www.images.com/",
        "https://www.images.com/"
      ],
}
""".data(using: .utf8)!

let jsonImageObjectsArray = """
{
    "image": [
        {
            "@type": "ImageObject",
            "url": "https://www.images.com/"
        },
        {
            "@type": "ImageObject",
            "url": "https://www.anotherimage.com/"
        }
    ]
}
""".data(using: .utf8)!

let jsonImageObject =  """
{
    "image":
    {
      "@type": "ImageObject",
      "url": "https://www.images.com/"
    }
}
""".data(using: .utf8)!



@Test("ArrayNestedDecodable: returns array of strings", arguments: [
    jsonImageString, jsonImageArray, jsonImageObjectsArray, jsonImageObject
])

func testArrayNestedDecodable(jsonData: Data) async throws {
    let decoder = RecipeJSONLDDecoder()

    do {
        let recipe = try decoder.decode(RecipeImages.self, from: jsonImageString)
        #expect(recipe.images == ["https://www.images.com/"])
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }

    do {
        let recipe = try decoder.decode(RecipeImages.self, from: jsonImageArray)
        #expect(recipe.images == [
            "https://www.images.com/",
            "https://www.images.com/"
        ])
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }

    do {
        let recipe = try decoder.decode(RecipeImages.self, from: jsonImageObject)
        #expect(recipe.images == [
            "https://www.images.com/"
        ])
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }

//    do {
//        let recipe = try decoder.decode(RecipeImages.self, from: jsonImageObjectsArray)
//        #expect(recipe.images == [
//            "https://www.images.com/"
//        ])
//    } catch {
//        Issue.record("Decoding failed with error: \(error)")
//    }
}
