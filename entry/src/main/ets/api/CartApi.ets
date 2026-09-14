import { http } from '@kit.NetworkKit'
import { AddCartItemRequest, CartItem, CartMutationResult, UpdateCartItemRequest } from '../model/CartModels'
import { HttpClient, RequestOptions } from '../network/HttpClient'

export class CartApi {
  static async add(skuId: number, quantity: number): Promise<CartMutationResult> {
    return await HttpClient.request<CartMutationResult>('/api/cart/items',
      new RequestOptions(http.RequestMethod.POST, new AddCartItemRequest(skuId, quantity)))
  }

  static async list(): Promise<CartItem[]> {
    return await HttpClient.request<CartItem[]>('/api/cart/items')
  }

  static async update(itemId: number, quantity: number): Promise<CartMutationResult> {
    return await HttpClient.request<CartMutationResult>(`/api/cart/items/${itemId}`,
      new RequestOptions(http.RequestMethod.PUT, new UpdateCartItemRequest(quantity)))
  }

  static async remove(itemId: number): Promise<void> {
    await HttpClient.request<void>(`/api/cart/items/${itemId}`, new RequestOptions(http.RequestMethod.DELETE))
  }
}
