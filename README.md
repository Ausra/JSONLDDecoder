# JSONLD Decoder

This Swift package provides utilities for decoding JSON-LD data structures, specifically tailored for json object that fits [Schema.org > Recipe](https://schema.org/Recipe) shape. The package includes a JSON decoder and several property wrappers to handle nested objects and arrays in a flexible manner.

## Features

- **RecipeJSONLDDecoder**: A JSONdecoder to initiate decoding.
- **StringArrayDecoder**: A property wrapper to decode a given string to or array of strings to arrays of strings.
- **NestedObjectsDecoder**: A property wrapper to decode nested objects given the codingkey path to the nested object property.
- **ArrayOfNestedObjectsDecoder**: A property wrapper to decode arrays of nested objects given the key path to the nested objects property.
- **AdaptiveArrayDecoder**: A property wrapper to decode adaptive arrays of nested objects given a nested object which conforms to `NestedObjectProtocol`.
- **NestedObjectProtocol**: A protocol for nested objects.

## Requirements

- iOS 18.0+ / macOS 14.0+
- Swift 6.0+
- Xcode 16+
- swift-tools-version: 6.0

## Installation

### Using Swift Package Manager in Xcode

 1. Open your Xcode project.
 2. Choose `File > Add Package Dependencies` to open swift package manager.
 3. Enter the repository URL of the JSONLDDecoder package in the search field:
    ``` https://github.com/Ausra/JSONLDDecoder.git```
4. Click `Add Package` button
5. Xcode will fetch the package and add it to your project.


### Swift Package Manager

To add JSONLDDecoder to your project, include the following dependency in your `Package.swift` file:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v18),
    ],
    dependencies: [
        .package(url: "https://github.com/Ausra/JSONLDDecoder.git", from: "1.0.10")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["JSONLDDecoder"]
        ),
    ]
)
```
## Usage

### Importing RecipeScraper

First, import `JSONLDDecoder` into your Swift file:

```swift
import Foundation
import RecipeJSONLDDecoder

let decoder = RecipeJSONLDDecoder()
let jsonData: Data = // your JSON data
let decodedObject = try decoder.decode(YourDecodableType.self, from: jsonData)
```
Then, add any of the property wrappers to enhance decoding of given struct property.

### Property Wrappers

#### StringArrayDecoder

`StringArrayDecoder` is a property wrapper to handle both single strings, arrays of strings, and single ints, decoding to an array of strings or `nil` if key not found.

```
import RecipeJSONLDDecoder

struct RecipeAuthor: Decodable {
    @StringArrayDecoder var name: [String]?
}
```
Given a JSON object like this:

```
{
    "author": "John Adam"
}
```

This will decode to `author.name = ["John Adam"]`.

#### NestedObjectsDecoder

`NestedObjectsDecoder` is a property wrapper to decode nested objects with a given coding key path to the nested property within an object. It can handle single strings or nested objects and decodes to a string or `nil` if the key is not found.

```
import RecipeJSONLDDecoder

struct RecipeAuthor: Decodable {
        @NestedObjectsDecoder<String, AuthorCodingKeys>
        var author: String?

        // enum with key path to nested object property
        enum AuthorCodingKeys: String, CodingKey, CaseIterable {
            case details, name
        }
}
```

Given a JSON object like this:

```
{
    "author":
    {
      "@type": "Person",
      "details":
      {
         "name": "John Adam"
      }
    }
}
```

This will decode to `author.name = "John Adam"`.

Given a JSON object like this:

```
{
    "author":  "John Adam"
}
```

This will decode to `author.name = "John Adam"`.

#### ArrayOfNestedObjectsDecoder

`ArrayOfNestedObjectsDecoder` is a property wrapper to decode arrays of nested objects with a given key path. It can handle single string, array of strings, single nested objects, or array of objects. Decodes to array of strings or `nil` if key not found.

```
import RecipeJSONLDDecoder

struct RecipeAuthor: Decodable {
        @ArrayOfNestedObjectsDecoder<String, AuthorCodingKeys>
        var author: [String]?

        // enum with key path to nested object property
        enum AuthorCodingKeys: String, CodingKey, CaseIterable {
            case details, name
        }
}
```

Given a JSON object like this:

```
{
    "author": [
      {
        "@type": "Person",
        "details":
          {
             "name": "John Adam"
          }
      },
      {
        "@type": "Person",
        "details":
          {
             "name": "Peter Friend"
          }
      }
  ]
}
```

This will decode to `author.name = ["John Adam", "Peter Friend"]`.

Given a JSON object like this:

```
{
    "author":  "John Adam"
}
```

This will decode to `author.name = ["John Adam"]`.

#### AdaptiveArrayDecoder

`AdaptiveArrayDecoder` is a property wrapper to decode adaptive arrays of nested objects. It can handle: single string, array of strings, single nested object and array of nested objects. Decodes to a given nested object type or `nil` if key not found.  

```
import RecipeJSONLDDecoder

struct RecipeAuthor: Decodable {
        @AdaptiveArrayDecoder
        var author: [ParsedAuthor]?
}

struct ParsedAuthor: Decodable, Equatable, NestedObjectProtocol {
        var text: String?
        var name: String?

        init(text: String?, name: String? = nil) {
            self.text = text
            self.name = name
        }

        // init to conform to NestedObjectProtocol
        init(text: String?) {
            self.text = text
            self.name = nil
        }
    }
```

Given a JSON object like this:

```
{
    "author": [
      {
        "@type": "Person",
        "text": "John Adam",
        "name": "John Adam"
      },
      {
        "@type": "Person",
        "text": "Peter Friend"
        "name": "Peter Friend"
      }
    ]
}
```

This will decode to `author.name = [ParsedAuthor(text: "John Adam", name: "John Adam"), ParsedAuthor(text: "Peter Friend", name: "Peter Friend")]`.

Given a JSON object like this:

```
{
    "author":  "John Adam",
}
```

This will decode to `author.name = [ParsedAuthor(text: "John Adam", name: "John Adam")]`.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

