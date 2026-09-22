import { http } from '@kit.NetworkKit'
import { NetworkConfig } from '../config/NetworkConfig'
import { ApiError, ApiErrorKind } from './ApiError'

export interface ApiResponse<T> {
  code: number
  message: string
  data: T | null
}

export class RequestOptions {
  method?: http.RequestMethod
  query?: QueryParam[]
  body?: Object
  headers?: RequestHeader[]

  constructor(method?: http.RequestMethod, body?: Object, query?: QueryParam[], headers?: RequestHeader[]) {
    this.method = method
    this.body = body
    this.query = query
    this.headers = headers
  }
}

export class QueryParam {
  key: string
  value: string | number | boolean

  constructor(key: string, value: string | number | boolean) {
    this.key = key
    this.value = value
  }
}

export class RequestHeader {
  key: string
  value: string

  constructor(key: string, value: string) {
    this.key = key
    this.value = value
  }
}

export class HttpClient {
  private static accessToken: string = ''

  static setAccessToken(token: string): void {
    HttpClient.accessToken = token.trim()
  }

  static clearAccessToken(): void {
    HttpClient.accessToken = ''
  }

  static async request<T>(path: string, options: RequestOptions = new RequestOptions()): Promise<T> {
    const baseUrl = NetworkConfig.BASE_URL.trim().replace(/\/+$/, '')
    if (baseUrl.length === 0) {
      throw new ApiError(ApiErrorKind.Configuration, '未配置后端服务地址')
    }

    const request = http.createHttp()

    try {
      const requestOptions: http.HttpRequestOptions = {
        method: options.method ?? http.RequestMethod.GET,
        header: HttpClient.buildHeaders(options.headers),
        connectTimeout: NetworkConfig.CONNECT_TIMEOUT_MS,
        readTimeout: NetworkConfig.READ_TIMEOUT_MS
      }

      if (options.body !== undefined) {
        requestOptions.extraData = options.body
      }

      const response = await request.request(
        HttpClient.buildUrl(baseUrl, path, options.query),
        requestOptions
      )

      const statusCode = Number(response.responseCode)
      let envelope: ApiResponse<T>
      try {
        envelope = HttpClient.parseEnvelope<T>(response.result)
      } catch (error) {
        // 反向代理或服务未启动时可能返回 HTML/空响应；保留 HTTP 状态便于页面判断是否可安全重试。
        if (statusCode < 200 || statusCode >= 300) {
          throw new ApiError(ApiErrorKind.Http, `服务响应异常：${statusCode}`, statusCode)
        }
        const message = error instanceof Error ? error.message : '服务响应格式无法识别'
        throw new ApiError(ApiErrorKind.InvalidResponse, message)
      }

      if (statusCode < 200 || statusCode >= 300) {
        throw new ApiError(
          ApiErrorKind.Http,
          envelope.message || `服务响应异常：${statusCode}`,
          statusCode
        )
      }

      if (envelope.code !== 0) {
        throw new ApiError(
          ApiErrorKind.Business,
          envelope.message || '服务拒绝了本次请求',
          envelope.code
        )
      }

      return envelope.data as T
    } catch (error) {
      if (error instanceof ApiError) {
        throw error
      }

      const message = error instanceof Error ? error.message : '网络连接失败，请检查网络后重试'
      throw new ApiError(ApiErrorKind.Network, message)
    } finally {
      request.destroy()
    }
  }

  private static buildHeaders(extraHeaders?: RequestHeader[]): Record<string, string> {
    const headers: Record<string, string> = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }

    if (HttpClient.accessToken.length > 0) {
      headers['Authorization'] = `Bearer ${HttpClient.accessToken}`
    }
    if (extraHeaders !== undefined) {
      extraHeaders.forEach((item: RequestHeader) => headers[item.key] = item.value)
    }

    return headers
  }

  private static buildUrl(
    baseUrl: string,
    path: string,
    query?: QueryParam[]
  ): string {
    const normalizedPath = path.startsWith('/') ? path : `/${path}`
    if (query === undefined) {
      return `${baseUrl}${normalizedPath}`
    }

    const pairs: string[] = []
    query.forEach((item: QueryParam) => {
      pairs.push(`${encodeURIComponent(item.key)}=${encodeURIComponent(String(item.value))}`)
    })

    if (pairs.length === 0) {
      return `${baseUrl}${normalizedPath}`
    }

    const separator = normalizedPath.includes('?') ? '&' : '?'
    return `${baseUrl}${normalizedPath}${separator}${pairs.join('&')}`
  }

  private static parseEnvelope<T>(result: string | Object | ArrayBuffer): ApiResponse<T> {
    let envelope: ApiResponse<T>

    try {
      if (typeof result === 'string') {
        envelope = JSON.parse(result) as ApiResponse<T>
      } else if (result instanceof ArrayBuffer) {
        throw new Error('服务响应不是 JSON 文本')
      } else {
        envelope = result as ApiResponse<T>
      }
    } catch (_) {
      throw new ApiError(ApiErrorKind.InvalidResponse, '服务响应格式无法识别')
    }

    if (envelope === null || typeof envelope !== 'object' || typeof envelope.code !== 'number' || typeof envelope.message !== 'string') {
      throw new ApiError(ApiErrorKind.InvalidResponse, '服务响应缺少标准字段')
    }

    return envelope
  }
}
