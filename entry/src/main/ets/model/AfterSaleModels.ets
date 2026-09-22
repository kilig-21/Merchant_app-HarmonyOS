/** GET /api/after-sales/eligible-orders 返回的可申请售后订单项。 */
export interface AfterSaleEligibleOrderItem {
  orderId: number
  orderItemId: number
  tenantId: number
  consumerId: number
  orderStatus: string
  salePrice: number
  purchasedQuantity: number
}

/** GET /api/after-sales 及详情接口的统一返回结构。 */
export interface AfterSaleRequest {
  id: number
  requestNo: string
  orderId: number
  orderItemId: number
  quantity: number
  requestedAmount: number
  reason: string
  status: string
  merchantRemark: string | null
  decidedAt: string | null
  createdAt: string
  updatedAt: string
}

export class SubmitAfterSaleRequest {
  orderItemId: number
  quantity: number
  reason: string

  constructor(orderItemId: number, quantity: number, reason: string) {
    this.orderItemId = orderItemId
    this.quantity = quantity
    this.reason = reason
  }
}
