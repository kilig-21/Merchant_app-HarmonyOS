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

export interface CheckoutOrderSummary {
  orderId: number
  orderNo: string
  status: string
  totalAmount: number
  expireAt: string | null
}

export interface CheckoutGroup {
  checkoutGroupId: number
  checkoutNo: string
  status: string
  totalAmount: number
  createdAt?: string
  orders: CheckoutOrderSummary[]
}
