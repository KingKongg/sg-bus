import XCTest
@testable import SGBus

private class URLCapture: URLProtocol {
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        lastRequest = request
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let json = """
        {"BusStopCode":"01012","Services":[]}
        """.data(using: .utf8)!
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: json)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class LTAClientTests: XCTestCase {

    private func makeClient() -> LTAClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLCapture.self]
        return LTAClient(apiKey: "test-key", sessionConfiguration: config)
    }

    func testBusArrivalURLUsesV3Endpoint() async throws {
        let client = makeClient()
        URLCapture.lastRequest = nil

        _ = try await client.fetchBusArrivals(stopCode: "01012")

        let url = try XCTUnwrap(URLCapture.lastRequest?.url)
        XCTAssertTrue(url.path.contains("/v3/BusArrival"), "URL should use v3 endpoint, got: \(url)")
        XCTAssertTrue(url.absoluteString.contains("BusStopCode=01012"))
    }

    func testBusArrivalURLIncludesServiceNo() async throws {
        let client = makeClient()
        URLCapture.lastRequest = nil

        _ = try await client.fetchBusArrivals(stopCode: "01012", serviceNo: "36")

        let url = try XCTUnwrap(URLCapture.lastRequest?.url)
        XCTAssertTrue(url.absoluteString.contains("ServiceNo=36"))
    }

    func testAccountKeyHeader() async throws {
        let client = makeClient()
        URLCapture.lastRequest = nil

        _ = try await client.fetchBusArrivals(stopCode: "01012")

        let key = URLCapture.lastRequest?.value(forHTTPHeaderField: "AccountKey")
        XCTAssertEqual(key, "test-key")
    }
}
