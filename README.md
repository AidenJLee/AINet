# AINet

 선언형으로 네트워크를 비동기로 통신하는 라이브러리.
 원하는 방식을 선언하고 서비스에 넘겨주면 async/await 형태로 반환한다. 

 UI도 NETWORK도 사용자는 그저 필요한 것을 선언할 뿐.  Thats all!

## Requirements

- iOS 15.0 or later
- Swift 5.5 or later


## 설치 방법

### Swift Package Manager(SPM) 설치

`ainet`를 SPM을 통해 설치하려면, 프로젝트의 `Package.swift` 파일에 다음 의존성을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/aidenjlee/ainet.git", from: "1.0.0")
]

Xcode의 File > Add Packages 메뉴를 통해서도 SPM 패키지를 추가할 수 있습니다.

## 사용 예제
기본적인 JSON 요청
다음은 서버로 JSON 데이터를 전송하는 간단한 POST 요청 예제입니다.


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
    let apiClient = AIConnectKit(baseURL: "https://api.example.com")
    let request = APISubmitForm()

    do {
        let response: APIResponse<EmptyResponse> = try await apiClient.dispatch(request)
        print("Form submission success: \(response.isSuccess)")
    } catch {
        print("Error submitting form: \(error)")
    }
}

멀티파트 파일 업로드 요청
다음은 멀티파트 파일을 업로드하는 예제입니다.

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
    let apiClient = AIConnectKit(baseURL: "https://api.example.com")
    let request = APIUploadFile(fileData: data)

    do {
        let response: APIResponse<EmptyResponse> = try await apiClient.dispatch(request)
        print("File upload success: \(response.isSuccess)")
    } catch {
        print("Error uploading file: \(error)")
    }
}

cURL 로깅
라이브러리는 요청을 자동으로 로깅하며, 각 요청에 대한 cURL 명령어를 생성하여 디버깅에 사용할 수 있습니다.


[Request] POST https://api.example.com/api/upload/file
[cURL Command] curl 'https://api.example.com/api/upload/file' -X POST -H 'Authorization: Bearer Token' --data-binary '@file.jpg'

