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

export class PromotionRoute {
  activityId: number

  constructor(activityId: number = 0) {
    this.activityId = activityId
  }
}
