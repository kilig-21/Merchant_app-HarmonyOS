import { OrderDetail } from './OrderModels'

export interface Address {
  id: number
  receiverName: string
  receiverPhone: string
  province: string
  city: string
  district: string
  detailAddress: string
  isDefault: boolean
  createdAt: string
  updatedAt: string
}

export class AddressRequest {
  receiverName: string
  receiverPhone: string
  province: string
  city: string
  district: string
  detailAddress: string
  isDefault: boolean

  constructor(receiverName: string, receiverPhone: string, province: string, city: string, district: string, detailAddress: string, isDefault: boolean) {
    this.receiverName = receiverName
    this.receiverPhone = receiverPhone
    this.province = province
    this.city = city
    this.district = district
    this.detailAddress = detailAddress
    this.isDefault = isDefault
  }
}

export class CheckoutRequest {
  cartItemIds: number[]
  addressId: number

  constructor(cartItemIds: number[], addressId: number) {
    this.cartItemIds = cartItemIds
    this.addressId = addressId
  }
}

/** POST /api/checkouts 的创建结果中，每个子订单的字段。 */
export interface CheckoutCreatedOrder {
  orderId: number
  orderNo: string
  status: string
  totalAmount: number
  expireAt: string | null
}

/** POST /api/checkouts 的响应。 */
export interface CheckoutCreateResult {
  checkoutGroupId: number
  checkoutNo: string
  status: string
  totalAmount: number
  orders: CheckoutCreatedOrder[]
}

/** GET /api/checkouts/{id} 的响应；子订单与 GET /api/orders/{id} 结构一致。 */
export interface CheckoutGroupDetail {
  checkoutGroupId: number
  checkoutNo: string
  status: string
  totalAmount: number
  createdAt: string
  orders: OrderDetail[]
}
