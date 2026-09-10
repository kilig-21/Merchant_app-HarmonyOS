@Component
export struct ProfileContent {
  @State notice: string = ''
  onNavigate: (index: number) => void = () => {}
  onOpenOrders: () => void = () => {}

  @Builder
  actionItem(icon: string, title: string, detail: string, message: string) {
    Row({ space: 13 }) {
      Text(icon).width(38).height(38).fontSize(18).textAlign(TextAlign.Center).padding({ top: 9 }).backgroundColor('#EDF2EC').borderRadius(13)
      Column({ space: 3 }) { Text(title).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#294238'); Text(detail).fontSize(11).fontColor('#839089') }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text('›').fontSize(23).fontColor('#A1ABA5')
    }.width('100%').padding({ top: 12, bottom: 12 }).onClick(() => this.notice = message)
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 20 }) {
          Text('我的').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#18352C').width('100%').margin({ top: 15 })
          Row({ space: 14 }) {
            Stack({ alignContent: Alignment.Center }) { Circle({ width: 62, height: 62 }).fill('#215C49'); Text('客').fontSize(23).fontWeight(FontWeight.Medium).fontColor('#FFFFFF') }
            Column({ space: 5 }) { Text('欢迎来到拾光集').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#263D34'); Text('登录后同步购物车与订单').fontSize(12).fontColor('#78857F') }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('去登录').fontSize(12).fontColor('#FFFFFF').padding({ left: 13, right: 13, top: 8, bottom: 8 }).backgroundColor('#215C49').borderRadius(15).onClick(() => this.notice = '登录页将在接入会话能力时开放')
          }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(24)

          Column({ space: 14 }) {
            Row() { Text('我的订单').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#263D34'); Blank(); Text('全部订单 →').fontSize(12).fontColor('#718078').onClick(this.onOpenOrders) }.width('100%')
            Row() {
              Column({ space: 7 }) { Text('◷').fontSize(22).fontColor('#C45F3B'); Text('待付款').fontSize(12).fontColor('#4B5D54') }.layoutWeight(1).onClick(() => this.notice = '暂无待付款订单')
              Column({ space: 7 }) { Text('□').fontSize(22).fontColor('#5D8171'); Text('已付款').fontSize(12).fontColor('#4B5D54') }.layoutWeight(1).onClick(() => this.notice = '已付款订单将在这里展示')
              Column({ space: 7 }) { Text('↶').fontSize(22).fontColor('#B0864A'); Text('退款/售后').fontSize(12).fontColor('#4B5D54') }.layoutWeight(1).onClick(() => this.notice = '售后记录将在这里展示')
              Column({ space: 7 }) { Text('…').fontSize(22).fontColor('#7A8A81'); Text('全部').fontSize(12).fontColor('#4B5D54') }.layoutWeight(1).onClick(() => this.notice = '订单中心将在这里展示')
            }.width('100%')
          }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(24)

          Column() {
            this.actionItem('⌂', '收货地址', '管理常用收货信息', '地址管理界面待接入')
            Divider().color('#EEF0EC').strokeWidth(1)
            this.actionItem('♧', '售后服务', '申请售后与查看进度', '售后服务界面待接入')
            Divider().color('#EEF0EC').strokeWidth(1)
            this.actionItem('⚙', '设置', '隐私、账号与帮助', '设置界面待接入')
          }.width('100%').padding({ left: 17, right: 17, top: 4, bottom: 4 }).backgroundColor('#FFFFFF').borderRadius(24)

          Column({ space: 6 }) { Text('拾光集 · 消费者商城').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#547064'); Text('让每一次选择，都更接近喜欢。').fontSize(11).fontColor('#94A099') }.width('100%').padding(18).backgroundColor('#E7EFE9').borderRadius(20)
          if (this.notice.length > 0) { Text(this.notice).width('100%').fontSize(12).fontColor('#704932').padding(13).backgroundColor('#FFF0DF').borderRadius(15) }
        }.width('100%').padding({ left: 2, right: 2, bottom: 28 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor('#F7F5EF')
  }
}
