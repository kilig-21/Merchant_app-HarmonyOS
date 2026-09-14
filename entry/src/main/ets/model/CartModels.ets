/** /api/cart/items 响应；勾选状态独立保存在 ViewModel。 */
export interface CartItem {
  id: number
  skuId: number
  productId: number
  productName: string
  skuName: string
  storeId: number
  storeName: string
  salePrice: number
  availableStock: number
  quantity: number
  purchasable: boolean
  unavailableReason: string | null
}
export interface CartGroup {
  storeId: number
  storeName: string
  items: CartItem[]
}

export class AddCartItemRequest {
  skuId: number
  quantity: number

  constructor(skuId: number, quantity: number) {
    this.skuId = skuId
    this.quantity = quantity
  }
}

export class UpdateCartItemRequest {
  quantity: number

  constructor(quantity: number) {
    this.quantity = quantity
  }
}

export interface CartMutationResult {
  id: number
  skuId: number
  quantity: number
}
