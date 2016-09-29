import Quick
import Nimble
import Moya
import Result

final class NetworkLogginPluginSpec: QuickSpec {
    override func spec() {

        var log = ""
        let plugin = NetworkLoggerPlugin(verbose: true, output: { printing in
            //mapping the Any... from items to a string that can be compared
            let stringArray: [String] = printing.2.map { $0 as? String }.flatMap { $0 }
            let string: String = stringArray.reduce("") { $0 + $1 + " " }
            log += string
        })

        let pluginWithCurl = NetworkLoggerPlugin(verbose: true, cURL: true, output: { printing in
            //mapping the Any... from items to a string that can be compared
            let stringArray: [String] = printing.2.map { $0 as? String }.flatMap { $0 }
            let string: String = stringArray.reduce("") { $0 + $1 + " " }
            log += string
        })

        let pluginWithResponseDataFormatter = NetworkLoggerPlugin(verbose: true, output: { printing in
            //mapping the Any... from items to a string that can be compared
            let stringArray: [String] = printing.2.map { $0 as? String }.flatMap { $0 }
            let string: String = stringArray.reduce("") { $0 + $1 + " " }
            log += string
            }, responseDataFormatter: { _ in
                return "formatted body".data(using: .utf8)!
        })

        beforeEach {
            log = ""
        }

        it("outputs all request fields with body") {

            plugin.willSendRequest(TestBodyRequest(), target: GitHub.zen)

            expect(log).to( contain("Request: https://api.github.com/zen") )
            expect(log).to( contain("Request Headers: [\"Content-Type\": \"application/json\"]") )
            expect(log).to( contain("HTTP Request Method: GET") )
            expect(log).to( contain("Request Body: cool body") )
        }

        it("outputs all request fields with stream") {

            plugin.willSendRequest(TestStreamRequest(), target: GitHub.zen)

            expect(log).to( contain("Request: https://api.github.com/zen") )
            expect(log).to( contain("Request Headers: [\"Content-Type\": \"application/json\"]") )
            expect(log).to( contain("HTTP Request Method: GET") )
            expect(log).to( contain("Request Body Stream:") )
        }

        it("will output invalid request when reguest is nil") {

            plugin.willSendRequest(TestNilRequest(), target: GitHub.zen)

            expect(log).to( contain("Request: (invalid request)") )
        }

        it("outputs the response data") {
            let response = Response(statusCode: 200, data: "cool body".data(using: .utf8)!, response: URLResponse(url: URL(string: url(GitHub.zen))!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, Moya.Error> = .success(response)

            plugin.didReceiveResponse(result, target: GitHub.zen)

            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("cool body") )
        }

        it("outputs the formatted response data") {
            let response = Response(statusCode: 200, data: "cool body".data(using: .utf8)!, response: URLResponse(url: URL(string: url(GitHub.zen))!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, Moya.Error> = .success(response)

            pluginWithResponseDataFormatter.didReceiveResponse(result, target: GitHub.zen)

            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("formatted body") )
        }

        it("outputs an empty reponse message") {
            let response = Response(statusCode: 200, data: "cool body".data(using: .utf8)!, response: nil)
            let result: Result<Moya.Response, Moya.Error> = .failure(Moya.Error.data(response))

            plugin.didReceiveResponse(result, target: GitHub.zen)

            expect(log).to( contain("Response: Received empty network response for zen.") )
        }

        it("outputs cURL representation of request") {

            pluginWithCurl.willSendRequest(TestCurlBodyRequest(), target: GitHub.zen)
            print(log)

            expect(log).to( contain("$ curl -i") )
            expect(log).to( contain("-H \"Content-Type: application/json\"") )
            expect(log).to( contain("-d \"cool body\"") )
            expect(log).to( contain("\"https://api.github.com/zen\"") )

        }
    }
}

private class TestStreamRequest: RequestType {
    var request: URLRequest? {
        var r = URLRequest(url: URL(string: url(GitHub.zen))!)
        r.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        r.httpBodyStream = InputStream(data: "cool body".data(using: .utf8)!)

        return r
    }

    func authenticate(user: String, password: String, persistence: URLCredential.Persistence) -> Self {
        return self
    }

    func authenticate(usingCredential credential: URLCredential) -> Self {
        return self
    }
}

private class TestBodyRequest: RequestType {
    var request: URLRequest? {
        var r = URLRequest(url: URL(string: url(GitHub.zen))!)
        r.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        r.httpBody = "cool body".data(using: .utf8)

        return r
    }

    func authenticate(user: String, password: String, persistence: URLCredential.Persistence) -> Self {
        return self
    }

    func authenticate(usingCredential credential: URLCredential) -> Self {
        return self
    }
}

private class TestCurlBodyRequest: RequestType, CustomDebugStringConvertible {
    var request: URLRequest? {
        var r = URLRequest(url: URL(string: url(GitHub.zen))!)
        r.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        r.httpBody = "cool body".data(using: .utf8)

        return r
    }

    func authenticate(user: String, password: String, persistence: URLCredential.Persistence) -> Self {
        return self
    }

    func authenticate(usingCredential credential: URLCredential) -> Self {
        return self
    }

    var debugDescription: String {
        return ["$ curl -i", "-H \"Content-Type: application/json\"", "-d \"cool body\"","\"https://api.github.com/zen\""].joined(separator: " \\\n\t")
    }
}

private class TestNilRequest: RequestType {
    var request: URLRequest? {
        return nil
    }

    func authenticate(user: String, password: String, persistence: URLCredential.Persistence) -> Self {
        return self
    }

    func authenticate(usingCredential credential: URLCredential) -> Self {
        return self
    }
}