import { PromotionApi } from '../api/PromotionApi'
import { PromotionActivity } from '../model/PromotionModels'
import { PageHeader } from '../components/common/PageHeader'
import { PageStateType, PageStateView } from '../components/common/PageStateView'
import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { PromotionPresentation } from '../utils/PromotionPresentation'

@Component
export struct PromotionsPage {
  onBack: () => void = () => {}
  onOpenDetail: (activityId: number) => void = (_: number) => {}
  @State activities: PromotionActivity[] = []
  @State loading: boolean = true
  @State error: string = ''
  @State now: number = Date.now()
  @State heroVisible: boolean = false
  @State ambientShift: boolean = false
  @State listVisible: boolean = false
  private alive: boolean = false
  private requestSerial: number = 0
  private serverOffsetMs: number = 0
  private clockTimer: number = -1
  private motionTimer: number = -1
  private listTimer: number = -1

  aboutToAppear(): void {
    this.alive = true
    this.clockTimer = setInterval(() => this.now = Date.now() + this.serverOffsetMs, 1000)
    this.startMotion()
    this.load()
  }

  aboutToDisappear(): void {
    this.alive = false
    this.requestSerial++
    clearInterval(this.clockTimer)
    clearTimeout(this.motionTimer)
    clearTimeout(this.listTimer)
    this.clockTimer = -1
  }

  private startMotion(): void {
    this.heroVisible = false
    this.ambientShift = false
    this.motionTimer = setTimeout(() => {
      if (!this.alive) { return }
      this.getUIContext().animateTo({ duration: 620, curve: 'spring-motion(0.58,0.82,0)' }, () => this.heroVisible = true)
      this.getUIContext().animateTo({ duration: 3200, curve: Curve.EaseInOut, iterations: 3, playMode: PlayMode.Alternate }, () => {
        this.ambientShift = true
      })
    }, 60)
  }

  private revealList(): void {
    clearTimeout(this.listTimer)
    this.listVisible = false
    this.listTimer = setTimeout(() => {
      if (!this.alive) { return }
      this.getUIContext().animateTo({ duration: 560, curve: 'spring-motion(0.55,0.84,0)' }, () => this.listVisible = true)
    }, 30)
  }

