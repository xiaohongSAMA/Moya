import Foundation

/// Used for stubbing responses.
public enum EndpointSampleResponse {

    /// The network returned a response, including status code and data.
    case networkResponse(Int, Data)

    /// The network returned response which can be fully customized.
    case response(HTTPURLResponse, Data)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case networkError(NSError)
}

/// Class for reifying a target of the `Target` enum unto a concrete `Endpoint`.
open class Endpoint<Target> {
    public typealias SampleResponseClosure = () -> EndpointSampleResponse

    open let url: String
    open let method: Moya.Method
    open let sampleResponseClosure: SampleResponseClosure
    open let httpHeaderFields: [String: String]?

    /// Main initializer for `Endpoint`.
    public init(url: String,
                sampleResponseClosure: @escaping SampleResponseClosure,
                method: Moya.Method = Moya.Method.get,
                httpHeaderFields: [String: String]? = nil) {

        self.url = url
        self.sampleResponseClosure = sampleResponseClosure
        self.method = method
        self.httpHeaderFields = httpHeaderFields
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with added HTTP header fields.
    open func adding(newHTTPHeaderFields: [String: String]) -> Endpoint<Target> {
        return adding(httpHeaderFields: newHTTPHeaderFields)
    }

    /// Convenience method for creating a new `Endpoint`, with changes only to the properties we specify as parameters
    open func adding(httpHeaderFields: [String: String]? = nil)  -> Endpoint<Target> {
        let newHTTPHeaderFields = add(httpHeaderFields: httpHeaderFields)
        return Endpoint(url: url, sampleResponseClosure: sampleResponseClosure, method: method, httpHeaderFields: newHTTPHeaderFields)
    }

    fileprivate func add(httpHeaderFields headers: [String: String]?) -> [String: String]? {
        guard let unwrappedHeaders = headers, unwrappedHeaders.isEmpty == false else {
            return self.httpHeaderFields
        }

        var newHTTPHeaderFields = self.httpHeaderFields ?? [:]
        unwrappedHeaders.forEach { key, value in
            newHTTPHeaderFields[key] = value
        }
        return newHTTPHeaderFields
    }
}

/// Extension for converting an `Endpoint` into an optional `URLRequest`.
extension Endpoint {
    /// Returns the `Endpoint` converted to a `URLRequest` if valid. Returns `nil` otherwise.
    public var urlRequest: URLRequest? {
        guard let requestURL = Foundation.URL(string: url) else { return nil }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        return request
    }
}

/// Required for using `Endpoint` as a key type in a `Dictionary`.
extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        return urlRequest?.hashValue ?? url.hashValue
    }

    public static func == <T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
        if lhs.urlRequest != nil, rhs.urlRequest == nil { return false }
        if lhs.urlRequest == nil, rhs.urlRequest != nil { return false }
        if lhs.urlRequest == nil, rhs.urlRequest == nil { return lhs.hashValue == rhs.hashValue }
        return (lhs.urlRequest == rhs.urlRequest)
    }
}