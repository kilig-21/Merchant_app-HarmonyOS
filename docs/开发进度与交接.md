# HarmonyOS App 后端接口对接文档

> 适用项目：`Merchant_AI_Operation`
>
> 后端基线：`feature/web-v2` 分支，提交 `f5ca396`（2026-09-09）
>
> 调用方：HarmonyOS 原生 ArkTS App
>
> 说明：本文以当前后端 Controller、DTO、VO 为准。当前接口尚未增加 `/api/v1` 版本前缀。

## 1. 对接范围与结论

鸿蒙 App 直接调用 Spring Boot 后端，不经过 Next.js 网页代理：

```text
HarmonyOS 页面
  -> Api 类
  -> HttpClient
  -> Spring Boot /api/**
  -> MySQL / Redis / RabbitMQ
```

当前可以完成消费者端主流程：

```text
注册/登录 -> 浏览店铺和商品 -> 购物车 -> 地址 -> 跨店结算
-> 订单查询/取消 -> 售后 -> 限量促销抢购
```

当前不能作为正式生产能力使用的部分：

- `mock-pay` 只是模拟支付，不是真实支付。
- 商品接口暂时没有正式商品图片字段和上传接口。
- 没有 Refresh Token、服务端退出登录和设备会话管理。
- 没有发货、物流、确认收货和真实退款接口。
- `/api/debug/**` 仅供开发调试，App 不应调用。

## 2. 环境地址

统一在 App 中维护一个 `BASE_URL`，不要在每个页面写死地址。

| 环境 | 示例 | 说明 |
|---|---|---|
| 本机接口工具 | `http://127.0.0.1:8080` | 只适用于同一台电脑上的 curl/ApiFox |
| 真机局域网联调 | `http://192.168.1.100:8080` | 替换成后端电脑的局域网 IPv4 |
| 正式环境 | `https://api.example.com` | 必须使用可信 HTTPS 域名 |

手机上的 `127.0.0.1` 和 `localhost` 指向手机本身，不是运行 Spring Boot 的电脑。

真机联调还需要确认：

1. 手机和电脑连接同一局域网。
2. Spring Boot 对局域网网卡监听，而不是只监听回环地址。
3. Windows 防火墙允许后端端口。
4. App 的 `entry/src/main/module.json5` 已声明网络权限：

```json5
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET"
  }
]
```

## 3. 通用请求规范

### 3.1 请求头

公开接口：

```http
Content-Type: application/json
Accept: application/json
```

登录后接口：

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <accessToken>
```

结算等幂等接口还需要：

```http
Idempotency-Key: <客户端生成的唯一字符串>
```

### 3.2 统一响应结构

所有接口的响应体都是：

```ts
export interface ApiResponse<T> {
  code: number
  message: string
  data: T | null
}
```

成功示例：

```json
{
  "code": 0,
  "message": "ok",
  "data": {}
}
```

失败示例：

```json
{
  "code": 401,
  "message": "请先登录",
  "data": null
}
```

客户端必须同时判断 HTTP 状态和响应体 `code`：

```ts
if (httpStatus < 200 || httpStatus >= 300 || body.code !== 0) {
  throw new Error(body.message)
}
```

当前错误码约定：

| code | 含义 | App 行为 |
|---:|---|---|
| `0` | 成功 | 使用 `data` |
| `400` | 参数或 JSON 错误 | 在表单附近显示 `message` |
| `401` | 未登录、/Token 无效或过期 | 清理本地 Token，跳登录页 |
| `403` | 角色或资源权限不足 | 显示无权限，不要循环重试 |
| `404` | 资源不存在 | 返回上一页或展示空状态 |
| `405` | HTTP 方法错误 | 检查 GET/POST/PUT/DELETE |
| `409` | 库存、状态、幂等等业务冲突 | 显示提示并刷新相关数据 |
| `500` | 后端异常 | 展示通用错误并允许手动重试 |

注意：当前部分参数校验异常的响应体 `code` 是 `400/403/405/500`，但 HTTP 状态仍可能是 `200`，因此不能只判断 HTTP 状态。

### 3.3 数据类型

| Java 类型 | ArkTS 建议类型 | 说明 |
|---|---|---|
| `Long` | `number` | 当前 ID 可按 number 使用；若未来改为超大雪花 ID，应让后端按字符串返回 |
| `Integer` | `number` | 数量、库存 |
| `BigDecimal` | `number` 或 `string` | 金额严禁用浮点数自行计算订单总价，以后端为准 |
| `LocalDate` | `string` | 示例：`2026-09-09` |
| `LocalDateTime` | `string` | 示例：`2026-09-09T15:30:00` |
| `List<T>` | `T[]` | 数组 |

## 4. 鉴权和 Token

后端使用 JWT Bearer Token。Token 当前有效期为 2 小时。

推荐流程：

```text
POST /api/auth/login
  -> 保存 data.accessToken
  -> 保存 data.user
  -> 后续请求自动添加 Authorization
  -> App 启动时调用 GET /api/auth/me 校验会话
  -> 收到 401 后删除 Token 并跳转登录页
