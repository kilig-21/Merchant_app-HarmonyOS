import { ReservePromotionRequest } from '../model/PromotionModels'

/** 结果不明确时冻结活动项、数量和幂等键，重试不会重复占用资格。 */
export class PromotionReservationIntent {
  request: ReservePromotionRequest | null = null

  begin(activityItemId: number, quantity: number): ReservePromotionRequest {
    if (this.request === null) {
      const requestKey = `promo-${activityItemId}-${Date.now()}-${Math.floor(Math.random() * 1000000000)}`
      this.request = new ReservePromotionRequest(activityItemId, quantity, requestKey)
    }
    return this.request
  }

  reset(): void {
    this.request = null
  }
}
