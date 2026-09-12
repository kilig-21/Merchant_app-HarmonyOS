import { CartViewModel } from '../../viewmodel/CartViewModel'
import { CartGroup, CartItem } from '../../model/CartModels'
import { BrowseTheme } from '../../theme/BrowseTheme'
import { ProductArtwork } from '../../theme/ProductArtwork'
import { PageStateType, PageStateView } from '../common/PageStateView'

@Component
export struct CartContent {
  @ObjectLink cart: CartViewModel
  onNavigate: (index: number) => void = () => {}
  onOpenProduct: (storeId: number, productId: number) => void = () => {}

  aboutToAppear(): void { if (!this.cart.initialized) { this.cart.load() } }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Row() {
          Text('购物车').fontSize(28).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
          Blank()
          Text(`${this.cart.count()} 件商品`).fontSize(12).fontColor(BrowseTheme.MUTED)
        }.width('100%')
        Text('本地演示 · 本次打开 App 期间保留').fontSize(11).fontColor(BrowseTheme.MUTED).width('100%')
        if (this.cart.loading) {
          PageStateView({ type: PageStateType.Loading, title: '正在整理购物车', description: '' })
        } else if (this.cart.error.length > 0) {
          PageStateView({ type: PageStateType.Error, title: '购物车暂时无法加载', description: this.cart.error, onAction: () => this.cart.load() })
        } else if (this.cart.items.length === 0) {
          PageStateView({ type: PageStateType.Empty, title: '把喜欢的，放进购物车', description: '先去逛逛，选择商品规格后即可加入。' })
          Button('去逛店').backgroundColor(BrowseTheme.INK).fontColor(BrowseTheme.PAPER).onClick(() => this.onNavigate(1))
        } else {
          ForEach(this.cart.groups(), (group: CartGroup) => {
            Column({ space: 16 }) {
              Text(group.storeName).fontSize(17).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK).width('100%')
              ForEach(group.items, (item: CartItem) => {
                Row({ space: 14 }) {
                  Image(ProductArtwork.resolve(item.productId)).width(80).height(96).objectFit(ImageFit.Cover).borderRadius(6)
                  Column({ space: 8 }) {
                    Text(item.productName).fontSize(16).fontColor(BrowseTheme.INK)
                    Text(item.skuName).fontSize(12).fontColor(BrowseTheme.MUTED)
                    Text(`¥ ${item.salePrice.toFixed(2)} × ${item.quantity}`).fontSize(16).fontColor(BrowseTheme.INK)
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                }.width('100%').onClick(() => this.onOpenProduct(item.storeId, item.productId))
              }, (item: CartItem) => item.id.toString())
            }.width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(8)
          }, (group: CartGroup) => group.storeId.toString())
          Text(`商品预估合计 ¥ ${this.cart.subtotal()}`).fontSize(20).fontColor(BrowseTheme.INK).width('100%')
        }
      }.width('100%').padding({ top: 20, bottom: 108, left: 4, right: 4 })
    }.width('100%').height('100%').scrollBar(BarState.Off).backgroundColor(BrowseTheme.PAPER)
  }
}