```

当前没有 Refresh Token。Token 过期后只能重新登录。

开发期可以使用 Preferences 保存 Token；正式版本应评估 HUKS 或加密存储，不要把 Token 写入日志、源码或普通页面状态快照。

## 5. ArkTS 网络层参考

建议目录：

```text
entry/src/main/ets
├─ network
│  ├─ HttpClient.ets
│  └─ ApiError.ets
├─ api
│  ├─ AuthApi.ets
│  ├─ StoreApi.ets
│  ├─ ProductApi.ets
│  ├─ CartApi.ets
│  ├─ AddressApi.ets
│  ├─ CheckoutApi.ets
│  ├─ OrderApi.ets
│  ├─ PromotionApi.ets
│  └─ AfterSaleApi.ets
└─ model
   └─ 各业务响应模型
```

最小网络封装示意：

```ts
import { http } from '@kit.NetworkKit'

export interface ApiResponse<T> {
  code: number
  message: string
  data: T | null
}

const BASE_URL: string = 'http://192.168.1.100:8080'

export class HttpClient {
  static accessToken: string = ''

  static async request<T>(
    path: string,
    method: http.RequestMethod,
    body?: object,
    extraHeaders?: Record<string, string>
  ): Promise<T> {
    const request = http.createHttp()
    const headers: Record<string, string> = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...extraHeaders
    }

    if (HttpClient.accessToken.length > 0) {
      headers['Authorization'] = `Bearer ${HttpClient.accessToken}`
    }

    try {
      const response = await request.request(`${BASE_URL}${path}`, {
        method,
        header: headers,
        extraData: body === undefined ? undefined : JSON.stringify(body),
        connectTimeout: 10000,
        readTimeout: 15000
      })

      const text = String(response.result)
      const envelope = JSON.parse(text) as ApiResponse<T>
      if (response.responseCode < 200 || response.responseCode >= 300 || envelope.code !== 0) {
        throw new Error(envelope.message || `请求失败：${response.responseCode}`)
      }
      return envelope.data as T
    } finally {
      request.destroy()
    }
  }
}
```

说明：这是网络层结构参考。不同 DevEco Studio/SDK 版本对 ArkTS 严格类型检查可能略有差异，应以当前 SDK 的 `http.HttpRequestOptions` 类型提示为准。

## 6. 推荐实现顺序

1. `GET /api/ping` 验证手机能访问电脑后端。
2. 注册、登录、`/api/auth/me`。
3. 店铺列表、商品搜索、商品详情。
4. 购物车。
5. 收货地址。
6. 原子结算 `/api/checkouts`。
7. 订单列表、详情和取消。
8. 售后。
9. 限量促销。
10. 最后再做商家端功能。

---

# 第一部分：公共和认证接口

## 7. 服务连通测试

### `GET /api/ping`

- 权限：公开
- 用途：只用于开发期确认网络是否连通
- 请求体：无

成功响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": "pong"
}
```

## 8. 用户注册

### `POST /api/auth/register`

- 权限：公开
- 注册用户类型：`CONSUMER`

请求：

```json
{
  "username": "consumer001",
  "password": "123456"
}
```

校验：

- `username`：3～64 个字符，不能为空。
- `password`：6～32 个字符，不能为空。

返回 `data`：

