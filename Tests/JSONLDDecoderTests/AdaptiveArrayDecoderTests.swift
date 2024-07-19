import Testing
import Foundation
@testable import JSONLDDecoder

@Suite("AdaptiveArrayDecoderTests")
struct AdaptiveArrayDecoderTests {

    struct RecipeInstructions: Decodable {

        @AdaptiveArrayDecoder
        var instructions: [ParsedInstruction]?

        enum CodingKeys: String, CodingKey {
            case instructions = "recipeInstructions"
        }
    }

    struct ParsedInstruction: Decodable, Equatable, NestedObjectProtocol {
        var text: String?
        var name: String?
        var image: String?

        private enum CodingKeys: String, CodingKey {
            case name, text, image = "url"
        }

        init(text: String?, name: String? = nil, image: String? = nil) {
            self.text = text
            self.name = name
            self.image = image
        }

        init(text: String?) {
            self.text = text
            self.name = nil
            self.image = nil
        }
    }

    let jsonHowToObjects = """
    {
         "recipeInstructions": [
            {
              "@type": "HowToStep",
              "text": "step 1",
              "name": "step 1",
              "url": "https://worldrecipes.com/#step-1"
            },
            {
              "@type": "HowToStep",
              "text": "Step 2",
              "name": "Step 2",
              "url": "https://worldrecipes.com/#step-2"
            }
        ]
    }
    """.data(using: .utf8)!

    let jsonSingleString = """
    {
        "recipeInstructions": "Step1 Step2"
    }
    """.data(using: .utf8)!

    let jsonArrayOfStrings = """
    {
        "recipeInstructions": ["Step1", "Step2"]
    }
    """.data(using: .utf8)!

    let jsonNullString = """
        {
            "recipeInstructions": null
        }
    """.data(using: .utf8)!

    @Test("Returns an array of decoded objects from a single string") func testSingleStringDecoder() async throws {
        let decoder = RecipeJSONLDDecoder()
        do {
            let recipe = try decoder.decode(RecipeInstructions.self, from: jsonSingleString)
            #expect(recipe.instructions == [ParsedInstruction(text: "Step1 Step2", name: nil, image: nil)])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

    @Test("Returns an array of decoded objects from an array of strings") func testArrayOfStringsDecoder() async throws {
        let decoder = RecipeJSONLDDecoder()
        do {
            let recipe = try decoder.decode(RecipeInstructions.self, from: jsonArrayOfStrings)
            #expect(recipe.instructions == [
                ParsedInstruction(text: "Step1", name: nil, image: nil),
                ParsedInstruction(text: "Step2", name: nil, image: nil)
            ])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

    @Test("Returns an array of decoded objects from an array of objects") func testArrayOfObjectsDecoder() async throws {
        let decoder = RecipeJSONLDDecoder()

        do {
            let recipe = try decoder.decode(RecipeInstructions.self, from: jsonHowToObjects)
            #expect(recipe.instructions == [
                ParsedInstruction(text: "step 1", name: "step 1", image: "https://worldrecipes.com/#step-1"),
                ParsedInstruction(text: "Step 2", name: "Step 2", image: "https://worldrecipes.com/#step-2")
            ])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

    @Test("Returns a nil value") func testNilDecoder() async throws {
        let decoder = RecipeJSONLDDecoder()

        do {
            let recipe = try decoder.decode(RecipeInstructions.self, from: jsonNullString)
            #expect(recipe.instructions == nil)
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }
}
