export enum ApiErrorKind {
  Configuration = 'configuration',
  Network = 'network',
  InvalidResponse = 'invalidResponse',
  Http = 'http',
  Business = 'business'
}

/**
 * 网络层把底层异常转换成稳定错误类型。
 * 页面只根据 kind 决定提示与是否允许重试。
 */
export class ApiError extends Error {
  readonly kind: ApiErrorKind
  readonly statusCode: number

  constructor(kind: ApiErrorKind, message: string, statusCode: number = 0) {
    super(message)
    this.name = 'ApiError'
    this.kind = kind
    this.statusCode = statusCode
  }
}