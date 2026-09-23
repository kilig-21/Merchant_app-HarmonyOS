import { PromotionApi } from '../api/PromotionApi'
import { PromotionActivity, PromotionReservationDetail } from '../model/PromotionModels'
import { QuantityStepper } from '../components/common/QuantityStepper'
import { PageHeader } from '../components/common/PageHeader'
import { PageStateType, PageStateView } from '../components/common/PageStateView'
import { ApiError, ApiErrorKind } from '../network/ApiError'
import { AppColors, AppRadius } from '../theme/AppTheme'
import { PromotionPresentation } from '../utils/PromotionPresentation'
import { PromotionReservationIntent } from '../viewmodel/PromotionReservationIntent'

@Component
export struct PromotionDetailPage {
  @Prop activityId: number = 0
  @Prop signedIn: boolean = false
  onBack: () => void = () => {}
  onLogin: () => void = () => {}
  onOpenOrders: () => void = () => {}
  @State activity: PromotionActivity | null = null
  @State loading: boolean = true
  @State error: string = ''
  @State now: number = Date.now()
  @State quantity: number = 1
  @State reservations: PromotionReservationDetail[] = []
  @State reservationLoading: boolean = false
  @State reservationError: string = ''
  @State submitting: boolean = false
  @State outcomeUncertain: boolean = false
  @State polling: boolean = false
  private alive: boolean = false
  private requestSerial: number = 0
  private serverOffsetMs: number = 0
  private clockTimer: number = -1
  private pollTimer: number = -1
  private pollSerial: number = 0
  private intent: PromotionReservationIntent = new PromotionReservationIntent()

  aboutToAppear(): void {
    this.alive = true
    this.clockTimer = setInterval(() => this.now = Date.now() + this.serverOffsetMs, 1000)
    this.load()
  }

