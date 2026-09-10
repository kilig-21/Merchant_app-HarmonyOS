import { PROTOTYPE_STORES, PrototypeStore } from '../../mock/MallPrototypeData'

@Component
export struct StoreContent {
  @State keyword: string = ''
  @State selectedStore: number = 0
  @State message: string = ''
  onNavigate: (index: number) => void = () => {}
  onOpenProduct: () => void = () => {}

  @Builder
  productCard(tone: string, mark: string, name: string, price: string, note: string) {
    Column({ space: 9 }) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height(126)
          .backgroundColor(tone)
          .borderRadius(18)
        Text(mark)
          .fontSize(42)
          .fontColor('#FFFFFF')
          .opacity(0.9)
      }
      .width('100%')
      Text(name).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#263B33').maxLines(1)
      Text(note).fontSize(11).fontColor('#89918C').maxLines(1)
      Row() {
        Text(price).fontSize(17).fontWeight(FontWeight.Bold).fontColor('#C45F3B')
        Blank()
        Text('＋').fontSize(18).fontColor('#215C49')
      }.width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .onClick(this.onOpenProduct)
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 20 }) {
          Row() {
            Column({ space: 3 }) {
              Text('逛店').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#C45F3B')
              Text('发现有温度的小店').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#18352C')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('⌕').fontSize(25).fontColor('#315B4C').width(44).height(44).textAlign(TextAlign.Center)
              .padding({ top: 7 }).backgroundColor('#FFFFFF').borderRadius(22)
          }.width('100%')

          Search({ value: this.keyword, placeholder: '搜商品，也可以搜店铺' })
            .height(48).backgroundColor('#FFFFFF').borderRadius(18).placeholderColor('#939B96')
            .onChange((value: string) => this.keyword = value)
            .onSubmit((value: string) => this.message = value.length > 0 ? `正在为你寻找「${value}」` : '输入关键词后即可搜索')

          Column({ space: 13 }) {
            Row() {
              Text('精选店铺').fontSize(19).fontWeight(FontWeight.Bold).fontColor('#203A31')
              Blank()
              Text('共 24 家').fontSize(12).fontColor('#829089')
            }.width('100%')
            ForEach(PROTOTYPE_STORES, (store: PrototypeStore, index: number) => {
              Row({ space: 13 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle({ width: 52, height: 52 }).fill(store.tone)
                  Text(store.mark).fontSize(23).fontColor('#FFFFFF')
                }
                Column({ space: 5 }) {
                  Text(store.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#263D34')
                  Text(store.tag).fontSize(12).fontColor('#7D8983')
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Text(this.selectedStore === index ? '已选择' : '去逛 →').fontSize(12)
                  .fontColor(this.selectedStore === index ? '#FFFFFF' : '#315B4C')
                  .padding({ left: 11, right: 11, top: 7, bottom: 7 })
                  .backgroundColor(this.selectedStore === index ? '#215C49' : '#E5F0EA').borderRadius(14)
              }.width('100%').padding(13).backgroundColor('#FFFFFF').borderRadius(20)
                .onClick(() => this.selectedStore = index)
            }, (store: PrototypeStore) => store.name)
          }

          Column({ space: 13 }) {
            Row() {
              Column({ space: 3 }) {
                Text('本店上新').fontSize(12).fontColor('#C45F3B')
                Text(PROTOTYPE_STORES[this.selectedStore].name).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#203A31')
              }.alignItems(HorizontalAlign.Start)
              Blank()
              Text('查看全部').fontSize(12).fontColor('#687A72')
            }.width('100%')
            Row({ space: 12 }) {
              this.productCard('#A7BAA7', '茶', '云雾白茶礼盒', '¥ 128', '清甜回甘 · 100g')
              this.productCard('#D8A78B', '杯', '手作玻璃杯', '¥ 69', '透亮日常 · 360ml')
            }.width('100%')
            Row({ space: 12 }) {
              this.productCard('#8DA8A1', '香', '雨后木质香氛', '¥ 89', '安静木调 · 100ml')
              this.productCard('#C9B58E', '布', '亚麻桌布', '¥ 98', '自然肌理 · 140cm')
            }.width('100%')
          }
          if (this.message.length > 0) {
            Text(this.message).width('100%').fontSize(12).fontColor('#704932').padding(13).backgroundColor('#FFF0DF').borderRadius(15)
          }
        }.width('100%').padding({ left: 2, right: 2, top: 15, bottom: 28 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor('#F7F5EF')
  }
}
