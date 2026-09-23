import { AfterSaleApi } from '../api/AfterSaleApi'
import { AfterSaleEligibleOrderItem, AfterSaleRequest } from '../model/AfterSaleModels'
import { QuantityStepper } from '../components/common/QuantityStepper'
import { PageHeader } from '../components/common/PageHeader'
import { PageStateType, PageStateView } from '../components/common/PageStateView'
import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { AfterSalePresentation } from '../utils/AfterSalePresentation'

@Component
export struct AfterSalesPage {
  onBack: () => void = () => {}
  @State records: AfterSaleRequest[] = []
  @State eligibleItems: AfterSaleEligibleOrderItem[] = []
  @State loading: boolean = true
  @State error: string = ''
  @State sheetVisible: boolean = false
  @State sheetMode: string = ''
  @State selectedItemId: number = 0
  @State quantity: number = 1
  @State reason: string = ''
  @State formError: string = ''
  @State submitting: boolean = false
  @State detail: AfterSaleRequest | null = null
  @State detailLoading: boolean = false
  @State detailError: string = ''
  private alive: boolean = false
  private requestSerial: number = 0
  private selectedDetailId: number = 0

  aboutToAppear(): void { this.alive = true; this.load() }
  aboutToDisappear(): void { this.alive = false; this.requestSerial++ }

  private async load(): Promise<void> {
    this.loading = true
    this.error = ''
    try {
      const records = await AfterSaleApi.list()
      const eligibleItems = await AfterSaleApi.eligibleOrders()
      if (this.alive) {
        this.records = records
        this.eligibleItems = eligibleItems
      }
    } catch (error) {
      if (this.alive) { this.error = error instanceof Error ? error.message : '售后记录加载失败，请重试' }
    } finally {
      if (this.alive) { this.loading = false }
    }
  }

  private selectedItem(): AfterSaleEligibleOrderItem | undefined {
    return this.eligibleItems.find((item: AfterSaleEligibleOrderItem) => item.orderItemId === this.selectedItemId)
  }

  private maximumQuantity(): number {
    const selected = this.selectedItem()
    return selected === undefined ? 0 : selected.purchasedQuantity
  }

  private openApply(): void {
    if (this.eligibleItems.length === 0 || this.submitting) { return }
    const first = this.eligibleItems[0]
    this.selectedItemId = first.orderItemId
    this.quantity = 1
    this.reason = ''
    this.formError = ''
    this.sheetMode = 'apply'
    this.sheetVisible = true
  }

  private selectItem(item: AfterSaleEligibleOrderItem): void {
    this.selectedItemId = item.orderItemId
    this.quantity = 1
    this.formError = ''
  }

  private async submit(): Promise<void> {
    const item = this.selectedItem()
    const reason = this.reason.trim()
    if (item === undefined) { this.formError = '请选择要申请售后的订单项'; return }
    if (this.quantity < 1 || this.quantity > item.purchasedQuantity) { this.formError = '申请数量需要在可申请范围内'; return }
    if (reason.length === 0) { this.formError = '请填写售后原因'; return }
    if (reason.length > 255) { this.formError = '售后原因不能超过 255 个字符'; return }

    this.submitting = true
    this.formError = ''
    try {
      const created = await AfterSaleApi.submit(item.orderItemId, this.quantity, reason)
      if (!this.alive) { return }
      this.sheetVisible = false
      await this.load()
      if (this.alive) { await this.openDetail(created.id) }
    } catch (error) {
      if (this.alive) {
        this.formError = error instanceof Error ? error.message : '提交结果未确认，请先查看售后记录后再决定是否重试'
      }
    } finally {
      if (this.alive) { this.submitting = false }
    }
  }

