import { AddressApi } from '../api/AddressApi'
import { Address, AddressRequest } from '../model/CheckoutModels'
import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { PageStateType, PageStateView } from '../components/common/PageStateView'

@Component
export struct AddressManagerPage {
  onBack: () => void = () => {}
  @State addresses: Address[] = []
  @State loading: boolean = true
  @State error: string = ''
  @State editorVisible: boolean = false
  @State editingId: number = 0
  @State receiverName: string = ''
  @State receiverPhone: string = ''
  @State province: string = ''
  @State city: string = ''
  @State district: string = ''
  @State detailAddress: string = ''
  @State isDefault: boolean = true
  @State saving: boolean = false
  @State formError: string = ''

  aboutToAppear(): void { this.load() }

  private async load(): Promise<void> {
    this.loading = true
    this.error = ''
    try { this.addresses = await AddressApi.list() }
    catch (error) { this.error = error instanceof Error ? error.message : '地址加载失败，请重试' }
    finally { this.loading = false }
  }

  private openEditor(address?: Address): void {
    this.editingId = address?.id ?? 0
    this.receiverName = address?.receiverName ?? ''
    this.receiverPhone = address?.receiverPhone ?? ''
    this.province = address?.province ?? ''
    this.city = address?.city ?? ''
    this.district = address?.district ?? ''
    this.detailAddress = address?.detailAddress ?? ''
    this.isDefault = address?.isDefault ?? this.addresses.length === 0
    this.formError = ''
    this.editorVisible = true
  }

  private valid(): boolean {
    if (this.receiverName.trim().length === 0 || this.receiverName.length > 64) { this.formError = '请填写不超过 64 字的收货人姓名'; return false }
    if (this.receiverPhone.trim().length === 0 || this.receiverPhone.length > 32) { this.formError = '请填写不超过 32 字的联系电话'; return false }
    if (this.province.trim().length === 0 || this.city.trim().length === 0 || this.district.trim().length === 0) { this.formError = '请完整填写省、市、区'; return false }
    if (this.detailAddress.trim().length === 0 || this.detailAddress.length > 255) { this.formError = '请填写不超过 255 字的详细地址'; return false }
    return true
  }

  private async save(): Promise<void> {
    if (this.saving || !this.valid()) { return }
    this.saving = true
    this.formError = ''
    const request = new AddressRequest(this.receiverName.trim(), this.receiverPhone.trim(), this.province.trim(), this.city.trim(), this.district.trim(), this.detailAddress.trim(), this.isDefault)
    try {
      if (this.editingId === 0) { await AddressApi.create(request) } else { await AddressApi.update(this.editingId, request) }
      this.editorVisible = false
      await this.load()
    } catch (error) { this.formError = error instanceof Error ? error.message : '地址保存失败，请重试' }
    finally { this.saving = false }
  }

  private confirmRemove(address: Address): void {
    this.getUIContext().showAlertDialog({
      title: '删除该地址？', message: `${address.receiverName} · ${address.receiverPhone}`,
      primaryButton: { value: '保留', action: () => {} },
      secondaryButton: { value: '删除', fontColor: AppColors.DANGER, action: () => this.remove(address.id) }
    })
  }

  private async remove(id: number): Promise<void> {
    try { await AddressApi.remove(id); await this.load() }
    catch (error) { this.error = error instanceof Error ? error.message : '地址删除失败，请重试' }
  }

