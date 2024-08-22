// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation

// MARK: - AIRequest Protocol

public protocol AIRequest {
	associatedtype ReturnType: Codable
	var path: String { get }
	var method: HTTPMethod { get }
	var contentType: HTTPContentType { get }

	// 기본 헤더 및 바디 파라미터 프로퍼티
	var defaultHeaders: HTTPHeaders { get }
	var defaultBodyParams: Params { get }

	// 요청 시 추가할 헤더나 바디 파라미터
	var headerParams: HTTPHeaders? { get }
	var bodyParams: Params? { get }
	var multipartData: [MultipartFormData]? { get } // 멀티파트 데이터
}

public extension AIRequest {
	var method: HTTPMethod { return .GET }
	var contentType: HTTPContentType { return .json }
	var headerParams: HTTPHeaders? { return nil }
	var bodyParams: Params?  { return nil }
	var multipartData: [MultipartFormData]?  { return nil }
	
	// 병합된 최종 헤더
	var mergedHeaders: HTTPHeaders {
		var merged = defaultHeaders
		if let additionalHeaders = headerParams {
			merged.merge(additionalHeaders) { (_, new) in new }
		}
		return merged
	}

	// 병합된 최종 바디 파라미터
	var mergedBodyParams: Params {
		var merged = defaultBodyParams
		if let additionalParams = bodyParams {
			merged.merge(additionalParams) { (_, new) in new }
		}
		return merged
	}

	// 기본적으로 body는 mergedBodyParams로 생성됨 (멀티파트 데이터 포함)
	func createBody(withBoundary boundary: String? = nil) -> Data? {
		switch contentType {
		case .json:
			return try? JSONSerialization.data(withJSONObject: mergedBodyParams, options: [])
		case .urlEncoded:
			let queryString = mergedBodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
			return queryString.data(using: .utf8)
		case .multipart:
			guard let boundary = boundary else { return nil }
			return createMultipartBody(withBoundary: boundary)
		}
	}

	// 멀티파트 바디 생성
	func createMultipartBody(withBoundary boundary: String) -> Data? {
		guard let multipartData = multipartData else { return nil }

		var body = Data()

		for part in multipartData {
			body.append("--\(boundary)\r\n".data(using: .utf8)!)
			body.append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(part.fileName)\"\r\n".data(using: .utf8)!)
			body.append("Content-Type: \(part.mimeType)\r\n\r\n".data(using: .utf8)!)
			body.append(part.data)
			body.append("\r\n".data(using: .utf8)!)
		}

		body.append("--\(boundary)--\r\n".data(using: .utf8)!)
		return body
	}
}

// MARK: - HTTP Method and Content Type

public enum HTTPMethod: String {
	case GET, POST, PUT, DELETE
}

public enum HTTPContentType: String {
	case json = "application/json"
	case urlEncoded = "application/x-www-form-urlencoded"
	case multipart = "multipart/form-data"

	var headerValue: String {
		return self.rawValue
	}
}

// MARK: - Utility Types

public typealias HTTPParams = [String: Any]
public typealias Params = HTTPParams
public typealias HTTPHeaders = [String: String]

public struct MultipartFormData {
	let name: String
	let fileName: String
	let mimeType: String
	let data: Data

	public init(name: String, fileName: String, mimeType: String, data: Data) {
		self.name = name
		self.fileName = fileName
		self.mimeType = mimeType
		self.data = data
	}
}

// MARK: - AINet

@available(iOS 15.0, *)
public struct AINet {
	public var baseURL: String
	private let logger: AILogger

	public init(baseURL: String, logLevel: LogLevel = .info) {
		self.baseURL = baseURL
		self.logger = AILogger(logLevel: logLevel)
	}

	// 비동기 API 호출 메서드
	public func dispatch<Request: AIRequest>(_ request: Request) async throws -> Request.ReturnType {
		guard let urlRequest = prepareURLRequest(for: request) else {
			throw NetworkRequestError.invalidRequest
		}

		logger.logRequest(urlRequest)
		logger.logCurlCommand(urlRequest)

		do {
			let (data, response) = try await URLSession.shared.data(for: urlRequest)
			logger.logResponse(response, data: data)
			return try processResponse(data: data, response: response, decoder: JSONDecoder())
		} catch let error as URLError {
			throw NetworkRequestError.urlSessionError(error)
		} catch {
			throw NetworkRequestError.unknownError
		}
	}

	// URLRequest 준비
	private func prepareURLRequest<Request: AIRequest>(for request: Request) -> URLRequest? {
		guard var components = URLComponents(string: baseURL + request.path) else { return nil }

		// GET 요청일 경우 쿼리 파라미터를 URL에 추가
		if request.method == .GET, let queryParams = request.bodyParams {
			components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
		}

		guard let url = components.url else { return nil }
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = request.method.rawValue

		// 헤더 설정
		request.mergedHeaders.forEach { key, value in
			urlRequest.addValue(value, forHTTPHeaderField: key)
		}

		// POST, PUT 등 바디 요청일 경우 바디 설정
		if request.method != .GET {
			if request.contentType == .multipart {
				let boundary = "Boundary-\(UUID().uuidString)"
				urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
				urlRequest.httpBody = request.createBody(withBoundary: boundary)
			} else {
				urlRequest.setValue(request.contentType.headerValue, forHTTPHeaderField: "Content-Type")
				urlRequest.httpBody = request.createBody()
			}
		}

		return urlRequest
	}

	// 응답 처리
	private func processResponse<ReturnType: Codable>(data: Data?, response: URLResponse?, decoder: JSONDecoder) throws -> ReturnType {
		guard let httpResponse = response as? HTTPURLResponse else {
			throw NetworkRequestError.unknownError
		}

		switch httpResponse.statusCode {
		case 200...299:
			guard let data = data else {
				throw NetworkRequestError.noData
			}
			do {
				return try decoder.decode(ReturnType.self, from: data)
			} catch {
				throw NetworkRequestError.decodingError(error)
			}

		case 400...499:
			throw NetworkRequestError.clientError(statusCode: httpResponse.statusCode, data: data)

		case 500...599:
			throw NetworkRequestError.serverError(statusCode: httpResponse.statusCode, data: data)

		default:
			throw NetworkRequestError.unknownError
		}
	}
}
// MARK: - NetworkRequestError

public enum NetworkRequestError: LocalizedError {
	case invalidRequest
	case clientError(statusCode: Int, data: Data?)
	case serverError(statusCode: Int, data: Data?)
	case noData
	case decodingError(Error)
	case urlSessionError(URLError)
	case unknownError

	public var errorDescription: String? {
		switch self {
		case .invalidRequest:
			return "Invalid request."
		case .clientError(let statusCode, _):
			return "Client error: \(statusCode)"
		case .serverError(let statusCode, _):
			return "Server error: \(statusCode)"
		case .noData:
			return "No data received."
		case .decodingError(let error):
			return "Decoding error: \(error.localizedDescription)"
		case .urlSessionError(let error):
			return "Network error: \(error.localizedDescription)"
		case .unknownError:
			return "An unknown error occurred."
		}
	}
}
