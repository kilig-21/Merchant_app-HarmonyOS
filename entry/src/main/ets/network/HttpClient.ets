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
  query?: Record<string, string | number | boolean | undefined>
  body?: Object

  constructor(method?: http.RequestMethod, body?: Object, query?: Record<string, string | number | boolean | undefined>) {
    this.method = method
    this.body = body
    this.query = query
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
        header: HttpClient.buildHeaders(),
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
      const envelope = HttpClient.parseEnvelope<T>(response.result)

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

  private static buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }

    if (HttpClient.accessToken.length > 0) {
      headers['Authorization'] = `Bearer ${HttpClient.accessToken}`
    }

    return headers
  }

  private static buildUrl(
    baseUrl: string,
    path: string,
    query?: Record<string, string | number | boolean | undefined>
  ): string {
    const normalizedPath = path.startsWith('/') ? path : `/${path}`
    if (query === undefined) {
      return `${baseUrl}${normalizedPath}`
    }

    const pairs: string[] = []
    Object.keys(query).forEach((key: string) => {
      const value = query[key]
      if (value !== undefined) {
        pairs.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`)
      }
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

    if (typeof envelope.code !== 'number' || typeof envelope.message !== 'string') {
      throw new ApiError(ApiErrorKind.InvalidResponse, '服务响应缺少标准字段')
    }

    return envelope
  }
}
