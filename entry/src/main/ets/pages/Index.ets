import { HomeContent } from '../components/home/HomeContent'

@Entry
@Component
struct Index {
  private pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      HomeContent()
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F5EF')
  }
}