```json
{
  "id": 10001,
  "username": "consumer001",
  "userType": "CONSUMER",
  "tenantId": null
}
```

注意：注册成功不会返回 Token。App 应在注册成功后调用登录接口。

## 9. 用户登录

### `POST /api/auth/login`

- 权限：公开

请求：

```json
{
  "username": "consumer001",
  "password": "123456"
}
```

返回 `data`：

```json
{
  "accessToken": "eyJ...",
  "user": {
    "id": 10001,
    "username": "consumer001",
    "userType": "CONSUMER",
    "tenantId": null
  }
}
```

`userType` 当前可能值：

- `CONSUMER`：消费者。
- `MERCHANT_ADMIN`：商家管理员。
- `MERCHANT_OPERATOR`：商家操作员。

## 10. 获取当前用户

### `GET /api/auth/me`

- 权限：已登录
- Header：`Authorization: Bearer <accessToken>`

返回字段：`id`、`username`、`userType`、`tenantId`。

---

# 第二部分：公开商城接口

## 11. 店铺列表

### `GET /api/public/stores`

- 权限：公开
- 参数：无

返回 `data`：

```json
[
  {
    "id": 1001,
    "name": "示例店铺",
    "productCount": 12
  }
]
```

## 12. 跨店搜索商品

### `GET /api/public/stores/products/search`

- 权限：公开

Query 参数：

| 参数 | 必填 | 说明 |
|---|---|---|
| `keyword` | 否 | 商品关键词 |
| `storeId` | 否 | 限定店铺 |
| `page` | 否 | 页码，从 `1` 开始 |
| `size` | 否 | 每页数量，后端会限制最大值 |

示例：

```http
GET /api/public/stores/products/search?keyword=咖啡&storeId=1001&page=1&size=20
```

返回单项：

```json
{
  "storeId": 1001,
  "storeName": "示例店铺",
  "id": 2001,
  "name": "手冲咖啡",
  "description": "商品描述",
  "minSalePrice": 29.90,
  "totalAvailableStock": 100,
  "updatedAt": "2026-09-09T15:30:00"
}
```

当前返回的是数组，没有 `total/hasMore`。

## 13. 店铺商品列表

### `GET /api/public/stores/{storeId}/products`

Query 参数：`page`、`size`，均可选。

返回单项：

```json
{
  "id": 2001,
  "name": "手冲咖啡",
  "description": "商品描述",
  "minSalePrice": 29.90,
  "totalAvailableStock": 100,
  "updatedAt": "2026-09-09T15:30:00"
}
```

## 14. 商品详情

### `GET /api/public/stores/{storeId}/products/{spuId}`

返回：

```json
{
  "id": 2001,
  "name": "手冲咖啡",
  "description": "商品描述",
  "updatedAt": "2026-09-09T15:30:00",
  "skus": [
    {
      "id": 3001,
      "skuName": "250g",
      "salePrice": 29.90,
      "availableStock": 100
    }
  ]
}
```

当前没有图片字段，App 初期需使用本地占位图，不能自己拼造远程图片地址。

## 15. SKU 可购买状态

### `GET /api/public/skus/{skuId}/availability`

返回：

```json
{
  "skuId": 3001,
  "purchasable": true,
  "availableStock": 100,
  "message": "可购买"
}
```

加入购物车或提交订单前可刷新该接口，但最终库存判断仍以后端写接口为准。

## 16. 公开促销列表

### `GET /api/public/promotions`

返回：

```json
{
  "serverTime": "2026-09-09T15:30:00",
  "activities": [
    {
      "activityId": 5001,
      "activityItemId": 5002,
      "name": "限时抢购",
      "productName": "手冲咖啡",
      "skuName": "250g",
      "activityPrice": 19.90,
      "startAt": "2026-09-09T16:00:00",
      "endAt": "2026-09-09T18:00:00",
      "status": "PREHEATED",
      "stockStatus": "AVAILABLE",
      "limitPerUser": 1
    }
  ]
}
```

倒计时必须优先基于 `serverTime` 计算，避免手机时间不准确。

## 17. 公开促销详情

### `GET /api/public/promotions/{activityId}`

返回结构：

