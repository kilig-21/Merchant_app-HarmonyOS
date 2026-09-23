import { PromotionActivity } from '../model/PromotionModels'

/** 将服务端活动时间与状态转换为消费者可读文案；倒计时始终使用服务端校准后的时间。 */
export class PromotionPresentation {
  static serverNow(serverTime: string): number {
    const parsed = Date.parse(serverTime)
    return Number.isNaN(parsed) ? Date.now() : parsed
  }

  static phase(activity: PromotionActivity, now: number): string {
    if (activity.stockStatus === 'SOLD_OUT') { return '已售罄' }
    const startAt = Date.parse(activity.startAt)
    const endAt = Date.parse(activity.endAt)
    if (Number.isNaN(startAt) || Number.isNaN(endAt)) { return '活动时间待确认' }
    if (now < startAt) { return `距开始 ${PromotionPresentation.duration(startAt - now)}` }
    if (now >= endAt || activity.status === 'ENDED') { return '活动已结束' }
    return `进行中 · 余 ${PromotionPresentation.duration(endAt - now)}`
  }

  static canReserve(activity: PromotionActivity, now: number): boolean {
    return activity.stockStatus === 'AVAILABLE' && activity.status === 'ACTIVE' && now >= Date.parse(activity.startAt) && now < Date.parse(activity.endAt)
  }

  static status(activity: PromotionActivity, now: number): string {
    if (activity.stockStatus === 'SOLD_OUT') { return '已售罄' }
    if (now < Date.parse(activity.startAt)) { return '即将开始' }
    if (now >= Date.parse(activity.endAt) || activity.status === 'ENDED') { return '已结束' }
    return activity.status === 'ACTIVE' ? '限量进行中' : '活动准备中'
  }

  static date(value: string): string {
    return value.replace('T', ' ').substring(0, 16)
  }

  private static duration(milliseconds: number): string {
    const seconds = Math.max(0, Math.floor(milliseconds / 1000))
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const remainder = seconds % 60
    if (hours > 0) { return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${remainder.toString().padStart(2, '0')}` }
    return `${minutes.toString().padStart(2, '0')}:${remainder.toString().padStart(2, '0')}`
  }
}
