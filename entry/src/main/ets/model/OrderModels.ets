export interface OrderItem {
  id: number
  skuId: number
  skuNameSnapshot: string
  salePrice: number
  quantity: number
}

export interface ShippingAddressSnapshot {
  receiverName: string
  receiverPhone: string
  province: string
  city: string
  district: string
  detailAddress: string
}

export interface OrderDetail {
  id: number
  checkoutGroupId: number
  orderNo: string
  tenantId: number
  status: string
  totalAmount: number
  expireAt: string | null
  createdAt: string
  items: OrderItem[]
  shippingAddress: ShippingAddressSnapshot
}
