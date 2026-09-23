import { PromotionApi } from '../api/PromotionApi'
import { PromotionActivity } from '../model/PromotionModels'
import { PageHeader } from '../components/common/PageHeader'
import { PageStateType, PageStateView } from '../components/common/PageStateView'
import { AppColors, AppRadius } from '../theme/AppTheme'
import { PromotionPresentation } from '../utils/PromotionPresentation'

@Component
export struct PromotionDetailPage {
  @Prop activityId: number = 0
  onBack: () => void = () => {}
  @State activity: PromotionActivity | null = null
  @State loading: boolean = true
  @State error: string = ''
  @State now: number = Date.now()
  private alive: boolean = false
  private requestSerial: number = 0
  private serverOffsetMs: number = 0
  private clockTimer: number = -1

  aboutToAppear(): void {
    this.alive = true
    this.clockTimer = setInterval(() => this.now = Date.now() + this.serverOffsetMs, 1000)
    this.load()
  }

  aboutToDisappear(): void {
    this.alive = false
    this.requestSerial++
    clearInterval(this.clockTimer)
    this.clockTimer = -1
  }

  private async load(): Promise<void> {
    if (this.activityId <= 0) { this.error = '活动编号无效'; this.loading = false; return }
    const serial = ++this.requestSerial
    this.loading = true
    this.error = ''
    try {
      const result = await PromotionApi.get(this.activityId)
      if (!this.alive || serial !== this.requestSerial) { return }
      this.serverOffsetMs = PromotionPresentation.serverNow(result.serverTime) - Date.now()
      this.now = Date.now() + this.serverOffsetMs
      this.activity = result.activity
    } catch (error) {
      if (this.alive && serial === this.requestSerial) {
        this.error = error instanceof Error ? error.message : '活动详情读取失败，请重试'
      }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.loading = false }
    }
  }

  build() {
    Column({ space: 16 }) {
      PageHeader({ title: '活动详情', actionLabel: '刷新', actionDisabled: this.loading, onBack: this.onBack, onAction: () => this.load() })
      if (this.loading) {
        PageStateView({ type: PageStateType.Loading, title: '正在读取活动详情', description: '' })
      } else if (this.activity === null) {
        PageStateView({ type: PageStateType.Error, title: '活动暂时无法打开', description: this.error, onAction: () => this.load() })
      } else {
        Scroll() {
          Column({ space: 18 }) {
            Column({ space: 10 }) {
              Text(PromotionPresentation.status(this.activity, this.now)).fontSize(12).fontWeight(FontWeight.Medium)
                .fontColor(PromotionPresentation.canReserve(this.activity, this.now) ? AppColors.ACCENT : AppColors.TEXT_SECONDARY)
              Text(this.activity.name).fontSize(30).lineHeight(39).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
              Text(`${this.activity.productName} · ${this.activity.skuName}`).fontSize(15).lineHeight(23).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%').alignItems(HorizontalAlign.Start).padding(20).backgroundColor(AppColors.SAND).borderRadius(AppRadius.CARD)
            Column({ space: 10 }) {
              Text('¥ ' + this.activity.activityPrice.toFixed(2)).fontSize(36).fontWeight(FontWeight.Medium).fontColor(AppColors.ACCENT)
              Text(PromotionPresentation.phase(this.activity, this.now)).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%').alignItems(HorizontalAlign.Start)
            Row({ space: 1 }) {
              Column({ space: 7 }) { Text('限购数量').fontSize(11).fontColor(AppColors.TEXT_SECONDARY); Text(`${this.activity.limitPerUser} 件`).fontSize(16).fontColor(AppColors.BRAND) }
                .layoutWeight(1).alignItems(HorizontalAlign.Start).padding(16).backgroundColor(AppColors.SURFACE)
              Column({ space: 7 }) { Text('开始时间').fontSize(11).fontColor(AppColors.TEXT_SECONDARY); Text(PromotionPresentation.date(this.activity.startAt)).fontSize(13).fontColor(AppColors.BRAND) }
                .layoutWeight(1).alignItems(HorizontalAlign.Start).padding(16).backgroundColor(AppColors.SURFACE)
            }.width('100%').clip(true).borderRadius(AppRadius.CONTROL)
            Column({ space: 7 }) {
              Text('活动说明').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
              Text('抢购资格由服务端原子确认。获得资格后，订单会异步创建；请以资格和订单最终状态为准。').fontSize(13).lineHeight(22).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%').alignItems(HorizontalAlign.Start).padding(18).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
          }.width('100%').padding({ bottom: 24 })
        }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').padding({ left: 18, right: 18, top: 8 }).backgroundColor(AppColors.BACKGROUND)
  }
}