  private async openDetail(id: number): Promise<void> {
    const serial = ++this.requestSerial
    this.selectedDetailId = id
    this.detail = null
    this.detailError = ''
    this.detailLoading = true
    this.sheetMode = 'detail'
    this.sheetVisible = true
    try {
      const detail = await AfterSaleApi.get(id)
      if (this.alive && serial === this.requestSerial) { this.detail = detail }
    } catch (error) {
      if (this.alive && serial === this.requestSerial) {
        this.detailError = error instanceof Error ? error.message : '售后详情读取失败，请重试'
      }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.detailLoading = false }
    }
  }

  private statusColor(status: string): string {
    if (status === 'REJECTED') { return AppColors.DANGER }
    if (status === 'APPROVED') { return AppColors.SUCCESS }
    return AppColors.ACCENT
  }

  @Builder
  applySheet() {
    Column({ space: 16 }) {
      Row() {
        Text('申请售后').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND).layoutWeight(1)
        Button('×', { type: ButtonType.Normal }).width(44).height(44).padding(0).fontSize(25)
          .backgroundColor(Color.Transparent).fontColor(AppColors.BRAND).enabled(!this.submitting)
          .accessibilityText('关闭售后申请').onClick(() => this.sheetVisible = false)
      }.width('100%')
      Text('仅显示后端确认的已付款订单项；最终审核与金额以后端结果为准。').fontSize(12).lineHeight(20).fontColor(AppColors.TEXT_SECONDARY).width('100%')
      Scroll() {
        Column({ space: 10 }) {
          ForEach(this.eligibleItems, (item: AfterSaleEligibleOrderItem) => {
            Button({ type: ButtonType.Normal }) {
              Row({ space: 12 }) {
                Column({ space: 5 }) {
                  Text(`订单 #${item.orderId}`).fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                  Text(`订单项 #${item.orderItemId} · 已购 ${item.purchasedQuantity} 件`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Text(`¥ ${item.salePrice.toFixed(2)}`).fontSize(14).fontColor(AppColors.ACCENT)
              }.width('100%').padding(14)
            }.width('100%').padding(0).backgroundColor(this.selectedItemId === item.orderItemId ? AppColors.BRAND_SOFT : AppColors.SURFACE)
              .border({ width: 1, color: this.selectedItemId === item.orderItemId ? AppColors.BRAND : AppColors.DIVIDER })
              .borderRadius(AppRadius.CONTROL).enabled(!this.submitting).onClick(() => this.selectItem(item))
          }, (item: AfterSaleEligibleOrderItem) => item.orderItemId.toString())
        }.width('100%')
      }.width('100%').constraintSize({ maxHeight: 210 }).scrollBar(BarState.Off)
      if (this.maximumQuantity() > 0) {
        Row() {
          Column({ space: 4 }) {
            Text('申请数量').fontSize(14).fontColor(AppColors.TEXT_PRIMARY)
            Text(`最多 ${this.maximumQuantity()} 件`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          QuantityStepper({ value: this.quantity, maximum: this.maximumQuantity(), disabled: this.submitting,
            onChange: (value: number) => { this.quantity = value; this.formError = '' } })
        }.width('100%').padding(14).backgroundColor(AppColors.SAND).borderRadius(AppRadius.CONTROL)
      }
      Column({ space: 8 }) {
        Text('售后原因').fontSize(14).fontColor(AppColors.TEXT_PRIMARY)
        TextArea({ text: this.reason, placeholder: '请说明遇到的问题，最多 255 个字符' }).maxLength(255).width('100%').height(104)
          .backgroundColor(AppColors.BACKGROUND).borderRadius(AppRadius.CONTROL).enabled(!this.submitting)
          .accessibilityText('售后原因')
          .onChange((value: string) => { this.reason = value; this.formError = '' })
      }.width('100%').alignItems(HorizontalAlign.Start)
      if (this.formError.length > 0) { Text(this.formError).fontSize(12).lineHeight(19).fontColor(AppColors.DANGER).width('100%') }
      Button(this.submitting ? '正在提交…' : '提交售后申请').width('100%').height(48).backgroundColor(AppColors.BRAND)
        .fontColor(AppColors.SURFACE).borderRadius(AppRadius.CONTROL).enabled(!this.submitting).onClick(() => this.submit())
    }.width('100%').height('100%').padding({ left: 22, right: 22, bottom: 24 })
  }

  @Builder
  detailSheet() {
    Column({ space: 16 }) {
      Row() {
        Text('售后详情').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND).layoutWeight(1)
        Button('×', { type: ButtonType.Normal }).width(44).height(44).padding(0).fontSize(25)
          .backgroundColor(Color.Transparent).fontColor(AppColors.BRAND).accessibilityText('关闭售后详情')
          .onClick(() => { this.sheetVisible = false; this.requestSerial++ })
      }.width('100%')
      if (this.detailLoading) {
        PageStateView({ type: PageStateType.Loading, title: '正在读取售后详情', description: '' })
      } else if (this.detail === null) {
        PageStateView({ type: PageStateType.Error, title: '暂时无法打开售后记录', description: this.detailError,
          onAction: () => { if (this.selectedDetailId > 0) { this.openDetail(this.selectedDetailId) } } })
      } else {
        Scroll() {
          Column({ space: 18 }) {
            Column({ space: 8 }) {
              Text(AfterSalePresentation.status(this.detail.status)).fontSize(25).fontWeight(FontWeight.Medium)
                .fontColor(this.statusColor(this.detail.status))
              Text(this.detail.status === 'APPROVED' ? '审核通过不代表退款已到账，当前版本尚未接入退款服务。' :
                this.detail.status === 'REJECTED' ? '申请未通过，可查看商家说明或联系商家。' : '申请已提交，等待商家处理。')
                .fontSize(13).lineHeight(21).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%').alignItems(HorizontalAlign.Start).padding(18).backgroundColor(AppColors.BRAND_SOFT).borderRadius(AppRadius.CARD)
            Text('申请编号  ' + this.detail.requestNo).fontSize(13).fontColor(AppColors.TEXT_SECONDARY).width('100%').copyOption(CopyOptions.InApp)
            Text('关联订单  #' + this.detail.orderId + ' · 订单项 #' + this.detail.orderItemId).fontSize(13).fontColor(AppColors.TEXT_SECONDARY).width('100%')
            Divider().color(AppColors.DIVIDER)
            Column({ space: 8 }) {
              Text('申请原因').fontSize(16).fontColor(AppColors.BRAND)
              Text(this.detail.reason).fontSize(14).lineHeight(22).fontColor(AppColors.TEXT_PRIMARY)
            }.width('100%').alignItems(HorizontalAlign.Start)
            Row() {
              Text('申请数量').fontSize(14).fontColor(AppColors.TEXT_SECONDARY).layoutWeight(1)
              Text(this.detail.quantity + ' 件').fontSize(15).fontColor(AppColors.TEXT_PRIMARY)
            }.width('100%')
            Row() {
              Text('申请金额').fontSize(14).fontColor(AppColors.TEXT_SECONDARY).layoutWeight(1)
              Text('¥ ' + this.detail.requestedAmount.toFixed(2)).fontSize(22).fontWeight(FontWeight.Medium).fontColor(AppColors.ACCENT)
            }.width('100%')
            Divider().color(AppColors.DIVIDER)
            Column({ space: 8 }) {
              Text('商家说明').fontSize(16).fontColor(AppColors.BRAND)
              Text(this.detail.merchantRemark ?? '商家暂未留言').fontSize(13).lineHeight(21).fontColor(AppColors.TEXT_SECONDARY)
              Text('提交时间  ' + AfterSalePresentation.date(this.detail.createdAt)).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
              if (this.detail.decidedAt !== null) { Text('处理时间  ' + AfterSalePresentation.date(this.detail.decidedAt)).fontSize(12).fontColor(AppColors.TEXT_SECONDARY) }
            }.width('100%').alignItems(HorizontalAlign.Start)
          }.width('100%').padding({ bottom: 24 })
        }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').padding({ left: 22, right: 22, bottom: 24 })
  }

  @Builder
  sheetContent() {
    if (this.sheetMode === 'apply') {
      this.applySheet()
    } else {
      this.detailSheet()
    }
  }

  build() {
    Column({ space: AppSpacing.ITEM }) {
      PageHeader({ title: '售后服务', subtitle: '查询记录或提交新的售后申请', actionLabel: '申请售后',
        actionDisabled: this.loading || this.eligibleItems.length === 0, onBack: this.onBack, onAction: () => this.openApply() })
      if (this.loading) {
        PageStateView({ type: PageStateType.Loading, title: '正在读取售后记录', description: '' })
      } else if (this.error.length > 0 && this.records.length === 0) {
        PageStateView({ type: PageStateType.Error, title: '售后记录暂时无法加载', description: this.error, onAction: () => this.load() })
      } else if (this.records.length === 0) {
        PageStateView({ type: PageStateType.Empty, title: this.eligibleItems.length > 0 ? '还没有售后记录' : '暂无可申请的售后',
          description: this.eligibleItems.length > 0 ? '已付款订单项可在这里提交售后申请。' : '仅后端确认的已付款订单项可申请售后。',
          actionLabel: this.eligibleItems.length > 0 ? '申请售后' : '刷新', onAction: () => this.eligibleItems.length > 0 ? this.openApply() : this.load() })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.error.length > 0) { Text(this.error).fontSize(12).lineHeight(19).fontColor(AppColors.DANGER).width('100%') }
            if (this.eligibleItems.length > 0) {
              Button('你有可申请售后的已付款订单项  ›', { type: ButtonType.Normal }).width('100%').height(44).fontSize(13)
                .backgroundColor(AppColors.BRAND_SOFT).fontColor(AppColors.BRAND).borderRadius(AppRadius.CONTROL).onClick(() => this.openApply())
            }
            ForEach(this.records, (record: AfterSaleRequest) => {
              Button({ type: ButtonType.Normal }) {
                Column({ space: 12 }) {
                  Row() {
                    Text(AfterSalePresentation.date(record.createdAt)).fontSize(12).fontColor(AppColors.TEXT_SECONDARY).layoutWeight(1)
                    Text(AfterSalePresentation.status(record.status)).fontSize(12).fontColor(this.statusColor(record.status))
                      .padding({ left: 9, right: 9, top: 5, bottom: 5 }).backgroundColor(AppColors.BRAND_SOFT).borderRadius(AppRadius.PILL)
                  }.width('100%')
                  Divider().color(AppColors.DIVIDER)
                  Text(record.reason).fontSize(16).lineHeight(23).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontColor(AppColors.TEXT_PRIMARY).width('100%').textAlign(TextAlign.Start)
                  Row() {
                    Text(`订单 #${record.orderId} · ${record.quantity} 件`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
                    Blank()
                    Text(`¥ ${record.requestedAmount.toFixed(2)}`).fontSize(19).fontWeight(FontWeight.Medium).fontColor(AppColors.ACCENT)
                  }.width('100%')
                }.width('100%').padding(AppSpacing.CARD)
              }.width('100%').padding(0).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
                .border({ width: 1, color: AppColors.DIVIDER }).onClick(() => this.openDetail(record.id))
            }, (record: AfterSaleRequest) => record.id.toString())
          }.width('100%').padding({ bottom: 24 })
        }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').constraintSize({ maxWidth: AppSpacing.CONTENT_MAX }).alignSelf(ItemAlign.Center)
      .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL, top: 12 }).backgroundColor(AppColors.BACKGROUND)
      .bindSheet($$this.sheetVisible, this.sheetContent(), { height: SheetSize.LARGE, showClose: false, backgroundColor: AppColors.SURFACE,
        shouldDismiss: (action: SheetDismiss) => {
          if (this.sheetMode !== 'apply' || !this.submitting) {
            if (this.sheetMode === 'detail') { this.requestSerial++ }
            action.dismiss()
          }
        } })
  }
}
