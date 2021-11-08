import Foundation

public enum SearchParameter {
    case keyword(String)
    case resultID(String)
}

public struct APIClient {

    private let urlSession: URLSession

    /// - Parameter urlSession: pass nil for default implementation
    public init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }

    static func makeRequest(from parameter: SearchParameter, withDevAPI: Bool) -> URLRequest? {
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        urlComponent.host = "ebook.yuer.tw"
        if withDevAPI {
            urlComponent.port = 8443
        }
        urlComponent.path = "/v1/searches"
        let httpMethod: String
        switch parameter {
        case .keyword(let keyword):
            httpMethod = "POST"
            urlComponent.queryItems = [     // Percent encoding is automatically done with RFC 3986
                URLQueryItem(name: "q", value: keyword)
            ]
        case .resultID(let resultID):
            httpMethod = "GET"
            urlComponent.path.append(contentsOf: "/\(resultID)")
        }
        guard let url = urlComponent.url else {
            assertionFailure()
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        return request
    }

    static func parseResponse(data: Data, with decoder: JSONDecoder) throws -> EbookResponse {
        return try decoder.decode(EbookResponse.self, from: data)
    }

    public func searchEbook(parameter: SearchParameter, withDevAPI: Bool, withVerbose: Bool,
                            completionHandler: @escaping (Result<EbookResponse, EbookResultError>) -> Void) {
        guard let request = APIClient.makeRequest(from: parameter, withDevAPI: withDevAPI) else {
            completionHandler(.failure(EbookResultError(message: "Error of making request")))
            return
        }
        urlSession.dataTask(with: request) { (data, urlResponse, error) in
            if let error = error {
                completionHandler(.failure(EbookResultError(message: error.localizedDescription)))
                return
            }
            let jsonDecoder = JSONDecoder()
            if withVerbose {
                let successfulStatusCodes = 200..<300
                if let httpUrlResponse = urlResponse as? HTTPURLResponse, !successfulStatusCodes.contains(httpUrlResponse.statusCode) {
                    var errorMessage = "HTTP Error \(httpUrlResponse.statusCode)"
                    if let data = data {
                        if let ebookResultError = try? jsonDecoder.decode(EbookResultError.self, from: data) {
                            errorMessage += "\n\(ebookResultError.message)"
                        } else {
                            errorMessage += "\nNot error message"
                        }
                    } else {
                        errorMessage += "\nNo data"
                    }
                    completionHandler(.failure(EbookResultError(message: errorMessage)))
                    return
                }
            }
            guard let data = data else {
                completionHandler(.failure(EbookResultError(message: "No data")))
                return
            }
            var ebookResponse : EbookResponse? = nil
            do {
                ebookResponse = try APIClient.parseResponse(data: data, with: jsonDecoder)
            } catch let error as DecodingError {
                if let ebookResultError = try? jsonDecoder.decode(EbookResultError.self, from: data) {
                    completionHandler(.failure(EbookResultError(message: ebookResultError.message)))
                    return
                }
                if withVerbose {
                    switch error {
                    case .dataCorrupted(let context):
                        completionHandler(.failure(EbookResultError(message: context.debugDescription)))
                    case .keyNotFound(_, let context):
                        completionHandler(.failure(EbookResultError(message: context.debugDescription)))
                    case .typeMismatch(_, let context):
                        completionHandler(.failure(EbookResultError(message: context.debugDescription)))
                    case .valueNotFound(_, let context):
                        completionHandler(.failure(EbookResultError(message: context.debugDescription)))
                    @unknown default:
                        completionHandler(.failure(EbookResultError(message: "unknown error")))
                    }
                }
            } catch let error {
                completionHandler(.failure(EbookResultError(message: error.localizedDescription)))
            }
            guard let ebookResponse = ebookResponse else {
                switch parameter {
                case .keyword(let keyword):
                    completionHandler(.failure(EbookResultError(message: "搜尋「\(keyword)」時發生錯誤。麻煩回報給開發者，謝謝！")))
                case .resultID:
                    completionHandler(.failure(EbookResultError(message: "搜尋連結無法使用")))
                }
                return
            }
            completionHandler(.success(ebookResponse))
        }.resume()
    }
}
