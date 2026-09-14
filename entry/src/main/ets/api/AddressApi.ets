import { http } from '@kit.NetworkKit'
import { Address, AddressRequest } from '../model/CheckoutModels'
import { HttpClient, RequestOptions } from '../network/HttpClient'

export class AddressApi {
  static async list(): Promise<Address[]> {
    return await HttpClient.request<Address[]>('/api/addresses')
  }

  static async create(request: AddressRequest): Promise<void> {
    await HttpClient.request<void>('/api/addresses', new RequestOptions(http.RequestMethod.POST, request))
  }

  static async update(id: number, request: AddressRequest): Promise<void> {
    await HttpClient.request<void>(`/api/addresses/${id}`, new RequestOptions(http.RequestMethod.PUT, request))
  }

  static async remove(id: number): Promise<void> {
    await HttpClient.request<void>(`/api/addresses/${id}`, new RequestOptions(http.RequestMethod.DELETE))
  }
}
