import { http } from '@kit.NetworkKit'
import { OrderDetail } from '../model/OrderModels'
import { HttpClient, RequestOptions } from '../network/HttpClient'

export class OrderApi {
  static async list(): Promise<OrderDetail[]> {
    return await HttpClient.request<OrderDetail[]>('/api/orders')
  }

  static async get(orderId: number): Promise<OrderDetail> {
    return await HttpClient.request<OrderDetail>(`/api/orders/${orderId}`)
  }

  static async cancel(orderId: number): Promise<OrderDetail> {
    return await HttpClient.request<OrderDetail>(`/api/orders/${orderId}/cancel`, new RequestOptions(http.RequestMethod.POST))
  }
}