  private async load(): Promise<void> {
    const serial = ++this.requestSerial
    this.loading = true
    this.error = ''
    try {
      const result = await PromotionApi.list()
      if (!this.alive || serial !== this.requestSerial) { return }
      this.serverOffsetMs = PromotionPresentation.serverNow(result.serverTime) - Date.now()
      this.now = Date.now() + this.serverOffsetMs
      this.activities = result.activities
      this.revealList()
    } catch (error) {
      if (this.alive && serial === this.requestSerial) {
        this.error = error instanceof Error ? error.message : '活动暂时无法加载，请重试'
      }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.loading = false }
    }
  }

  @Builder
  activityCard(activity: PromotionActivity) {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 15 }) {
        Row() {
          Text(PromotionPresentation.status(activity, this.now)).fontSize(11).fontWeight(FontWeight.Medium)
            .fontColor(PromotionPresentation.canReserve(activity, this.now) ? AppColors.ACCENT : AppColors.TEXT_SECONDARY)
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .backgroundColor(PromotionPresentation.canReserve(activity, this.now) ? AppColors.ACCENT_SOFT : AppColors.SAND).borderRadius(AppRadius.PILL)
          Blank()
          Text(PromotionPresentation.phase(activity, this.now)).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
        }.width('100%')
        Column({ space: 7 }) {
          Text(activity.name).fontSize(22).lineHeight(30).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').textAlign(TextAlign.Start)
          Text(`${activity.productName} · ${activity.skuName}`).fontSize(13).lineHeight(20).fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').textAlign(TextAlign.Start)
        }.width('100%').alignItems(HorizontalAlign.Start)
        Divider().color(AppColors.DIVIDER)
        Row() {
          Column({ space: 3 }) {
            Text('活动价').fontSize(11).fontColor(AppColors.TEXT_SECONDARY)
            Text(`¥ ${activity.activityPrice.toFixed(2)}`).fontSize(27).fontWeight(FontWeight.Medium).fontColor(AppColors.ACCENT)
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Column({ space: 5 }) {
            Text(`每人限购 ${activity.limitPerUser} 件`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
            Text('查看活动  ›').fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
          }.alignItems(HorizontalAlign.End)
        }.width('100%').alignItems(VerticalAlign.Bottom)
      }.width('100%').padding(18)
    }.width('100%').padding(0).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
      .border({ width: 1, color: AppColors.DIVIDER }).onClick(() => this.onOpenDetail(activity.activityId))
      .accessibilityText(`查看活动：${activity.name}`)
  }

  build() {
    Column({ space: 16 }) {
      PageHeader({ title: '限量活动', subtitle: '价格与时间以服务端为准', actionLabel: '刷新', actionDisabled: this.loading,
        onBack: this.onBack, onAction: () => this.load() })
      Stack({ alignContent: Alignment.TopEnd }) {
        Circle().width(108).height(108).backgroundColor(AppColors.ACCENT_SOFT).opacity(0.72)
          .translate({ x: this.ambientShift ? 18 : -8, y: this.ambientShift ? -20 : 8 })
          .scale({ x: this.ambientShift ? 1.14 : 0.88, y: this.ambientShift ? 1.14 : 0.88 })
          .accessibilityLevel('no')
        Circle().width(76).height(76).backgroundColor(AppColors.BRAND_SOFT).opacity(0.8)
          .translate({ x: this.ambientShift ? -92 : -66, y: this.ambientShift ? 48 : 28 })
          .scale({ x: this.ambientShift ? 0.9 : 1.12, y: this.ambientShift ? 0.9 : 1.12 })
          .accessibilityLevel('no')
        Column({ space: 7 }) {
          Text('把握恰好的时机').fontSize(26).lineHeight(34).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
          Text('限量商品的资格、库存与订单均由服务端确认。').fontSize(13).lineHeight(21).fontColor(AppColors.TEXT_SECONDARY)
        }.width('100%').alignItems(HorizontalAlign.Start).padding(18)
      }.width('100%').backgroundColor(AppColors.SAND).borderRadius(AppRadius.CARD).clip(true)
        .opacity(this.heroVisible ? 1 : 0).translate({ y: this.heroVisible ? 0 : 16 })
      if (this.loading) {
        PageStateView({ type: PageStateType.Loading, title: '正在读取限量活动', description: '' })
      } else if (this.error.length > 0 && this.activities.length === 0) {
        PageStateView({ type: PageStateType.Error, title: '活动暂时无法加载', description: this.error, onAction: () => this.load() })
      } else if (this.activities.length === 0) {
        PageStateView({ type: PageStateType.Empty, title: '暂时没有限量活动', description: '新的精选活动准备好后会出现在这里。', actionLabel: '刷新看看', onAction: () => this.load() })
      } else {
        Scroll() {
          Column({ space: 14 }) {
            if (this.error.length > 0) { Text(this.error).fontSize(12).lineHeight(19).fontColor(AppColors.DANGER).width('100%') }
            ForEach(this.activities, (activity: PromotionActivity) => this.activityCard(activity),
              (activity: PromotionActivity) => activity.activityItemId.toString())
            Text('倒计时已按服务端时间校准。').fontSize(11).fontColor(AppColors.TEXT_SECONDARY).width('100%')
          }.width('100%').padding({ bottom: 24 }).opacity(this.listVisible ? 1 : 0)
            .translate({ y: this.listVisible ? 0 : 18 })
        }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').constraintSize({ maxWidth: AppSpacing.CONTENT_MAX }).alignSelf(ItemAlign.Center)
      .padding({ left: 18, right: 18, top: 8 }).backgroundColor(AppColors.BACKGROUND)
  }
}