  @Builder
  editor() {
    Column({ space: 12 }) {
      Row() {
        Text(this.editingId === 0 ? '新增收货地址' : '编辑收货地址').fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
        Text('×').fontSize(24).fontColor(AppColors.TEXT_SECONDARY).padding(5).onClick(() => this.editorVisible = false)
      }.width('100%')
      TextInput({ text: this.receiverName, placeholder: '收货人姓名' }).width('100%').height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12).onChange((value: string) => this.receiverName = value)
      TextInput({ text: this.receiverPhone, placeholder: '联系电话' }).width('100%').height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12).onChange((value: string) => this.receiverPhone = value)
      TextInput({ text: this.province, placeholder: '省' }).width('100%').height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12).onChange((value: string) => this.province = value)
      TextInput({ text: this.city, placeholder: '市' }).width('100%').height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12).onChange((value: string) => this.city = value)
      TextInput({ text: this.district, placeholder: '区' }).width('100%').height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12).onChange((value: string) => this.district = value)
      TextInput({ text: this.detailAddress, placeholder: '街道、门牌号等详细地址' }).width('100%').height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12).onChange((value: string) => this.detailAddress = value)
      Row({ space: 8 }) {
        Checkbox({ name: 'address-default' }).select(this.isDefault).shape(CheckBoxShape.CIRCLE).selectedColor(AppColors.BRAND).onChange((value: boolean) => this.isDefault = value)
        Text('设为默认地址').fontSize(13).fontColor(AppColors.TEXT_PRIMARY)
      }.width('100%')
      if (this.formError.length > 0) { Text(this.formError).width('100%').fontSize(12).fontColor(AppColors.DANGER) }
      Button(this.saving ? '正在保存…' : '保存地址').width('100%').height(46).backgroundColor(AppColors.BRAND).fontColor('#FFFFFF').borderRadius(AppRadius.CONTROL).enabled(!this.saving).onClick(() => this.save())
    }.width('100%').padding(AppSpacing.CARD)
  }

  build() {
    Column({ space: AppSpacing.ITEM }) {
      Row() {
        Text('‹').fontSize(32).width(42).height(42).textAlign(TextAlign.Center).fontColor(AppColors.TEXT_PRIMARY).onClick(this.onBack)
        Column({ space: 2 }) { Text('收货地址').fontSize(19).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY); Text('配送信息仅用于订单收货').fontSize(10).fontColor(AppColors.TEXT_TERTIARY) }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Button('新增', { type: ButtonType.Normal }).height(36).fontSize(13).backgroundColor(AppColors.BRAND).fontColor('#FFFFFF').borderRadius(15).onClick(() => this.openEditor())
      }.width('100%')
      if (this.loading) {
        PageStateView({ type: PageStateType.Loading, title: '正在读取地址', description: '稍等片刻。' })
      } else if (this.error.length > 0 && this.addresses.length === 0) {
        PageStateView({ type: PageStateType.Error, title: '地址暂时无法加载', description: this.error, onAction: () => this.load() })
      } else if (this.addresses.length === 0) {
        PageStateView({ type: PageStateType.Empty, title: '还没有收货地址', description: '新增地址后即可在确认订单时选择。', actionLabel: '新增地址', onAction: () => this.openEditor() })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.error.length > 0) { Text(this.error).width('100%').fontSize(12).fontColor(AppColors.DANGER) }
            ForEach(this.addresses, (address: Address) => {
              Column({ space: 9 }) {
                Row({ space: 8 }) {
                  Text(address.receiverName).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                  Text(address.receiverPhone).fontSize(13).fontColor(AppColors.TEXT_SECONDARY).layoutWeight(1)
                  if (address.isDefault) { Text('默认').fontSize(10).fontColor(AppColors.BRAND).padding({ left: 7, right: 7, top: 3, bottom: 3 }).backgroundColor(AppColors.BRAND_SOFT).borderRadius(8) }
                }.width('100%')
                Text(`${address.province}${address.city}${address.district}${address.detailAddress}`).width('100%').fontSize(13).lineHeight(20).fontColor(AppColors.TEXT_SECONDARY)
                Row() { Blank(); Text('编辑').fontSize(12).fontColor(AppColors.BRAND).padding(6).onClick(() => this.openEditor(address)); Text('删除').fontSize(12).fontColor(AppColors.DANGER).padding(6).onClick(() => this.confirmRemove(address)) }.width('100%')
              }.width('100%').padding(AppSpacing.CARD).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD).border({ width: 1, color: AppColors.DIVIDER })
            }, (address: Address) => address.id.toString())
          }.width('100%').padding({ top: 4, bottom: 22 })
        }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
      }
      Blank().height(76)
    }.width('100%').height('100%').padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL, top: 12 }).backgroundColor(AppColors.BACKGROUND)
      .bindSheet($$this.editorVisible, this.editor(), { height: SheetSize.LARGE, showClose: false, backgroundColor: AppColors.SURFACE })
  }
}
