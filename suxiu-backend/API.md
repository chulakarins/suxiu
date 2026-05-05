# API 接口文档

## 基础信息

- **Base URL**: `http://localhost:8000` (开发环境)
- **生产 URL**: `https://api.suxiu-ai.com` (部署后)
- **认证方式**: JWT Bearer Token
- **响应格式**: JSON

## 统一响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": {},
  "request_id": "xxx"
}
```

## 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 1001 | 参数错误 |
| 1002 | 认证失败 |
| 1003 | 权限不足 |
| 1004 | 资源不存在 |
| 2001 | AI 服务调用失败 |
| 2002 | 生成超时 |
| 3001 | 数据库错误 |
| 4002 | 订单不存在 |

---

## 1. 认证接口

### 1.1 用户注册

```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "username": "zhangsan",
  "password": "password123",
  "phone": "13800138000",
  "email": "zhangsan@example.com"
}
```

**响应：**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "user_id": "usr_xxx",
    "username": "zhangsan",
    "access_token": "eyJhbGc...",
    "refresh_token": "eyJhbGc...",
    "token_type": "bearer",
    "expires_in": 86400
  }
}
```

### 1.2 用户登录

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "zhangsan",
  "password": "password123"
}
```

**响应：** 同注册

### 1.3 获取当前用户信息

```http
GET /api/v1/auth/me
Authorization: Bearer <access_token>
```

---

## 2. 设计接口

### 2.1 生成 AI 设计

```http
POST /api/v1/design/generate
Authorization: Bearer <token>
Content-Type: application/json

{
  "prompt": "一只在花园里的猫咪",
  "style": "traditional",
  "size": "1280*1280",
  "reference_image_urls": [],
  "color_preferences": ["红色", "金色"]
}
```

**响应：**
```json
{
  "code": 0,
  "data": {
    "task_id": "task_xxx",
    "design_id": "design_xxx",
    "status": "pending",
    "estimated_time": 30
  }
}
```

### 2.2 查询任务状态

```http
GET /api/v1/design/task/{task_id}
Authorization: Bearer <token>
```

**响应：**
```json
{
  "code": 0,
  "data": {
    "task_id": "task_xxx",
    "status": "succeeded",
    "progress": 100,
    "result": {
      "image_url": "https://oss.../xxx.jpg",
      "design_id": "design_xxx"
    }
  }
}
```

### 2.3 获取设计详情

```http
GET /api/v1/design/{design_id}
Authorization: Bearer <token>
```

### 2.4 获取设计列表

```http
GET /api/v1/designs?offset=0&limit=20&status=succeeded
Authorization: Bearer <token>
```

---

## 3. 订单接口

### 3.1 创建订单

```http
POST /api/v1/order/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "design_id": "design_xxx",
  "product_type": "framed",
  "shipping_address": {
    "name": "张三",
    "phone": "13800138000",
    "province": "江苏省",
    "city": "苏州市",
    "district": "姑苏区",
    "address": "XX 路 XX 号"
  }
}
```

**响应：**
```json
{
  "code": 0,
  "data": {
    "order_id": "ord_xxx",
    "status": "pending_payment",
    "pricing": {
      "design_fee": 50,
      "material_cost": 200,
      "labor_cost": 500,
      "shipping_cost": 20,
      "total": 770,
      "currency": "CNY"
    },
    "payment_url": "https://..."
  }
}
```

### 3.2 获取订单详情

```http
GET /api/v1/order/{order_id}
Authorization: Bearer <token>
```

### 3.3 获取订单列表

```http
GET /api/v1/orders?offset=0&limit=20
Authorization: Bearer <token>
```

### 3.4 取消订单

```http
POST /api/v1/order/{order_id}/cancel
Authorization: Bearer <token>
Content-Type: application/json

{
  "reason": "不想要了"
}
```

### 3.5 跟踪订单

```http
GET /api/v1/order/{order_id}/track
Authorization: Bearer <token>
```

---

## 4. 工厂接口

### 4.1 获取工厂列表

```http
GET /api/v1/factory/list?style=traditional
Authorization: Bearer <token>
```

### 4.2 获取工厂详情

```http
GET /api/v1/factory/{factory_id}
Authorization: Bearer <token>
```

---

## 5. 上传接口

### 5.1 获取 OSS 上传凭证

```http
GET /api/v1/upload/oss-token
Authorization: Bearer <token>
```

**响应：**
```json
{
  "code": 0,
  "data": {
    "access_key_id": "STS.xxx",
    "bucket": "suxiu-ai-user-upload",
    "endpoint": "oss-cn-hangzhou.aliyuncs.com",
    "host": "https://...",
    "expiration": 1712131200
  }
}
```

---

## Swift 调用示例

```swift
import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:8000"
    private var accessToken: String?
    
    // 设置 Token
    func setToken(_ token: String?) {
        self.accessToken = token
    }
    
    // 通用请求方法
    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Codable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - API 方法
    
    // 登录
    func login(username: String, password: String) async throws -> LoginResponse {
        let body = LoginRequest(username: username, password: password)
        return try await request("/api/v1/auth/login", method: "POST", body: body)
    }
    
    // 生成设计
    func generateDesign(prompt: String, style: String = "traditional") async throws -> DesignGenerateResponse {
        let body = DesignGenerateRequest(prompt: prompt, style: style)
        return try await request("/api/v1/design/generate", method: "POST", body: body)
    }
    
    // 查询任务状态
    func getTaskStatus(taskId: String) async throws -> TaskStatusResponse {
        return try await request("/api/v1/design/task/\(taskId)")
    }
    
    // 获取设计列表
    func getDesigns() async throws -> DesignListResponse {
        return try await request("/api/v1/designs")
    }
}

// 请求/响应模型
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let code: Int
    let data: LoginData
}

struct LoginData: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
}

struct DesignGenerateRequest: Codable {
    let prompt: String
    let style: String
    let size: String = "1280*1280"
    let reference_image_urls: [String] = []
    let color_preferences: [String] = []
}

struct DesignGenerateResponse: Codable {
    let code: Int
    let data: DesignGenerateData
}

struct DesignGenerateData: Codable {
    let task_id: String
    let design_id: String
    let status: String
}

struct TaskStatusResponse: Codable {
    let code: Int
    let data: TaskStatusData
}

struct TaskStatusData: Codable {
    let status: String
    let progress: Int
    let result: TaskResult?
}

struct TaskResult: Codable {
    let image_url: String
}

struct DesignListResponse: Codable {
    let code: Int
    let data: DesignListData
}

struct DesignListData: Codable {
    let total: Int
    let designs: [DesignItem]
}

struct DesignItem: Codable {
    let design_id: String
    let prompt: String
    let status: String
    let image_url: String?
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodeError
}
```