```json
{
  "serverTime": "2026-09-09T15:30:00",
  "activity": {
    "activityId": 5001,
    "activityItemId": 5002,
    "name": "限时抢购",
    "productName": "手冲咖啡",
    "skuName": "250g",
    "activityPrice": 19.90,
    "startAt": "2026-09-09T16:00:00",
    "endAt": "2026-09-09T18:00:00",
    "status": "PREHEATED",
    "stockStatus": "AVAILABLE",
    "limitPerUser": 1
  }
}
```

---

# 第三部分：消费者接口

以下接口必须使用 `CONSUMER` Token。

## 18. 购物车

### 18.1 加入购物车

`POST /api/cart/items`

```json
{
  "skuId": 3001,
  "quantity": 2
}
```

返回：

```json
{
  "id": 4001,
  "skuId": 3001,
  "quantity": 2
}
```

### 18.2 购物车列表

`GET /api/cart/items`

返回单项：

```json
{
  "id": 4001,
  "skuId": 3001,
  "productId": 2001,
  "productName": "手冲咖啡",
  "skuName": "250g",
  "storeId": 1001,
  "storeName": "示例店铺",
  "salePrice": 29.90,
  "availableStock": 100,
  "quantity": 2,
  "purchasable": true,
  "unavailableReason": null
}
```

App 应根据 `purchasable` 决定该项能否勾选结算。

### 18.3 修改数量

`PUT /api/cart/items/{id}`

```json
{
  "quantity": 3
}
```

`id` 是购物车项 ID，不是 SKU ID。

### 18.4 删除购物车项

`DELETE /api/cart/items/{id}`

成功时 `data` 为 `null`。

## 19. 收货地址

### 19.1 地址列表

`GET /api/addresses`

返回单项：

```json
{
  "id": 6001,
  "receiverName": "张三",
  "receiverPhone": "13800000000",
  "province": "广东省",
  "city": "深圳市",
  "district": "南山区",
  "detailAddress": "示例路 1 号",
  "isDefault": true,
  "createdAt": "2026-09-09T15:30:00",
  "updatedAt": "2026-09-09T15:30:00"
}
```

### 19.2 新增地址

`POST /api/addresses`

```json
{
  "receiverName": "张三",
  "receiverPhone": "13800000000",
  "province": "广东省",
  "city": "深圳市",
  "district": "南山区",
  "detailAddress": "示例路 1 号",
  "isDefault": true
}
```

字段长度：姓名最多 64、电话最多 32、省市区各最多 64、详细地址最多 255 个字符。

### 19.3 修改地址

`PUT /api/addresses/{id}`

请求体与新增地址相同，而且当前是完整更新，不是局部 PATCH；所有必填字段都要传。

### 19.4 删除地址

`DELETE /api/addresses/{id}`

成功时 `data` 为 `null`。

## 20. 推荐结算流程

正式 App 主流程只使用原子结算接口：

### `POST /api/checkouts`

Header：

```http
Idempotency-Key: checkout-<用户ID>-<UUID>
```

请求：

```json
{
  "cartItemIds": [4001, 4002],
  "addressId": 6001
}
```

返回：

```json
{
  "checkoutGroupId": 7001,
  "checkoutNo": "CG202609090001",
  "status": "PENDING_PAYMENT",
  "totalAmount": 89.70,
  "orders": [
    {
      "orderId": 8001,
      "orderNo": "O202609090001",
      "status": "PENDING_PAYMENT",
      "totalAmount": 59.80,
      "expireAt": "2026-09-09T16:00:00"
    }
  ]
}
```

同一次用户点击产生的重试必须复用相同的 `Idempotency-Key`。用户主动重新发起一笔新结算时才生成新 Key。

不要在点击按钮后立即生成 Key 再因重试生成新 Key，否则会失去幂等保护。提交期间还应禁用按钮，防止重复点击。

### 查询结算组详情

`GET /api/checkouts/{checkoutGroupId}`

返回字段：

```text
checkoutGroupId, checkoutNo, status, totalAmount, createdAt, orders[]
```

其中 `orders[]` 是完整订单详情结构。

### 取消结算组

`POST /api/checkouts/{checkoutGroupId}/cancel`

请求体：无。

