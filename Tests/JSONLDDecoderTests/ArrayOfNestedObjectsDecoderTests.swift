import Testing
import Foundation
@testable import JSONLDDecoder

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

    let jsonMissingKeyObject =  """
{
    "banana":
    {
      "@type": "ImageObject",
      "url": "https://www.images.com/"
    }
}
""".data(using: .utf8)!


    let decoder = RecipeJSONLDDecoder()

    @Test("Return an array of string from a given string") func testSingleStringDecoder() async throws {

        do {
            let recipe = try decoder.decode(RecipeImages.self, from: jsonImageString)
            #expect(recipe.images == ["https://www.images.com/"])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

    @Test("Returns an array of strings from jsonImageArray") func testImagesArrayDecoder() async throws {
        do {
            let recipe = try decoder.decode(RecipeImages.self, from: jsonImageArray)
            #expect(recipe.images == [
                "https://www.images.com/",
                "https://www.images.com/"
            ])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

    @Test("Returns nil") func testNilReturn() async throws {
        do {
            let recipe = try decoder.decode(RecipeImages.self, from: jsonMissingKeyObject)
            #expect(recipe.images == nil)
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

    @Test("Returns array with string from nested object") func testImageNested() {

        do {
            let recipe = try decoder.decode(RecipeImages.self, from: jsonImageObject)
            #expect(recipe.images == [
                "https://www.images.com/"
            ])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }


    }

    @Test("Returns an array of strings from array of objects") func testImageObjectsArrayDecoder() async throws {

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

