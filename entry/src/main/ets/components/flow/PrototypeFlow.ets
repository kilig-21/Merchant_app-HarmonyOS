import { PROTOTYPE_CART_TOTAL, PROTOTYPE_PRODUCT_NAME, PROTOTYPE_PRODUCT_PRICE } from '../../mock/MallPrototypeData'

@Component
export struct PrototypeFlow {
  @Prop page: string = 'product'
  onBack: () => void = () => {}
  onNavigate: (page: string) => void = () => {}

  @Builder
  topBar(title: string, subtitle: string) {
    Row({ space: 12 }) {
      Text('‹').fontSize(32).fontColor('#25473B').width(36).height(40).textAlign(TextAlign.Center).onClick(this.onBack)
      Column({ space: 2 }) { Text(title).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1E382E'); Text(subtitle).fontSize(11).fontColor('#829088') }.alignItems(HorizontalAlign.Start)
      Blank()
    }.width('100%').margin({ bottom: 19 })
  }

  @Builder
  productPage() {
    Column({ space: 18 }) {
      this.topBar('商品详情', '原型预览 · 商品数据为 Mock')
      Stack({ alignContent: Alignment.Center }) {
        Column().width('100%').height(280).backgroundColor('#D8A78B').borderRadius(30)
        Text('咖').fontSize(76).fontColor('#FFFFFF').opacity(0.9)
        Text('浮光咖啡研究所').fontSize(12).fontColor('#FFFFFF').margin({ top: 112 })
      }.width('100%')
      Column({ space: 9 }) {
        Text(PROTOTYPE_PRODUCT_NAME).fontSize(23).fontWeight(FontWeight.Bold).fontColor('#1E382E')
        Text('山野果香与巧克力余韵，适合慢慢冲一杯。').fontSize(13).fontColor('#738078').lineHeight(21)
        Text(PROTOTYPE_PRODUCT_PRICE).fontSize(27).fontWeight(FontWeight.Bold).fontColor('#C45F3B').margin({ top: 4 })
      }.width('100%').alignItems(HorizontalAlign.Start)
      Column({ space: 10 }) {
        Row() { Text('选择规格').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#2E473C'); Blank(); Text('库存以服务端为准').fontSize(11).fontColor('#87938C') }.width('100%')
        Row({ space: 9 }) { Text('日晒 SOE · 200g').fontSize(13).fontColor('#FFFFFF').padding({ left: 15, right: 15, top: 10, bottom: 10 }).backgroundColor('#215C49').borderRadius(16); Text('水洗拼配 · 200g').fontSize(13).fontColor('#607269').padding({ left: 15, right: 15, top: 10, bottom: 10 }).backgroundColor('#EDF1ED').borderRadius(16) }.width('100%')
      }.width('100%').padding(17).backgroundColor('#FFFFFF').borderRadius(22)
      Blank().layoutWeight(1)
      Row({ space: 11 }) { Text('加入购物车').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#215C49').padding({ left: 22, right: 22, top: 14, bottom: 14 }).backgroundColor('#E3EFE8').borderRadius(22).onClick(() => this.onNavigate('cart')); Text('去购物车 →').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#FFFFFF').padding({ left: 23, right: 23, top: 14, bottom: 14 }).backgroundColor('#215C49').borderRadius(22).onClick(() => this.onNavigate('cart')) }.width('100%').justifyContent(FlexAlign.End)
    }
  }

  @Builder
  checkoutPage() {
    Column({ space: 17 }) {
      this.topBar('确认订单', '原型预览 · 不提交订单')
      Column({ space: 7 }) { Text('收货地址').fontSize(12).fontColor('#C45F3B'); Text('林小满  138 0000 0000').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#294238'); Text('广东省 深圳市 南山区 生活路 18 号').fontSize(12).fontColor('#748078') }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(22)
      Column({ space: 12 }) { Text('浮光咖啡研究所').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#2E473C'); Row({ space: 12 }) { Text('咖').width(64).height(64).fontSize(24).textAlign(TextAlign.Center).padding({ top: 17 }).backgroundColor('#D8A78B').fontColor('#FFFFFF').borderRadius(15); Column({ space: 5 }) { Text(PROTOTYPE_PRODUCT_NAME).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#2D453A'); Text('日晒 SOE · 200g × 1').fontSize(12).fontColor('#819088'); Text(PROTOTYPE_PRODUCT_PRICE).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#C45F3B') }.alignItems(HorizontalAlign.Start) }.width('100%') }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(22)
      Column({ space: 11 }) { Row() { Text('商品金额').fontSize(13).fontColor('#728078'); Blank(); Text(PROTOTYPE_CART_TOTAL).fontSize(14).fontColor('#31483E') }.width('100%'); Row() { Text('实际支付金额').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#31483E'); Blank(); Text(PROTOTYPE_CART_TOTAL).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#C45F3B') }.width('100%') }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(22)
      Blank().layoutWeight(1)
      Text('确认下单（原型演示）').width('100%').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#FFFFFF').textAlign(TextAlign.Center).padding({ top: 15, bottom: 15 }).backgroundColor('#215C49').borderRadius(23).onClick(() => this.onNavigate('result'))
    }
  }

  @Builder
  resultPage() {
    Column({ space: 17 }) {
      this.topBar('订单结果', '原型预览')
      Column({ space: 11 }) { Text('✓').fontSize(36).fontColor('#FFFFFF').width(66).height(66).textAlign(TextAlign.Center).padding({ top: 12 }).backgroundColor('#215C49').borderRadius(33); Text('订单已提交').fontSize(23).fontWeight(FontWeight.Bold).fontColor('#1E382E'); Text('等待支付 · 这里不会展示模拟支付。').fontSize(13).fontColor('#77857D') }.width('100%').alignItems(HorizontalAlign.Center).padding({ top: 38, bottom: 34 }).backgroundColor('#E5F0EA').borderRadius(28)
      Column({ space: 12 }) { Row() { Text('订单编号').fontSize(13).fontColor('#7C8982'); Blank(); Text('MOCK-20260910-001').fontSize(13).fontColor('#2E473C') }.width('100%'); Row() { Text('订单金额').fontSize(13).fontColor('#7C8982'); Blank(); Text(PROTOTYPE_CART_TOTAL).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#C45F3B') }.width('100%') }.width('100%').padding(19).backgroundColor('#FFFFFF').borderRadius(22)
      Text('查看我的订单').width('100%').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#FFFFFF').textAlign(TextAlign.Center).padding({ top: 15, bottom: 15 }).backgroundColor('#215C49').borderRadius(23).onClick(() => this.onNavigate('orders'))
      Text('继续逛逛').width('100%').fontSize(15).fontColor('#315B4C').textAlign(TextAlign.Center).padding({ top: 13, bottom: 13 }).backgroundColor('#FFFFFF').borderRadius(22).onClick(this.onBack)
    }
  }

  @Builder
  orderPage() {
    Column({ space: 17 }) {
      this.topBar('我的订单', '原型预览 · 订单数据为 Mock')
      Row({ space: 8 }) { Text('全部').fontSize(13).fontColor('#FFFFFF').padding({ left: 15, right: 15, top: 8, bottom: 8 }).backgroundColor('#215C49').borderRadius(15); Text('待付款').fontSize(13).fontColor('#697A72').padding({ left: 15, right: 15, top: 8, bottom: 8 }).backgroundColor('#FFFFFF').borderRadius(15); Text('已完成').fontSize(13).fontColor('#697A72').padding({ left: 15, right: 15, top: 8, bottom: 8 }).backgroundColor('#FFFFFF').borderRadius(15) }.width('100%')
      Column({ space: 12 }) { Row() { Text('浮光咖啡研究所').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#2C453A'); Blank(); Text('待付款').fontSize(13).fontColor('#C45F3B') }.width('100%'); Row({ space: 12 }) { Text('咖').width(66).height(66).fontSize(25).fontColor('#FFFFFF').textAlign(TextAlign.Center).padding({ top: 17 }).backgroundColor('#D8A78B').borderRadius(15); Column({ space: 6 }) { Text(PROTOTYPE_PRODUCT_NAME).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#2C453A'); Text('日晒 SOE · 200g × 1').fontSize(12).fontColor('#849089'); Text('合计 ' + PROTOTYPE_CART_TOTAL).fontSize(14).fontColor('#C45F3B') }.alignItems(HorizontalAlign.Start) }.width('100%'); Row() { Blank(); Text('取消订单').fontSize(13).fontColor('#60736A').padding({ left: 14, right: 14, top: 8, bottom: 8 }).border({ width: 1, color: '#D8DED9' }).borderRadius(15); Text('查看详情').fontSize(13).fontColor('#FFFFFF').margin({ left: 9 }).padding({ left: 14, right: 14, top: 8, bottom: 8 }).backgroundColor('#215C49').borderRadius(15) }.width('100%') }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(22)
    }
  }

  build() {
    Column() {
      if (this.page === 'product') { this.productPage() } else if (this.page === 'checkout') { this.checkoutPage() } else if (this.page === 'result') { this.resultPage() } else { this.orderPage() }
    }.width('100%').height('100%').padding({ left: 18, right: 18, top: 22, bottom: 18 }).backgroundColor('#F7F5EF')
  }
}
