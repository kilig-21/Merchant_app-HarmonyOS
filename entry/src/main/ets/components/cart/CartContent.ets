@Component
export struct CartContent {
  @State selectedFirst: boolean = true
  @State selectedSecond: boolean = true
  @State quantity: number = 1
  @State showNotice: boolean = false
  onNavigate: (index: number) => void = () => {}
  onCheckout: () => void = () => {}

  @Builder
  cartItem(tone: string, mark: string, title: string, spec: string, price: string, selected: boolean, onToggle: () => void) {
    Row({ space: 12 }) {
      Text(selected ? '✓' : '').width(21).height(21).fontSize(13).fontColor('#FFFFFF').textAlign(TextAlign.Center)
        .padding({ top: 2 }).backgroundColor(selected ? '#215C49' : '#FFFFFF').border({ width: 1, color: '#B8C2BC' }).borderRadius(11).onClick(onToggle)
      Stack({ alignContent: Alignment.Center }) {
        Column().width(76).height(76).backgroundColor(tone).borderRadius(16)
        Text(mark).fontSize(27).fontColor('#FFFFFF')
      }
      Column({ space: 5 }) {
        Text(title).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#263D34').maxLines(1)
        Text(spec).fontSize(11).fontColor('#849089')
        Row() {
          Text(price).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#C45F3B')
          Blank()
          Text('−').fontSize(17).fontColor('#668075').padding({ left: 6, right: 6 })
          Text(this.quantity.toString()).fontSize(13).fontColor('#334B41').padding({ left: 5, right: 5 })
          Text('＋').fontSize(17).fontColor('#215C49').padding({ left: 6, right: 1 }).onClick(() => this.quantity += 1)
        }.width('100%')
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }.width('100%').padding({ top: 12, bottom: 12 })
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 18 }) {
          Row() {
            Column({ space: 3 }) {
              Text('购物车').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#C45F3B')
              Text('慢慢挑，也别错过').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#18352C')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('管理').fontSize(13).fontColor('#537164').padding({ left: 13, right: 13, top: 8, bottom: 8 }).backgroundColor('#FFFFFF').borderRadius(16)
          }.width('100%')

          Column({ space: 0 }) {
            Row() { Text('浮光咖啡研究所').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#294338'); Blank(); Text('›').fontSize(20).fontColor('#91A098') }.width('100%')
            this.cartItem('#D7A98A', '咖', '云南小粒咖啡豆', '日晒 SOE · 200g', '¥ 58', this.selectedFirst, () => this.selectedFirst = !this.selectedFirst)
            Divider().color('#EEF0EC').strokeWidth(1)
            this.cartItem('#A7B8AA', '杯', '耐热玻璃分享壶', '简约透明 · 600ml', '¥ 76', this.selectedSecond, () => this.selectedSecond = !this.selectedSecond)
          }.width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(24)

          Column({ space: 12 }) {
            Row() { Text('购物车小提醒').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#2B453A'); Blank(); Text('2 件可结算').fontSize(12).fontColor('#75827B') }.width('100%')
            Text('下单前会再次确认库存和最终金额。展示价格仅用于界面预览。').fontSize(12).fontColor('#74817A').lineHeight(19)
          }.width('100%').padding(16).backgroundColor('#EDF2EC').borderRadius(20)

          if (this.showNotice) {
            Text('结算流程将使用后端的原子结算接口；当前是静态界面演示。').width('100%').fontSize(12).fontColor('#704932').padding(13).backgroundColor('#FFF0DF').borderRadius(15)
          }
        }.width('100%').padding({ left: 2, right: 2, top: 15, bottom: 22 })
      }.layoutWeight(1).scrollBar(BarState.Off)

      Row({ space: 12 }) {
        Column({ space: 2 }) {
          Text('合计').fontSize(12).fontColor('#77837D')
          Text('¥ 134').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#C45F3B')
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text('去结算  →').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#FFFFFF').padding({ left: 27, right: 27, top: 14, bottom: 14 }).backgroundColor('#215C49').borderRadius(22).onClick(this.onCheckout)
      }.width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(23)
    }.width('100%').height('100%').backgroundColor('#F7F5EF')
  }
}
