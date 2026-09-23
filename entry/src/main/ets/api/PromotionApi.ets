import { http } from '@kit.NetworkKit'
import { PromotionActivityDetail, PromotionActivityList, PromotionReservationDetail,
  PromotionReservationResult, ReservePromotionRequest } from '../model/PromotionModels'
import { HttpClient, QueryParam, RequestOptions } from '../network/HttpClient'

/** 公开活动不要求登录；抢购资格接口会在消费者登录后另行调用。 */
export class PromotionApi {
  static async list(): Promise<PromotionActivityList> {
    return await HttpClient.request<PromotionActivityList>('/api/public/promotions')
  }

  static async get(activityId: number): Promise<PromotionActivityDetail> {
    return await HttpClient.request<PromotionActivityDetail>(`/api/public/promotions/${activityId}`)
  }

  static async reserve(request: ReservePromotionRequest): Promise<PromotionReservationResult> {
    return await HttpClient.request<PromotionReservationResult>('/api/promotions/reservations',
      new RequestOptions(http.RequestMethod.POST, request))
  }

  static async getReservation(reservationId: string): Promise<PromotionReservationDetail> {
    return await HttpClient.request<PromotionReservationDetail>(`/api/promotions/reservations/${encodeURIComponent(reservationId)}`)
  }

  static async listReservations(activityId: number): Promise<PromotionReservationDetail[]> {
    return await HttpClient.request<PromotionReservationDetail[]>('/api/promotions/reservations',
      new RequestOptions(undefined, undefined, [new QueryParam('activityId', activityId)]))
  }
}
