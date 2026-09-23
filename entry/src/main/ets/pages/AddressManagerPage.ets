import { AddressApi } from '../api/AddressApi'
import { Address, AddressRequest } from '../model/CheckoutModels'
import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { PageStateType, PageStateView } from '../components/common/PageStateView'
import { PageHeader } from '../components/common/PageHeader'

@Component
export struct AddressManagerPage {
  onBack: () => void = () => {}
  onChanged: () => void = () => {}
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
  @State removingId: number = 0
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

  private changed(): void { this.formError = '' }

  private valid(): boolean {
    if (this.receiverName.trim().length === 0 || this.receiverName.length > 64) { this.formError = '请填写不超过 64 字的收货人姓名'; return false }
    if (this.receiverPhone.trim().length === 0 || this.receiverPhone.length > 32) { this.formError = '请填写不超过 32 字的联系电话'; return false }
    if (this.province.trim().length === 0 || this.city.trim().length === 0 || this.district.trim().length === 0) { this.formError = '请完整填写省、市、区'; return false }
    if (this.province.length > 64 || this.city.length > 64 || this.district.length > 64) { this.formError = '省、市、区各不能超过 64 字'; return false }
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
      this.onChanged()
      try { this.getUIContext().getPromptAction().showToast({ message: '地址已保存' }) } catch (_) {}
    } catch (error) { this.formError = error instanceof Error ? error.message : '地址保存失败，请重试' }
    finally { this.saving = false }
  }

  private confirmRemove(address: Address): void {
    if (this.removingId !== 0 || this.saving) { return }
    this.getUIContext().showAlertDialog({
      title: '删除该地址？', message: `${address.receiverName} · ${address.receiverPhone}`,
      primaryButton: { value: '保留', action: () => {} },
      secondaryButton: { value: '删除', fontColor: AppColors.DANGER, action: () => this.remove(address.id) }
    })
  }

  private async remove(id: number): Promise<void> {
    if (this.removingId !== 0) { return }
    this.removingId = id
    try { await AddressApi.remove(id); await this.load(); this.onChanged() }
    catch (error) { this.error = error instanceof Error ? error.message : '地址删除失败，请重试' }
    finally { this.removingId = 0 }
  }

  @Builder
  editor() {
    Scroll() {
    Column({ space: 12 }) {
      Row() {
        Text(this.editingId === 0 ? '新增收货地址' : '编辑收货地址').fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
        Button('×', { type: ButtonType.Normal }).width(44).height(44).padding(0).fontSize(24).backgroundColor(Color.Transparent)
          .fontColor(AppColors.TEXT_SECONDARY).enabled(!this.saving).onClick(() => this.editorVisible = false).accessibilityText('关闭地址编辑')
      }.width('100%')
      Text('收货人').fontSize(13).fontColor(AppColors.TEXT_PRIMARY).width('100%')
      TextInput({ text: this.receiverName, placeholder: '填写收货人姓名' }).maxLength(64).width('100%').height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12)
        .fontSize(14).fontColor(AppColors.TEXT_PRIMARY).placeholderColor(AppColors.TEXT_SECONDARY).caretColor(AppColors.BRAND)
        .onChange((value: string) => { this.receiverName = value; this.changed() })
      Text('联系电话').fontSize(13).fontColor(AppColors.TEXT_PRIMARY).width('100%')
      TextInput({ text: this.receiverPhone, placeholder: '填写联系电话' }).type(InputType.PhoneNumber).maxLength(32).width('100%').height(48).backgroundColor(AppColors.BACKGROUND).borderRadius(12)
        .fontSize(14).fontColor(AppColors.TEXT_PRIMARY).placeholderColor(AppColors.TEXT_SECONDARY).caretColor(AppColors.BRAND)
        .onChange((value: string) => { this.receiverPhone = value; this.changed() })
      Text('所在地区').fontSize(13).fontColor(AppColors.TEXT_PRIMARY).width('100%').margin({ top: 4 })
      Row({ space: 8 }) {
        TextInput({ text: this.province, placeholder: '省' }).maxLength(64).layoutWeight(1).height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12)
          .fontSize(14).fontColor(AppColors.TEXT_PRIMARY).placeholderColor(AppColors.TEXT_SECONDARY).caretColor(AppColors.BRAND)
          .onChange((value: string) => { this.province = value; this.changed() })
        TextInput({ text: this.city, placeholder: '市' }).maxLength(64).layoutWeight(1).height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12)
          .fontSize(14).fontColor(AppColors.TEXT_PRIMARY).placeholderColor(AppColors.TEXT_SECONDARY).caretColor(AppColors.BRAND)
          .onChange((value: string) => { this.city = value; this.changed() })
        TextInput({ text: this.district, placeholder: '区' }).maxLength(64).layoutWeight(1).height(44).backgroundColor(AppColors.BACKGROUND).borderRadius(12)
          .fontSize(14).fontColor(AppColors.TEXT_PRIMARY).placeholderColor(AppColors.TEXT_SECONDARY).caretColor(AppColors.BRAND)
          .onChange((value: string) => { this.district = value; this.changed() })
      }.width('100%')
      Text('详细地址').fontSize(13).fontColor(AppColors.TEXT_PRIMARY).width('100%').margin({ top: 4 })
      TextArea({ text: this.detailAddress, placeholder: '填写街道、门牌号等详细地址' }).maxLength(255).width('100%').height(88)
        .fontSize(14).fontColor(AppColors.TEXT_PRIMARY).placeholderColor(AppColors.TEXT_SECONDARY)
        .backgroundColor(AppColors.BACKGROUND).borderRadius(AppRadius.CONTROL)
        .onChange((value: string) => { this.detailAddress = value; this.changed() })
      Row({ space: 8 }) {
        Checkbox({ name: 'address-default' }).select(this.isDefault).shape(CheckBoxShape.CIRCLE).selectedColor(AppColors.BRAND)
          .onChange((value: boolean) => { this.isDefault = value; this.changed() }).accessibilityText('设为默认地址')
        Text('设为默认地址').fontSize(13).fontColor(AppColors.TEXT_PRIMARY)
      }.width('100%')
      if (this.formError.length > 0) { Text(this.formError).width('100%').fontSize(12).fontColor(AppColors.DANGER) }
      Button(this.saving ? '正在保存…' : '保存地址').width('100%').height(46).backgroundColor(AppColors.BRAND).fontColor('#FFFFFF').borderRadius(AppRadius.CONTROL).enabled(!this.saving).onClick(() => this.save())
    }.width('100%').padding(AppSpacing.CARD).enabled(!this.saving)
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
  }

  build() {
    Column({ space: AppSpacing.ITEM }) {
      PageHeader({ title: '收货地址', subtitle: '管理你的收货信息', actionLabel: '新增',
        onBack: this.onBack, onAction: () => this.openEditor() })
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
                  Text(address.receiverName).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
                  if (address.isDefault) { Text('默认').fontSize(10).fontColor(AppColors.BRAND).padding({ left: 7, right: 7, top: 3, bottom: 3 }).backgroundColor(AppColors.BRAND_SOFT).borderRadius(8) }
                }.width('100%').alignItems(VerticalAlign.Top)
                Text(address.receiverPhone).width('100%').fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
                Text(`${address.province}${address.city}${address.district}${address.detailAddress}`).width('100%').fontSize(13).lineHeight(20).fontColor(AppColors.TEXT_SECONDARY)
                Row({ space: 10 }) {
                  Blank()
                  Button('编辑', { type: ButtonType.Normal }).height(44).fontSize(13).backgroundColor(AppColors.BRAND_SOFT)
                    .fontColor(AppColors.BRAND).borderRadius(10).enabled(this.removingId === 0).onClick(() => this.openEditor(address))
                  Button(this.removingId === address.id ? '删除中…' : '删除', { type: ButtonType.Normal }).height(44).fontSize(13)
                    .backgroundColor(Color.Transparent).fontColor(AppColors.DANGER).enabled(this.removingId === 0).onClick(() => this.confirmRemove(address))
                }.width('100%')
              }.width('100%').padding(AppSpacing.CARD).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD).border({ width: 1, color: AppColors.DIVIDER })
            }, (address: Address) => address.id.toString())
          }.width('100%').padding({ top: 4, bottom: 22 })
        }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').constraintSize({ maxWidth: AppSpacing.CONTENT_MAX }).alignSelf(ItemAlign.Center)
      .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL, top: 12 }).backgroundColor(AppColors.BACKGROUND)
      .bindSheet($$this.editorVisible, this.editor(), { height: SheetSize.LARGE, showClose: false, backgroundColor: AppColors.SURFACE,
        shouldDismiss: (action: SheetDismiss) => { if (!this.saving) { action.dismiss() } } })
  }
}
