import XCTest
@testable import EbookTWAPI

final class EbookTWAPITests: XCTestCase {

    func testMakingURLRequest() throws {
        let keywordEn = "bookname"
        let urlRequestEn = APIClient.makeRequest(from: keywordEn, withDevAPI: false)
        XCTAssertEqual(urlRequestEn?.httpMethod, "POST")
        XCTAssertEqual(urlRequestEn?.url?.scheme, "https")
        XCTAssertEqual(urlRequestEn?.url?.host, "ebook.yuer.tw")
        XCTAssertEqual(urlRequestEn?.url?.path, "/v1/searches")
        XCTAssertEqual(urlRequestEn?.url?.port, nil)
        XCTAssertEqual(urlRequestEn?.url?.query, "q=bookname")
        let keywordZh = "書名"
        let urlRequestZh = APIClient.makeRequest(from: keywordZh, withDevAPI: true)
        XCTAssertEqual(urlRequestZh?.httpMethod, "POST")
        XCTAssertEqual(urlRequestZh?.url?.scheme, "https")
        XCTAssertEqual(urlRequestZh?.url?.host, "ebook.yuer.tw")
        XCTAssertEqual(urlRequestZh?.url?.path, "/v1/searches")
        XCTAssertEqual(urlRequestZh?.url?.port, 8443)
        XCTAssertEqual(urlRequestZh?.url?.query, "q=%E6%9B%B8%E5%90%8D")
    }

    func testParsingResponse() throws {
        let dataString = """
                {
                  "results": [
                    {
                      "isOkay": true,
                      "status": "",
                      "bookstore": {
                        "id": "bookStore",
                        "displayName": "BookStore",
                        "isOnline": true
                      },
                      "books" : [
                        {
                          "thumbnail": "",
                          "title": "bookTitle",
                          "link": "",
                          "priceCurrency": "TWD",
                          "price": 100
                        }
                      ]
                    }
                  ]
                }
                """
        guard let data = dataString.data(using: .utf8) else {
            XCTFail()
            return
        }
        let response = try APIClient.parseResponse(data: data, with: JSONDecoder())
        let expectedResponse = EbookResponse(results: [
            EbookResponse.Result(
                bookstore: EbookResponse.Bookstore(id: "bookStore", displayName: "BookStore", isOnline: true),
                books: [EbookResponse.Book(thumbnail: "", title: "bookTitle", link: "", priceCurrency: "TWD", price: 100)],
                isOkay: true, status: "")
        ])
        XCTAssertEqual(response, expectedResponse)
    }
}
