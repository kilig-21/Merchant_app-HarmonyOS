import { http } from '@kit.NetworkKit'
import { AfterSaleEligibleOrderItem, AfterSaleRequest, SubmitAfterSaleRequest } from '../model/AfterSaleModels'
import { HttpClient, RequestOptions } from '../network/HttpClient'

/** 消费者售后接口；所有请求均要求消费者登录态。 */
export class AfterSaleApi {
  static async eligibleOrders(): Promise<AfterSaleEligibleOrderItem[]> {
    return await HttpClient.request<AfterSaleEligibleOrderItem[]>('/api/after-sales/eligible-orders')
  }

  static async list(): Promise<AfterSaleRequest[]> {
    return await HttpClient.request<AfterSaleRequest[]>('/api/after-sales')
  }

  static async get(id: number): Promise<AfterSaleRequest> {
    return await HttpClient.request<AfterSaleRequest>(`/api/after-sales/${id}`)
  }

  static async submit(orderItemId: number, quantity: number, reason: string): Promise<AfterSaleRequest> {
    return await HttpClient.request<AfterSaleRequest>('/api/after-sales',
      new RequestOptions(http.RequestMethod.POST, new SubmitAfterSaleRequest(orderItemId, quantity, reason)))
  }
}
