
# AINet

**AINet**는 선언형 방식으로 네트워크 통신을 비동기적으로 처리하는 Swift 라이브러리입니다. 원하는 요청 방식을 선언하고 서비스에 넘겨주면 `async/await` 형태로 결과를 반환합니다. 사용자는 그저 필요한 네트워크 요청을 선언만 하면 됩니다.

**UI도 NETWORK도 사용자는 그저 필요한 것을 선언할 뿐입니다. That's all!**

## Requirements

- iOS 15.0 or later
- Swift 5.5 or later

## 설치 방법

### Swift Package Manager(SPM) 설치

`AINet`를 SPM을 통해 설치하려면, 프로젝트의 `Package.swift` 파일에 다음 의존성을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/aidenjlee/ainet.git", from: "1.0.0")
]
```

또는 Xcode의 `File > Add Packages` 메뉴를 통해 SPM 패키지를 추가할 수 있습니다.

## 사용 예제

### 기본적인 JSON 요청

다음은 서버로 JSON 데이터를 전송하는 간단한 `POST` 요청 예제입니다.

```swift
import AINet

struct APISubmitForm: AIRequest {
    typealias ReturnType = APIResponse<EmptyResponse>
    
    let path = "/api/submit/form"
    let method: HTTPMethod = .POST

    var defaultHeaders: HTTPHeaders {
        return ["Authorization": "Bearer Token"]
    }

    var bodyParams: Params? {
        return ["name": "John Doe", "age": 30, "email": "john.doe@example.com"]
    }
}

@available(iOS 15.0, *)
func submitForm() async {
    let apiClient = AINet(baseURL: "https://api.example.com")
    let request = APISubmitForm()

    do {
        let response: APIResponse<EmptyResponse> = try await apiClient.dispatch(request)
        print("Form submission success: \(response.isSuccess)")
    } catch {
        print("Error submitting form: \(error)")
    }
}
```

### 멀티파트 파일 업로드 요청

다음은 멀티파트 파일을 업로드하는 예제입니다.

```swift
import AINet

struct APIUploadFile: AIRequest {
    typealias ReturnType = APIResponse<EmptyResponse>
    
    let path = "/api/upload/file"
    let method: HTTPMethod = .POST
    let fileData: Data

    var defaultHeaders: HTTPHeaders {
        return ["Authorization": "Bearer Token"]
    }

    var multipartData: [MultipartFormData]? {
        return [MultipartFormData(name: "file", fileName: "file.jpg", mimeType: "image/jpeg", data: fileData)]
    }

    var bodyParams: Params? {
        return nil
    }
}

@available(iOS 15.0, *)
func uploadFile(data: Data) async {
    let apiClient = AINet(baseURL: "https://api.example.com")
    let request = APIUploadFile(fileData: data)

    do {
        let response: APIResponse<EmptyResponse> = try await apiClient.dispatch(request)
        print("File upload success: \(response.isSuccess)")
    } catch {
        print("Error uploading file: \(error)")
    }
}
```

### cURL 로깅

`AINet`는 모든 요청을 자동으로 로깅하며, 디버깅을 위해 각 요청에 대한 cURL 명령어를 생성합니다.

```
[Request] POST https://api.example.com/api/upload/file
[cURL Command] curl 'https://api.example.com/api/upload/file' -X POST -H 'Authorization: Bearer Token' --data-binary '@file.jpg'
```

## 고급 기능

### 에러 처리

`AINet`는 네트워크 에러를 상세하게 처리할 수 있도록 `NetworkRequestError`를 제공합니다. 다양한 HTTP 상태 코드와 URLSession 에러를 쉽게 구분하고 처리할 수 있습니다.

```swift
do {
    let response: APIResponse<EmptyResponse> = try await apiClient.dispatch(request)
    // 성공 처리
} catch let error as NetworkRequestError {
    switch error {
    case .clientError(let statusCode, _):
        print("Client error occurred: \(statusCode)")
    case .serverError(let statusCode, _):
        print("Server error occurred: \(statusCode)")
    case .urlSessionError(let urlError):
        print("Network issue: \(urlError.localizedDescription)")
    default:
        print("Unexpected error: \(error)")
    }
} catch {
    print("Unknown error: \(error.localizedDescription)")
}
```

### 헤더 병합

`AINet`는 기본 헤더와 추가 헤더를 병합하는 기능을 제공합니다. 예를 들어, 기본적으로 설정된 헤더 외에 각 요청에 특정한 헤더를 추가할 수 있습니다.

```swift
extension AIRequest {
 var defaultHeaders: HTTPHeaders {
     return ["Authorization": "Bearer DefaultToken"]
 }

 var headerParams: HTTPHeaders? {
     return ["Custom-Header": "Value"]
 }
}
```

기본 헤더와 추가 헤더가 병합되어 최종 요청 시 설정됩니다.

### 타임아웃 및 네트워크 설정

`URLSession`의 설정을 커스터마이즈하고 싶은 경우, AINet에서 사용 중인 `URLSession`을 교체하거나, 커스텀 구성(`URLSessionConfiguration`)을 적용할 수 있습니다.

```swift
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30 // 30초 타임아웃
let customSession = URLSession(configuration: configuration)
```

## FAQ

### Q1: cURL 명령어는 어떻게 로깅되나요?

요청이 발생할 때 자동으로 cURL 명령어가 로그로 출력됩니다. 이 명령어는 네트워크 요청의 디버깅에 매우 유용합니다.

### Q2: 멀티파트 업로드가 실패하는 이유는 무엇인가요?

멀티파트 요청에서 `Content-Type` 헤더가 누락되거나 잘못된 형식일 경우 업로드가 실패할 수 있습니다. 서버의 요구 사항을 다시 한번 확인해 주세요.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
```
