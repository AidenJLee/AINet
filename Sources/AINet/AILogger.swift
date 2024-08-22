import Foundation

// MARK: - AILogger

public class AILogger {
	private let logLevel: LogLevel

	public init(logLevel: LogLevel = .info) {
		self.logLevel = logLevel
	}

	public func logRequest(_ request: URLRequest) {
		log("[Request] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")", level: .info)
	}

	public func logResponse(_ response: URLResponse, data: Data?) {
		log("[Response] \(response)", level: .info)
		if let data = data {
			log("[Response Data] \(String(data: data, encoding: .utf8) ?? "")", level: .verbose)
		}
	}

	public func logCurlCommand(_ request: URLRequest) {
		let curlCommand = toCurlCommand(request)
		log("[cURL Command] \(curlCommand)", level: .verbose)
	}

	// cURL 명령어 생성
	private func toCurlCommand(_ request: URLRequest) -> String {
		guard let url = request.url else { return "" }
		var curlCommand = "curl '\(url.absoluteString)'"

		// HTTP Method
		if let method = request.httpMethod, method != "GET" {
			curlCommand += " -X \(method)"
		}

		// Headers
		if let headers = request.allHTTPHeaderFields {
			for (key, value) in headers {
				curlCommand += " -H '\(key): \(value)'"
			}
		}

		// Body
		if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
			curlCommand += " --data '\(bodyString)'"
		}

		return curlCommand
	}

	private func log(_ message: String, level: LogLevel) {
		guard level.rawValue >= logLevel.rawValue else { return }
		print(message)
	}
}

public enum LogLevel: Int {
	case verbose = 0
	case info = 1
	case warning = 2
	case error = 3
}
