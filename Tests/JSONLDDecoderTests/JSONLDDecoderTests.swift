import Testing
import Foundation
@testable import JSONLDDecoder

@Suite("StringDecodableTests") struct StringDecodableTests {
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

@Suite("ArrayOfNestedObjectsDecoderTests") struct ArrayOfNestedObjectsDecoderTests {
    struct RecipeImages: Decodable {
        
        @ArrayOfNestedObjectsDecoder<String, ImageCodingKeys>
        var images: [String]?
        
        enum CodingKeys: String, CodingKey {
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
    
    @Test("Returns an array of strings") func testDecoder() async throws {
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
        
        do {
            let recipe = try decoder.decode(RecipeImages.self, from: jsonImageObjectsArray)
            #expect(recipe.images == [
                "https://www.images.com/",
                "https://www.anotherimage.com/"
            ])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }
}

@Suite("NestedObjectsDecoderTests")
struct NestedObjectsDecoderTests {
    
    struct RecipeAuthor: Decodable {
        @NestedObjectsDecoder<String?, AuthorCodingKeys>
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