### 暂不作为 App 主流程使用的结算接口

| 接口 | 原因 |
|---|---|
| `POST /api/checkouts/prepare` | 阶段性分步结算接口，不如原子提交完整 |
| `POST /api/checkouts/{id}/orders` | 分步创建子订单，普通客户端不应编排内部流程 |
| `POST /api/checkouts/{id}/mock-pay` | 仅模拟支付，正式 App 禁止使用 |

## 21. 旧单店订单接口

### 创建订单

`POST /api/orders`

Header 建议携带 `Idempotency-Key`。

```json
{
  "cartItemIds": [4001],
  "addressId": 6001
}
```

该接口适合兼容旧单店流程。新 App 统一优先使用 `/api/checkouts`，避免维护两套结算入口。

### 我的订单列表

`GET /api/orders`

当前不支持分页，返回 `OrderDetail[]`。

### 订单详情

`GET /api/orders/{id}`

返回：

```json
{
  "id": 8001,
  "checkoutGroupId": 7001,
  "orderNo": "O202609090001",
  "tenantId": 1001,
  "status": "PENDING_PAYMENT",
  "totalAmount": 59.80,
  "expireAt": "2026-09-09T16:00:00",
  "createdAt": "2026-09-09T15:30:00",
  "items": [
    {
      "id": 8101,
      "skuId": 3001,
      "skuNameSnapshot": "250g",
      "salePrice": 29.90,
      "quantity": 2
    }
  ],
  "shippingAddress": {
    "receiverName": "张三",
    "receiverPhone": "13800000000",
    "province": "广东省",
    "city": "深圳市",
    "district": "南山区",
    "detailAddress": "示例路 1 号"
  }
}
```

订单常见状态：`PENDING_PAYMENT`、`PAID`、`CANCELLED`、`CLOSED`。

### 取消订单

`POST /api/orders/{id}/cancel`

请求体：无。重复取消或状态不允许时可能返回 `409`。

### 模拟支付

`POST /api/orders/{id}/mock-pay`

只用于开发验收，正式 App 不得展示或调用。

## 22. 消费者售后

### 查询可申请售后的订单项

`GET /api/after-sales/eligible-orders`

返回单项：

```json
{
  "orderId": 8001,
  "orderItemId": 8101,
  "tenantId": 1001,
  "consumerId": 10001,
  "orderStatus": "PAID",
  "salePrice": 29.90,
  "purchasedQuantity": 2
}
```

### 提交售后

`POST /api/after-sales`

```json
{
  "orderItemId": 8101,
  "quantity": 1,
  "reason": "商品破损"
}
```

### 我的售后列表

`GET /api/after-sales`

### 售后详情

`GET /api/after-sales/{id}`

列表和详情使用相同结构：

```json
{
  "id": 9001,
  "requestNo": "AS202609090001",
  "orderId": 8001,
  "orderItemId": 8101,
  "quantity": 1,
  "requestedAmount": 29.90,
  "reason": "商品破损",
  "status": "SUBMITTED",
  "merchantRemark": null,
  "decidedAt": null,
  "createdAt": "2026-09-09T15:30:00",
  "updatedAt": "2026-09-09T15:30:00"
}
```

售后状态：`SUBMITTED`、`REVIEWING`、`APPROVED`、`REJECTED`。

当前“审核通过”不等于已真实退款，因为项目还没有接入支付退款系统。

## 23. 消费者抢购

### 提交抢购资格

`POST /api/promotions/reservations`

```json
{
  "activityItemId": 5002,
  "quantity": 1,
  "requestKey": "promo-<用户ID>-<UUID>"
}
```

返回：

```json
{
  "code": 1,
  "reservationId": "R202609090001"
}
```

注意这里存在两层 `code`：

- 外层 `ApiResponse.code`：`0` 才表示 HTTP 业务处理成功。
- `data.code`：`1` 表示新获得资格，`2` 表示幂等重试复用原资格，负数表示未开始、结束、售罄、超限或未预热等结果。

### 查询单个抢购结果

`GET /api/promotions/reservations/{reservationId}`

### 查询当前用户在某活动中的资格

`GET /api/promotions/reservations?activityId={activityId}`

返回详情结构：

