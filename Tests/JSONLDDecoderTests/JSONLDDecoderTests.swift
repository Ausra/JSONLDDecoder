import Testing
import Foundation
@testable import JSONLDDecoder

struct Person: Decodable {
    let name: String
    let age: Int
}

let jsonData = """
        {
            "name": "John Doe",
            "age": 30
        }
        """.data(using: .utf8)!

@Test("Return name", arguments: [
    jsonData
])

func testDecoder(jsonData: Data) async throws {
    let decoder = RecipeJSONLDDecoder()

    do {
        let person = try decoder.decode(Person.self, from: jsonData)
        #expect(person.name == "John Doe")
        #expect(person.age == 30)
    } catch {
        Issue.record("Decoding failed with error: \(error)")
    }

}



