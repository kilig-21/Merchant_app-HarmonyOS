import { CartViewModel } from '../../viewmodel/CartViewModel'
import { CartGroup, CartItem } from '../../model/CartModels'
import { BrowseTheme } from '../../theme/BrowseTheme'
import { CartItemCard } from './CartItemCard'
import { Money } from '../../utils/Money'
import { PageStateType, PageStateView } from '../common/PageStateView'

@Component
export struct CartContent {
  @ObjectLink cart: CartViewModel
  onNavigate: (index: number) => void = () => {}
  onOpenProduct: (storeId: number, productId: number, skuId: number) => void = () => {}
  onOpenStore: (storeId: number) => void = () => {}
  @State showReview: boolean = false

  aboutToAppear(): void { this.cart.load() }

  private confirmRemove(ids: number[]): void {
    if (this.cart.busy || ids.length === 0) { return }
    this.getUIContext().showAlertDialog({
      title: '从购物车移除？', message: `将移除 ${ids.length} 款商品，以后还可以重新加入。`,
      primaryButton: { value: '保留', action: () => {} },
      secondaryButton: { value: '移除', fontColor: '#98482F', action: () => this.cart.remove(ids) }
    })
  }

  private groupSelection(group: CartGroup): string {
    const available = group.items.filter((item: CartItem) => this.cart.selectable(item))
    const selected = available.filter((item: CartItem) => this.cart.selectedIds.includes(item.id))
    return `已选 ${selected.length}/${available.length}`
  }