```json
{
  "reservationId": "R202609090001",
  "activityItemId": 5002,
  "quantity": 1,
  "unitPriceSnapshot": 19.90,
  "reservationStatus": "ORDER_CREATED",
  "orderId": 8002,
  "orderNo": "O202609090002",
  "orderStatus": "PENDING_PAYMENT",
  "totalAmount": 19.90,
  "expireAt": "2026-09-09T16:00:00",
  "createdAt": "2026-09-09T15:30:00",
  "updatedAt": "2026-09-09T15:30:01"
}
```

抢购后订单由消息队列异步创建，因此首次响应不一定马上有 `orderId`。App 应短时间轮询查询结果，例如 1 秒、2 秒、3 秒退避，并设置总超时；不要无限高频轮询。

---

# 第四部分：商家 App 接口

以下接口要求 `MERCHANT_ADMIN` 或 `MERCHANT_OPERATOR` Token。消费者版 App 可以暂不实现本部分。

## 24. 商家上下文

### `GET /api/merchant/context`

返回：

```json
{
  "userId": 20001,
  "tenantId": 1001,
  "userType": "MERCHANT_ADMIN"
}
```

## 25. 商家商品

### 商品列表

`GET /api/merchant/products?page=1&size=20&keyword=咖啡`

返回单项：

```json
{
  "id": 2001,
  "name": "手冲咖啡",
  "description": "商品描述",
  "status": "ON_SALE",
  "createdAt": "2026-09-09T15:30:00",
  "updatedAt": "2026-09-09T15:30:00",
  "skuCount": 2,
  "minSalePrice": 29.90,
  "totalAvailableStock": 100
}
```

### 创建 SPU

`POST /api/merchant/products`

```json
{
  "name": "手冲咖啡",
  "description": "商品描述"
}
```

返回：

```json
{
  "id": 2001
}
```

### 创建 SKU

`POST /api/merchant/products/{productId}/skus`

```json
{
  "skuName": "250g",
  "salePrice": 29.90,
  "availableStock": 100
}
```

返回 `{ "id": 3001 }`。

### 上架/下架

```http
POST /api/merchant/products/{productId}/publish
POST /api/merchant/products/{productId}/unpublish
```

请求体：无。

### 修改 SKU 价格

`PUT /api/merchant/products/skus/{skuId}/price`

```json
{
  "salePrice": 39.90
}
```

## 26. 商家订单

### `GET /api/merchant/orders?page=1&size=20`

返回 `OrderDetail[]`，结构与消费者订单详情一致，但后端按当前商家的 `tenantId` 隔离。

当前只有订单列表，没有商家发货、物流和履约接口。

## 27. 商家售后

```http
GET  /api/merchant/after-sales
GET  /api/merchant/after-sales/{id}
POST /api/merchant/after-sales/{id}/decision
```

审核请求：

```json
{
  "decision": "APPROVED",
  "remark": "同意售后"
}
```

`decision` 只能是 `APPROVED` 或 `REJECTED`，`remark` 最多 500 个字符。

## 28. 商家促销

### 活动列表

`GET /api/merchant/promotions`

返回单项：

```json
{
  "activityId": 5001,
  "activityItemId": 5002,
  "name": "限时抢购",
  "productName": "手冲咖啡",
  "skuId": 3001,
  "skuName": "250g",
  "activityPrice": 19.90,
  "stockTotal": 100,
  "stockAvailable": 80,
  "limitPerUser": 1,
  "startAt": "2026-09-10T10:00:00",
  "endAt": "2026-09-10T12:00:00",
  "status": "SCHEDULED"
}
```

### 创建活动

`POST /api/merchant/promotions`

```json
{
  "name": "限时抢购",
  "startAt": "2026-09-10T10:00:00",
  "endAt": "2026-09-10T12:00:00",
  "skuId": 3001,
  "activityPrice": 19.90,
  "stockTotal": 100,
  "limitPerUser": 1
}
```

开始和结束时间都必须晚于当前时间，并且结束时间必须晚于开始时间。成功返回活动 ID。

### 取消活动

`DELETE /api/merchant/promotions/{activityId}`

### 预热活动

`POST /api/merchant/promotions/{activityId}/preheat`

