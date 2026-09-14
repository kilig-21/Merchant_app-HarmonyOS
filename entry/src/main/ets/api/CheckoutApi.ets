import { http } from '@kit.NetworkKit'
import { CheckoutGroup, CheckoutRequest } from '../model/CheckoutModels'
import { HttpClient, RequestHeader, RequestOptions } from '../network/HttpClient'

export class CheckoutApi {
  static async create(request: CheckoutRequest, idempotencyKey: string): Promise<CheckoutGroup> {
    return await HttpClient.request<CheckoutGroup>('/api/checkouts',
      new RequestOptions(http.RequestMethod.POST, request, undefined, [new RequestHeader('Idempotency-Key', idempotencyKey)]))
  }

  static async get(checkoutGroupId: number): Promise<CheckoutGroup> {
    return await HttpClient.request<CheckoutGroup>(`/api/checkouts/${checkoutGroupId}`)
  }
}
