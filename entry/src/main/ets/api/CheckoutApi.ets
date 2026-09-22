import { http } from '@kit.NetworkKit'
import { CheckoutCreateResult, CheckoutGroupDetail, CheckoutRequest } from '../model/CheckoutModels'
import { HttpClient, RequestHeader, RequestOptions } from '../network/HttpClient'

export class CheckoutApi {
  static async create(request: CheckoutRequest, idempotencyKey: string): Promise<CheckoutCreateResult> {
    return await HttpClient.request<CheckoutCreateResult>('/api/checkouts',
      new RequestOptions(http.RequestMethod.POST, request, undefined, [new RequestHeader('Idempotency-Key', idempotencyKey)]))
  }

  static async get(checkoutGroupId: number): Promise<CheckoutGroupDetail> {
    return await HttpClient.request<CheckoutGroupDetail>(`/api/checkouts/${checkoutGroupId}`)
  }
}