  aboutToDisappear(): void {
    this.alive = false
    this.requestSerial++
    this.pollSerial++
    clearInterval(this.clockTimer)
    clearTimeout(this.pollTimer)
    this.clockTimer = -1
    this.pollTimer = -1
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
      if (this.signedIn) { await this.loadReservations() }
    } catch (error) {
      if (this.alive && serial === this.requestSerial) {
        this.error = error instanceof Error ? error.message : '活动详情读取失败，请重试'
      }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.loading = false }
    }
  }

  private reservedQuantity(): number {
    return this.reservations
      .filter((item: PromotionReservationDetail) => item.reservationStatus !== 'FAILED')
      .reduce((total: number, item: PromotionReservationDetail) => total + item.quantity, 0)
  }

  private maximumQuantity(): number {
    if (this.activity === null) { return 0 }
    return Math.max(0, this.activity.limitPerUser - this.reservedQuantity())
  }

  private async loadReservations(): Promise<void> {
    if (!this.signedIn || this.activityId <= 0 || this.reservationLoading) { return }
    this.reservationLoading = true
    this.reservationError = ''
    try {
      const reservations = await PromotionApi.listReservations(this.activityId)
      if (this.alive) {
        this.reservations = reservations
        const maximum = this.maximumQuantity()
        if (maximum > 0 && this.quantity > maximum) { this.quantity = maximum }
      }
    } catch (error) {
      if (this.alive) { this.reservationError = error instanceof Error ? error.message : '资格记录读取失败，请重试' }
    } finally {
      if (this.alive) { this.reservationLoading = false }
    }
  }

  private async reserve(): Promise<void> {
    if (this.activity === null || this.submitting || !this.signedIn) { return }
    if (!PromotionPresentation.canReserve(this.activity, this.now)) { this.reservationError = '当前活动暂不可抢购，请刷新活动状态'; return }
    if (this.quantity < 1 || this.quantity > this.maximumQuantity()) { this.reservationError = '抢购数量超过当前可申请范围'; return }
    const request = this.intent.begin(this.activity.activityItemId, this.quantity)
    this.submitting = true
    this.reservationError = ''
    try {
      const result = await PromotionApi.reserve(request)
      if (!this.alive) { return }
      if ((result.code !== 1 && result.code !== 2) || result.reservationId.length === 0) {
        throw new Error('服务端未返回有效抢购资格')
      }
      this.outcomeUncertain = false
      await this.pollReservation(result.reservationId, 0, ++this.pollSerial)
    } catch (error) {
      if (!this.alive) { return }
      if (error instanceof ApiError && error.kind === ApiErrorKind.Business) {
        this.intent.reset()
        this.outcomeUncertain = false
        this.reservationError = error.message
      } else {
        this.outcomeUncertain = true
        this.reservationError = '提交结果暂未确认。再次点击会使用同一请求，不会重复占用资格。'
      }
    } finally {
      if (this.alive) { this.submitting = false }
    }
  }

  private async pollReservation(reservationId: string, attempt: number, serial: number): Promise<void> {
    if (!this.alive || serial !== this.pollSerial) { return }
    this.polling = true
    try {
      const detail = await PromotionApi.getReservation(reservationId)
      if (!this.alive || serial !== this.pollSerial) { return }
      this.upsertReservation(detail)
      if (detail.reservationStatus !== 'PENDING_ORDER') {
        this.polling = false
        this.intent.reset()
        await this.loadReservations()
        return
      }
    } catch (error) {
      if (this.alive && serial === this.pollSerial) {
        this.reservationError = error instanceof Error ? error.message : '资格结果暂时无法读取'
      }
    }
    if (!this.alive || serial !== this.pollSerial) { return }
    if (attempt >= 3) {
      this.polling = false
      this.reservationError = '已获得资格，订单仍在创建。可稍后刷新结果。'
      return
    }
    const nextAttempt = attempt + 1
    this.pollTimer = setTimeout(() => this.pollReservation(reservationId, nextAttempt, serial), nextAttempt * 1000)
  }

  private upsertReservation(detail: PromotionReservationDetail): void {
    const others = this.reservations.filter((item: PromotionReservationDetail) => item.reservationId !== detail.reservationId)
    this.reservations = [detail].concat(others)
  }

  private async refreshResults(): Promise<void> {
    clearTimeout(this.pollTimer)
    this.pollSerial++
    this.polling = false
    await this.loadReservations()
  }

  @Builder
  reservationCard(item: PromotionReservationDetail) {
    Column({ space: 10 }) {
      Row() {
        Text(PromotionPresentation.reservationStatus(item.reservationStatus)).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(item.reservationStatus === 'FAILED' ? AppColors.DANGER : AppColors.BRAND)
        Blank()
        Text(`${item.quantity} 件`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
      }.width('100%')
      Text(`资格编号  ${item.reservationId}`).fontSize(11).fontColor(AppColors.TEXT_SECONDARY).width('100%')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).copyOption(CopyOptions.InApp)
      if (item.reservationStatus === 'ORDER_CREATED' && item.orderNo !== null) {
        Row() {
          Column({ space: 4 }) {
            Text(`订单号  ${item.orderNo}`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
            Text(`¥ ${item.totalAmount.toFixed(2)}`).fontSize(18).fontColor(AppColors.ACCENT)
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          Button('查看订单', { type: ButtonType.Normal }).height(40).padding({ left: 13, right: 13 })
            .backgroundColor(AppColors.BRAND_SOFT).fontColor(AppColors.BRAND).borderRadius(AppRadius.CONTROL).onClick(() => this.onOpenOrders())
        }.width('100%')
      } else if (item.reservationStatus === 'PENDING_ORDER') {
        Text('资格已确认，系统正在异步创建订单，请勿重复抢购。').fontSize(12).lineHeight(19).fontColor(AppColors.TEXT_SECONDARY).width('100%')
      } else if (item.reservationStatus === 'FAILED') {
        Text('订单创建未完成，服务端会按补偿规则处理资格和库存。').fontSize(12).lineHeight(19).fontColor(AppColors.DANGER).width('100%')
      }
    }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CONTROL)
      .border({ width: 1, color: AppColors.DIVIDER })
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
            Column({ space: 14 }) {
              Row() {
                Text('参与抢购').fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
                Blank()
                if (this.signedIn && this.maximumQuantity() > 0) {
                  Text(`还可申请 ${this.maximumQuantity()} 件`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
                }
              }.width('100%')
              if (!this.signedIn) {
                Text('登录消费者账号后即可申请抢购资格。').fontSize(13).lineHeight(21).fontColor(AppColors.TEXT_SECONDARY).width('100%')
                Button('登录后参与', { type: ButtonType.Normal }).width('100%').height(48).backgroundColor(AppColors.BRAND)
                  .fontColor(AppColors.SURFACE).borderRadius(AppRadius.CONTROL).onClick(() => this.onLogin())
              } else if (this.maximumQuantity() <= 0) {
                Text('当前账号已达到本活动限购数量。').fontSize(13).lineHeight(21).fontColor(AppColors.TEXT_SECONDARY).width('100%')
              } else {
                Row() {
                  Text('抢购数量').fontSize(14).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
                  QuantityStepper({ value: this.quantity, maximum: this.maximumQuantity(), disabled: this.submitting || this.polling || this.outcomeUncertain,
                    onChange: (value: number) => { this.quantity = value; this.reservationError = '' } })
                }.width('100%').padding(14).backgroundColor(AppColors.BACKGROUND).borderRadius(AppRadius.CONTROL)
                Button(this.submitting ? '资格确认中…' : this.outcomeUncertain ? '使用原请求重试' : '尝试抢购', { type: ButtonType.Normal })
                  .width('100%').height(48).backgroundColor(AppColors.BRAND).fontColor(AppColors.SURFACE).borderRadius(AppRadius.CONTROL)
                  .enabled(!this.submitting && !this.polling && PromotionPresentation.canReserve(this.activity, this.now))
                  .onClick(() => this.reserve())
              }
              if (this.reservationError.length > 0) {
                Text(this.reservationError).fontSize(12).lineHeight(19)
                  .fontColor(this.outcomeUncertain ? AppColors.ACCENT : AppColors.DANGER).width('100%')
              }
            }.width('100%').alignItems(HorizontalAlign.Start).padding(18).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
            if (this.signedIn) {
              Column({ space: 12 }) {
                Row() {
                  Text('我的抢购结果').fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
                  Blank()
                  Button(this.reservationLoading ? '刷新中…' : '刷新结果', { type: ButtonType.Normal }).height(40)
                    .padding({ left: 12, right: 12 }).backgroundColor(AppColors.BRAND_SOFT).fontColor(AppColors.BRAND)
                    .borderRadius(AppRadius.CONTROL).enabled(!this.reservationLoading && !this.polling).onClick(() => this.refreshResults())
                }.width('100%')
                if (this.reservationLoading && this.reservations.length === 0) {
                  Text('正在读取资格与订单结果…').fontSize(13).fontColor(AppColors.TEXT_SECONDARY).width('100%')
                } else if (this.reservations.length === 0) {
                  Text('还没有本活动的抢购记录。').fontSize(13).fontColor(AppColors.TEXT_SECONDARY).width('100%')
                } else {
                  ForEach(this.reservations, (item: PromotionReservationDetail) => this.reservationCard(item),
                    (item: PromotionReservationDetail) => item.reservationId)
                }
              }.width('100%').alignItems(HorizontalAlign.Start)
            }
          }.width('100%').padding({ bottom: 24 })
        }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').padding({ left: 18, right: 18, top: 8 }).backgroundColor(AppColors.BACKGROUND)
  }
}
