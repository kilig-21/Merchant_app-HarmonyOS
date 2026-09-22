/**
 * 开发环境的后端地址只在这里维护。
 * 真机或模拟器不能填写 127.0.0.1，因为它会指向设备自身。
 */
export class NetworkConfig {
  // 填写运行 Merchant_AI_Operation 后端的电脑局域网地址；设备和电脑必须处于同一局域网。
  // 后端默认端口为 8080。不要填写 127.0.0.1 或 localhost，它们会指向设备自身。
  static readonly BASE_URL: string = 'http://10.251.73.246:8080'

  static readonly CONNECT_TIMEOUT_MS: number = 10000
  static readonly READ_TIMEOUT_MS: number = 15000
}
