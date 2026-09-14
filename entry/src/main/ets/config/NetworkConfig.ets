/**
 * 开发环境的后端地址只在这里维护。
 * 真机或模拟器不能填写 127.0.0.1，因为它会指向设备自身。
 */
export class NetworkConfig {
  // 当前联调后端运行在本机 WLAN 地址；设备和电脑必须处于同一局域网。
  static readonly BASE_URL: string = 'http://10.251.73.246:8080'

  static readonly CONNECT_TIMEOUT_MS: number = 10000
  static readonly READ_TIMEOUT_MS: number = 15000
}
