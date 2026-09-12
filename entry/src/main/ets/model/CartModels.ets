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
