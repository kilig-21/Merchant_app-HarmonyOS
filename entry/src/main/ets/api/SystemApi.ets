import { HttpClient } from '../network/HttpClient'

/** 仅用于开发期确认设备能够访问后端，不用于消费者页面的业务展示。 */
export class SystemApi {
  static async ping(): Promise<string> {
    return await HttpClient.request<string>('/api/ping')
  }
}
