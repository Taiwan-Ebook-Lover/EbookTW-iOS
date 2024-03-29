import XCTest
@testable import EbookTWAPI

final class EbookTWAPITests: XCTestCase {

    var webBaseURLComponents : URLComponents {
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        urlComponent.host = "taiwan-ebook-lover.github.io"
        return urlComponent
    }

    func testMakingSearchParameter() throws {
        // Based on spec of
        // https://github.com/Taiwan-Ebook-Lover/Taiwan-Ebook-Lover.github.io/pull/54#pullrequestreview-821736848
        let testingArray : [(path: String, query: String?, expected: SearchParameter)] = [
            ("/search/123", nil, SearchParameter.resultID("123")),
            ("/searches/456", nil, SearchParameter.resultID("456")),
            ("/search", "q=123", SearchParameter.keyword("123")),
            ("/searches", "q=456", SearchParameter.keyword("456")),
        ]
        for testingCase in testingArray {
            var urlComponent = webBaseURLComponents
            urlComponent.path = testingCase.path
            urlComponent.query = testingCase.query
            XCTAssertNotNil(urlComponent.url)
            let result = APIClient.makeSearchParameter(from: urlComponent.url!)
            switch result {
            case .success(let searchParameter):
                XCTAssertEqual(searchParameter, testingCase.expected)
            case .failure(let error):
                XCTFail(error.message)
            }
        }
    }

    func testMakingURLRequest() throws {
        let keywordEn = "bookname"
        let urlRequestEn = APIClient.makeRequest(from: .keyword(keywordEn), withDevAPI: false)
        XCTAssertEqual(urlRequestEn?.httpMethod, "POST")
        XCTAssertEqual(urlRequestEn?.url?.scheme, "https")
        XCTAssertEqual(urlRequestEn?.url?.host, "ebook.yuer.tw")
        XCTAssertEqual(urlRequestEn?.url?.path, "/v1/searches")
        XCTAssertEqual(urlRequestEn?.url?.port, nil)
        XCTAssertEqual(urlRequestEn?.url?.query, "q=bookname")
        let keywordZh = "書名"
        let urlRequestZh = APIClient.makeRequest(from: .keyword(keywordZh), withDevAPI: true)
        XCTAssertEqual(urlRequestZh?.httpMethod, "POST")
        XCTAssertEqual(urlRequestZh?.url?.scheme, "https")
        XCTAssertEqual(urlRequestZh?.url?.host, "ebook.yuer.tw")
        XCTAssertEqual(urlRequestZh?.url?.path, "/v1/searches")
        XCTAssertEqual(urlRequestZh?.url?.port, 8443)
        XCTAssertEqual(urlRequestZh?.url?.query, "q=%E6%9B%B8%E5%90%8D")
        let searchResultID = "searchResultID"
        let urlRequestWithID = APIClient.makeRequest(from: .resultID(searchResultID), withDevAPI: true)
        XCTAssertEqual(urlRequestWithID?.httpMethod, "GET")
        XCTAssertEqual(urlRequestWithID?.url?.scheme, "https")
        XCTAssertEqual(urlRequestWithID?.url?.host, "ebook.yuer.tw")
        XCTAssertEqual(urlRequestWithID?.url?.path, "/v1/searches/\(searchResultID)")
        XCTAssertEqual(urlRequestWithID?.url?.port, 8443)
        XCTAssertEqual(urlRequestWithID?.url?.query, nil)
    }

    func testParsingResponse() throws {
        let dataString = """
                {
                  "keywords": "searchKeyword",
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
                  ],
                  "id": "searchResultID"
                }
                """
        guard let data = dataString.data(using: .utf8) else {
            XCTFail()
            return
        }
        let response = try APIClient.parseResponse(data: data, with: JSONDecoder())
        let expectedResponse = EbookResponse(
            keywords: "searchKeyword",
            results: [
                EbookResponse.Result(
                    bookstore: EbookResponse.Bookstore(id: "bookStore", displayName: "BookStore", isOnline: true),
                    books: [EbookResponse.Book(thumbnail: "", title: "bookTitle", link: "", priceCurrency: "TWD", price: 100)],
                    isOkay: true, status: "")
            ],
            id: "searchResultID"
        )
        XCTAssertEqual(response, expectedResponse)
    }
}
