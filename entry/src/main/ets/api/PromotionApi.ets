import { PromotionActivityDetail, PromotionActivityList } from '../model/PromotionModels'
import { HttpClient } from '../network/HttpClient'

/** 公开活动不要求登录；抢购资格接口会在消费者登录后另行调用。 */
export class PromotionApi {
  static async list(): Promise<PromotionActivityList> {
    return await HttpClient.request<PromotionActivityList>('/api/public/promotions')
  }

  static async get(activityId: number): Promise<PromotionActivityDetail> {
    return await HttpClient.request<PromotionActivityDetail>(`/api/public/promotions/${activityId}`)
  }
}