预热属于较强的运营/运维操作，消费者 App 不得调用。正式系统更适合由后端定时任务自动处理。

## 29. 商家经营仪表盘

### 指标卡片

`GET /api/merchant/dashboard/metrics?startDate=2026-09-01&endDate=2026-09-09`

返回：

```json
{
  "validOrderCount": 100,
  "paidRevenue": 9999.00,
  "pendingPaymentCount": 8,
  "lowStockProductCount": 3
}
```

### 每日趋势

`GET /api/merchant/dashboard/trends?startDate=2026-09-01&endDate=2026-09-09`

返回单点：

```json
{
  "date": "2026-09-09",
  "orderCount": 12,
  "paidRevenue": 1288.00
}
```

`startDate/endDate` 格式固定为 `yyyy-MM-dd`。

---

# 第五部分：禁止或暂缓接入

## 30. 不接入 App 的接口

| 接口 | 处理方式 |
|---|---|
| `/api/debug/**` | 仅后端开发调试，App 禁止调用 |
| `/api/public/products/ping` | 仅开发测试 |
| `/swagger-ui/**` | 后端文档页面，不属于 App 功能 |
| `/v3/api-docs/**` | OpenAPI 数据，不属于普通业务页面 |
| `/actuator/health` | 部署健康检查，不建议普通用户端轮询 |
| 所有 `mock-pay` | 只用于开发，正式版必须替换为真实支付 |

## 31. 当前尚不存在、不要自行假设的接口

```text
Refresh Token
退出登录/撤销 Token
忘记密码/短信验证码
鸿蒙账号登录
商品图片上传
用户头像上传
真实支付和支付回调
真实退款和退款回调
商家发货
物流查询
消费者确认收货
消息推送
收藏、评价、优惠券
```

如果页面需要这些功能，应先扩展后端合同，不能让 App 使用假接口并默认后端已经支持。

## 32. App 页面与接口映射

| App 页面 | 调用接口 |
|---|---|
| 启动页 | 本地读取 Token；有 Token 时调用 `/api/auth/me` |
| 注册页 | `POST /api/auth/register`，成功后再登录 |
| 登录页 | `POST /api/auth/login` |
| 商城首页 | `GET /api/public/stores`、`GET /api/public/promotions` |
| 搜索页 | `GET /api/public/stores/products/search` |
| 店铺页 | `GET /api/public/stores/{storeId}/products` |
| 商品详情 | 商品详情、SKU availability、加入购物车 |
| 购物车 | 购物车 GET/POST/PUT/DELETE |
| 地址管理 | 地址 GET/POST/PUT/DELETE |
| 确认订单 | 购物车列表、地址列表、`POST /api/checkouts` |
| 结算结果 | `GET /api/checkouts/{checkoutGroupId}` |
| 我的订单 | `GET /api/orders` |
| 订单详情 | `GET /api/orders/{id}`、取消订单 |
| 售后申请 | eligible-orders、提交售后 |
| 售后记录 | 售后列表和详情 |
| 抢购详情 | 公开促销详情、提交资格、轮询资格结果 |

## 33. 联调验收清单

每完成一个模块，至少验证：

- 成功响应能够正确解析。
- 无 Token 请求受保护接口会进入登录页。
- 过期或错误 Token 收到 401 后会清理本地状态。
- 消费者 Token 不能调用 `/api/merchant/**`。
- 商家 Token 不能操作消费者购物车、地址和订单。
- 400 参数错误能展示后端 `message`。
- 409 库存或状态冲突不会被当成网络故障。
- 页面离开后不会继续无意义轮询。
- 金额只负责展示，不在客户端决定最终成交金额。
- 日志中不会输出密码和完整 Token。
- 真机使用电脑局域网 IP，而不是 `localhost`。

## 34. 文档维护规则

后端新增或修改以下内容时，要同步更新本文：

- Controller 路径或 HTTP 方法。
- DTO 请求字段和校验规则。
- VO 响应字段。
- 用户角色和权限边界。
- 状态枚举。
- 错误码。
- 幂等规则。

App 实现应以 Controller 和 DTO/VO 源码为最终依据；本文用于双方联调合同，不代表尚未实现的规划接口已经可用。