  @Builder
  reviewSheet() {
    Column({ space: 18 }) {
      Scroll() {
        Column({ space: 18 }) {
          ForEach(this.cart.groups(), (group: CartGroup) => {
            if (group.items.some((item: CartItem) => this.cart.selectedIds.includes(item.id) && this.cart.selectable(item))) {
              Column({ space: 14 }) {
                Text(group.storeName).fontSize(17).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK).width('100%')
                ForEach(group.items, (item: CartItem) => {
                  if (this.cart.selectedIds.includes(item.id) && this.cart.selectable(item)) {
                    Row({ space: 12 }) {
                      Column({ space: 5 }) {
                        Text(item.productName).fontSize(14).fontColor(BrowseTheme.INK)
                        Text(`${item.skuName} × ${item.quantity}`).fontSize(12).fontColor(BrowseTheme.MUTED)
                      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                      Text(`¥ ${Money.format(Money.cents(item.salePrice) * item.quantity)}`).fontSize(14).fontColor(BrowseTheme.INK)
                    }.width('100%')
                  }
                }, (item: CartItem) => item.id.toString())
                Divider().color(BrowseTheme.LINE)
              }.width('100%')
            }
          }, (group: CartGroup) => group.storeId.toString())
        }.width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      Row() {
        Text(`已选 ${this.cart.selectedCount()} 件`).fontSize(14).fontColor(BrowseTheme.MUTED)
        Blank()
        Text(`¥ ${this.cart.selectedSubtotal()}`).fontSize(25).fontColor(BrowseTheme.INK)
      }.width('100%')
      Text('以上为商品预估金额，未含运费。收货地址与下单暂未开放，本次不会创建订单。')
        .fontSize(12).lineHeight(20).fontColor(BrowseTheme.MUTED).width('100%')
      Button('返回购物车', { type: ButtonType.Normal }).width('100%').height(48)
        .fontColor(BrowseTheme.PAPER).backgroundColor(BrowseTheme.INK).borderRadius(8).onClick(() => this.showReview = false)
    }.width('100%').height('100%').padding({ left: 22, right: 22, bottom: 24 })
  }

  build() {
    Column({ space: 0 }) {
      Scroll() {
        Column({ space: 20 }) {
          Row() {
            Column({ space: 6 }) {
              Text('购物车').fontSize(28).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
              Text(`${this.cart.count()} 件商品 · 慢慢选，认真买`).fontSize(12).fontColor(BrowseTheme.MUTED)
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Button('移除已选', { type: ButtonType.Normal }).fontSize(12).height(44).padding({ left: 12, right: 0 })
              .fontColor(BrowseTheme.MUTED).backgroundColor(Color.Transparent)
              .enabled(!this.cart.busy && this.cart.selectedItems().length > 0)
              .onClick(() => this.confirmRemove(this.cart.selectedIds.slice()))
          }.width('100%')
          Divider().color(BrowseTheme.INK)
          if (this.cart.loading && this.cart.items.length === 0) {
            PageStateView({ type: PageStateType.Loading, title: '正在整理购物车', description: '稍等片刻。' })
          } else if (this.cart.error.length > 0 && !this.cart.initialized) {
            PageStateView({ type: PageStateType.Error, title: '购物车暂时无法加载', description: this.cart.error, onAction: () => this.cart.load() })
          } else {
            if (this.cart.error.length > 0) {
              Column({ space: 8 }) {
                Text(this.cart.error).fontSize(12).lineHeight(20).fontColor('#98482F').width('100%')
                Button('重新加载', { type: ButtonType.Normal }).fontSize(12).height(40).backgroundColor(BrowseTheme.WASH)
                  .fontColor(BrowseTheme.INK).enabled(!this.cart.busy).onClick(() => this.cart.load())
              }.width('100%').alignItems(HorizontalAlign.Start)
            }
            if (this.cart.items.length === 0) {
              Column({ space: 18 }) {
                Text('把喜欢的，\n留在这里。').fontSize(30).lineHeight(43).fontColor(BrowseTheme.INK)
                Text('购物车还是空的。\n去选一件喜欢的商品吧。').fontSize(14).lineHeight(24).fontColor(BrowseTheme.MUTED)
                Button('去逛逛 →', { type: ButtonType.Normal }).height(46).fontColor(BrowseTheme.PAPER)
                  .backgroundColor(BrowseTheme.INK).borderRadius(8).onClick(() => this.onNavigate(1))
              }.width('100%').alignItems(HorizontalAlign.Start).padding({ top: 36, bottom: 36 })
            } else {
              ForEach(this.cart.groups(), (group: CartGroup) => {
                Column() {
                  Row({ space: 8 }) {
                    Checkbox({ name: `store-${group.storeId}` }).select(this.cart.allSelected(group.storeId))
                      .shape(CheckBoxShape.CIRCLE).width(22).height(22).margin({ left: 0, right: 4 })
                      .selectedColor(BrowseTheme.INK).unselectedColor('#899080')
                      .enabled(!this.cart.busy && group.items.some((item: CartItem) => this.cart.selectable(item)))
                      .onChange((selected: boolean) => this.cart.selectStore(group.storeId, selected))
                      .accessibilityText(`选择${group.storeName}全部可购商品`)
                    Text(group.storeName).fontSize(16).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
                      .layoutWeight(1).onClick(() => this.onOpenStore(group.storeId))
                    Text(this.groupSelection(group)).fontSize(10).fontColor(BrowseTheme.MUTED)
                  }.width('100%').padding({ top: 8, bottom: 12 })
                  Divider().color(BrowseTheme.LINE)
                  ForEach(group.items, (item: CartItem) => {
                    CartItemCard({ item: item, selected: this.cart.selectedIds.includes(item.id), busy: this.cart.busy,
                      onSelect: (selected: boolean) => this.cart.selectItem(item.id, selected),
                      onQuantityChange: (quantity: number) => this.cart.update(item.id, quantity),
                      onRemove: () => this.confirmRemove([item.id]),
                      onOpen: () => this.onOpenProduct(item.storeId, item.productId, item.skuId) })
                  }, (item: CartItem) => item.id.toString())
                }.width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(8)
              }, (group: CartGroup) => group.storeId.toString())
            }
          }
          if (this.cart.busy && !this.cart.loading) {
            Text('正在更新购物车…').fontSize(12).fontColor(BrowseTheme.OLIVE).width('100%')
          } else if (this.cart.message.length > 0) {
            Text(this.cart.message).fontSize(12).fontColor(BrowseTheme.OLIVE).width('100%')
          }
          Text('本地演示 · 本次打开 App 期间保留').fontSize(11).fontColor(BrowseTheme.MUTED).width('100%')
        }.width('100%').constraintSize({ maxWidth: 640 }).padding({ top: 20, bottom: 20, left: 4, right: 4 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      if (this.cart.items.length > 0) {
        Column({ space: 8 }) {
          Row() {
            Checkbox({ name: 'cart-all' }).select(this.cart.allSelected()).shape(CheckBoxShape.CIRCLE)
              .width(22).height(22).selectedColor(BrowseTheme.INK).unselectedColor('#899080')
              .margin({ left: 0, right: 8 }).enabled(!this.cart.busy)
              .onChange((selected: boolean) => this.cart.selectAll(selected)).accessibilityText('全选可购商品')
            Text('全选').fontSize(13).fontColor(BrowseTheme.INK)
            Blank()
            Text('合计（预估）').fontSize(12).fontColor(BrowseTheme.MUTED).margin({ right: 6 })
            Text(`¥ ${this.cart.selectedSubtotal()}`).fontSize(23).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
          }.width('100%')
          Button(`核对商品（${this.cart.selectedCount()} 件）`, { type: ButtonType.Normal }).width('100%').height(46)
            .backgroundColor(BrowseTheme.INK).fontColor(BrowseTheme.PAPER).fontSize(15).borderRadius(8)
            .enabled(!this.cart.busy && this.cart.error.length === 0 && this.cart.selectedCount() > 0)
            .onClick(() => this.showReview = true)
        }.width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 }).backgroundColor('#FFFFFF').borderRadius(8)
      }
      Blank().height(82)
    }.width('100%').height('100%').backgroundColor(BrowseTheme.PAPER)
      .bindSheet($$this.showReview, this.reviewSheet(), {
        height: SheetSize.LARGE, showClose: true, title: { title: '核对已选商品' }, backgroundColor: BrowseTheme.PAPER
      })
  }
}
