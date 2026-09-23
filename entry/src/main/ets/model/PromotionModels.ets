/** 公开限量活动接口返回的单个活动项。 */
export interface PromotionActivity {
  activityId: number
  activityItemId: number
  name: string
  productName: string
  skuName: string
  activityPrice: number
  startAt: string
  endAt: string
  status: string
  stockStatus: string
  limitPerUser: number
}

export interface PromotionActivityList {
  serverTime: string
  activities: PromotionActivity[]
}

export interface PromotionActivityDetail {
  serverTime: string
  activity: PromotionActivity
}

export interface PromotionReservationResult {
  code: number
  reservationId: string
}

export interface PromotionReservationDetail {
  reservationId: string
  activityItemId: number
  quantity: number
  unitPriceSnapshot: number
  reservationStatus: string
  orderId: number | null
  orderNo: string | null
  orderStatus: string | null
  totalAmount: number
  expireAt: string | null
  createdAt: string
  updatedAt: string
}

export class ReservePromotionRequest {
  activityItemId: number
  quantity: number
  requestKey: string

  constructor(activityItemId: number, quantity: number, requestKey: string) {
    this.activityItemId = activityItemId
    this.quantity = quantity
    this.requestKey = requestKey
  }
}

export class PromotionRoute {
  activityId: number

  constructor(activityId: number = 0) {
    this.activityId = activityId
  }
}
