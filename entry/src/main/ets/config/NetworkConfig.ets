/**
 * 开发环境的后端地址只在这里维护。
 * 真机或模拟器不能填写 127.0.0.1，因为它会指向设备自身。
 */
export class NetworkConfig {
  // 联调时填入运行 Spring Boot 电脑的局域网 IPv4，例如 http://10.251.73.246:8080。
  // 不提交个人局域网地址；空值会在请求前明确提示未配置服务地址。
  static readonly BASE_URL: string = ''

  static readonly CONNECT_TIMEOUT_MS: number = 10000
  static readonly READ_TIMEOUT_MS: number = 15000
}
