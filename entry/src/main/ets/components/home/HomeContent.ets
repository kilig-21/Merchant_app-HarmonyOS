import { FloatingTabBar } from '../navigation/FloatingTabBar'

@Component
export struct HomeContent {
  @State keyword: string = ''
  @State notice: string = ''
  @State selectedTabIndex: number = 0

  @Builder
  serviceLink(icon: string, title: string, color: string, message: string) {
    Column({ space: 6 }) {
      Text(icon)
        .width(38)
        .height(38)
        .fontSize(19)
        .textAlign(TextAlign.Center)
        .padding({ top: 8 })
        .backgroundColor(color)
        .borderRadius(14)
      Text(title)
        .fontSize(11)
        .fontColor('#35423C')
    }
    .layoutWeight(1)
    .onClick(() => {
      this.notice = message
    })
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 22 }) {
          Row() {
            Column({ space: 3 }) {
              Text('拾光集')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#C45F3B')
              Text('让日常，多一点好物')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#18352C')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('☀')
              .width(44)
              .height(44)
              .fontSize(22)
              .textAlign(TextAlign.Center)
              .padding({ top: 9 })
              .backgroundColor('#FFF9EE')
              .borderRadius(22)
          }
          .width('100%')

          Search({ value: this.keyword, placeholder: '搜索商品、店铺' })
            .height(50)
            .textFont({ size: 15 })
            .placeholderFont({ size: 15 })
            .placeholderColor('#909894')
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .onChange((value: string) => {
              this.keyword = value
            })
            .onSubmit((value: string) => {
              this.notice = value.length > 0 ? `“${value}”将在搜索接口接入后查询` : '请输入要搜索的内容'
            })

          Stack({ alignContent: Alignment.TopEnd }) {
            Circle({ width: 148, height: 148 })
              .fill('#F2C66D')
              .opacity(0.16)
              .translate({ x: 42, y: -32 })

            Column() {
              Row() {
                Text('本周新发现')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1C4A3B')
                  .padding({ left: 11, right: 11, top: 6, bottom: 6 })
                  .backgroundColor('#F4D88D')
                  .borderRadius(14)
                Blank()
              }

              Blank()

              Text('好生活，不必千篇一律')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('从精选店铺里，遇见值得留下的日常。')
                .fontSize(13)
                .fontColor('#D9EBE4')
                .margin({ top: 7 })

              Row() {
                Text('去逛一逛  →')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1D5141')
                  .padding({ left: 14, right: 14, top: 9, bottom: 9 })
                  .backgroundColor('#FFFFFF')
                  .borderRadius(17)
                Blank()
                Text('✦')
                  .fontSize(32)
                  .fontColor('#F2C66D')
              }
              .width('100%')
              .margin({ top: 15 })
            }
            .width('100%')
            .height(206)
            .padding(20)
          }
          .width('100%')
          .height(206)
          .backgroundColor('#215C49')
          .borderRadius(28)
          .clip(true)
          .onClick(() => {
            this.notice = '精选店铺将在店铺列表接入后开放'
          })

          Column({ space: 17 }) {
            Row() {
              Text('为你服务')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F342D')
              Blank()
              Text('买东西需要的，都放在手边')
                .fontSize(12)
                .fontColor('#8A938E')
                .maxLines(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Row({ space: 10 }) {
              Column() {
                Row() {
                  Text('🛒').fontSize(22)
                  Blank()
                  Text('→').fontSize(16).fontColor('#477161')
                }
                .width('100%')
                Text('购物车')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#244538')
                  .margin({ top: 10 })
                Text('继续挑选与结算')
                  .fontSize(11)
                  .fontColor('#668075')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .height(112)
              .padding(15)
              .backgroundColor('#E5F0EA')
              .borderRadius(20)
              .onClick(() => {
                this.notice = '购物车将在登录与购物车功能完成后开放'
              })

              Column() {
                Row() {
                  Text('📦').fontSize(22)
                  Blank()
                  Text('→').fontSize(16).fontColor('#8A6E35')
                }
                .width('100%')
                Text('我的订单')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#574727')
                  .margin({ top: 10 })
                Text('查看订单状态')
                  .fontSize(11)
                  .fontColor('#89764E')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .height(112)
              .padding(15)
              .backgroundColor('#F6ECD2')
              .borderRadius(20)
              .onClick(() => {
                this.notice = '我的订单将在订单功能完成后开放'
              })
            }
            .width('100%')

            Row() {
              this.serviceLink('🛍', '热门商品', '#FFF0E9', '热门商品将在搜索接口接入后开放')
              this.serviceLink('📍', '收货地址', '#FCE8E4', '收货地址将在地址管理完成后开放')
              this.serviceLink('♻', '售后服务', '#E7F1F3', '售后服务将在订单功能完成后开放')
              this.serviceLink('⋯', '全部服务', '#EEECE7', '更多服务正在规划中')
            }
            .width('100%')
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFF')
          .borderRadius(24)

          Column({ space: 13 }) {
            Row() {
              Column({ space: 3 }) {
                Text('正在发生')
                  .fontSize(12)
                  .fontColor('#C45F3B')
                Text('今天，逛点不一样的')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1F342D')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('全部  →')
                .fontSize(12)
                .fontColor('#6E7B75')
            }
            .width('100%')

            Row({ space: 10 }) {
              Column() {
                Text('限时抢购')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('好价准时见')
                  .fontSize(12)
                  .fontColor('#FFE6DC')
                  .margin({ top: 5 })
                Blank()
                Text('即将开放')
                  .fontSize(11)
                  .fontColor('#A84728')
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor('#FFFFFF')
                  .borderRadius(13)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(3)
              .height(150)
              .padding(17)
              .backgroundColor('#ED6A43')
              .borderRadius(24)
              .onClick(() => {
                this.notice = '限时抢购将在促销接口接入后开放'
              })

              Column({ space: 10 }) {
                Column({ space: 4 }) {
                  Text('精选店铺').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#284238')
                  Text('发现小店').fontSize(11).fontColor('#7A827D')
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center)
                .layoutWeight(1)
                .width('100%')
                .padding({ left: 13 })
                .backgroundColor('#E4EFE8')
                .borderRadius(18)

                Column({ space: 4 }) {
                  Text('新品上架').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#51462E')
                  Text('等待接入').fontSize(11).fontColor('#8B8068')
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center)
                .layoutWeight(1)
                .width('100%')
                .padding({ left: 13 })
                .backgroundColor('#F3E8CA')
                .borderRadius(18)
              }
              .layoutWeight(2)
              .height(150)
            }
            .width('100%')
          }
          .width('100%')

          Column({ space: 8 }) {
            Text('真实商品正在路上')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#284238')
            Text('接入店铺和商品搜索接口后，这里将展示真实商品，不使用虚构图片。')
              .fontSize(12)
              .fontColor('#78827D')
              .lineHeight(19)
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#EDF2EC')
          .borderRadius(20)

          if (this.notice.length > 0) {
            Text(this.notice)
              .width('100%')
              .fontSize(12)
              .fontColor('#704932')
              .padding(13)
              .backgroundColor('#FFF0DF')
              .borderRadius(15)
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 20, bottom: 28 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Column() {
        FloatingTabBar({
          selectedIndex: this.selectedTabIndex,
          onSelect: (index: number) => {
            this.selectedTabIndex = index
            const titles: string[] = ['首页', '逛店', '购物车', '我的']
            this.notice = index === 0 ? '' : `${titles[index]}页面将在主框架步骤接入`
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 14 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F5EF')
  }
}
