import { common } from '@kit.AbilityKit'
import { SessionViewModel } from '../viewmodel/SessionViewModel'
import { AppColors, AppRadius } from '../theme/AppTheme'

@Component
export struct AuthPage {
  @ObjectLink session: SessionViewModel
  onBack: () => void = () => {}
  onSuccess: () => void = () => {}
  @State account: string = ''
  @State password: string = ''
  @State register: boolean = false

  aboutToAppear(): void { this.session.error = '' }
  aboutToDisappear(): void { this.password = '' }
  private async submit(): Promise<void> {
    if (await this.session.signIn(this.getUIContext().getHostContext() as common.UIAbilityContext,
      this.account, this.password, this.register)) {
      this.password = ''
      this.onSuccess()
    }
  }

  build() {
    Column() {
      Row() {
        Button('‹', { type: ButtonType.Normal }).width(44).height(44).fontSize(30)
          .backgroundColor(Color.Transparent).fontColor(AppColors.BRAND).enabled(!this.session.busy)
          .onClick(this.onBack).accessibilityText('返回')
        Text('拾光集').fontSize(16).fontColor(AppColors.BRAND)
      }.width('100%')
      Scroll() {
        Column({ space: 20 }) {
          Text(this.register ? '从一次喜欢，\n开启新的日常。' : '欢迎回来，\n继续你的好物清单。')
            .fontSize(29).lineHeight(42).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
          Text('登录后可同步购物车、收货地址和订单。').fontSize(13).lineHeight(22).fontColor(AppColors.TEXT_SECONDARY)
          Column({ space: 8 }) {
            Text('账号').fontSize(13).fontColor(AppColors.BRAND)
            TextInput({ text: this.account, placeholder: '输入账号，3～64 个字符' }).height(50).maxLength(64)
              .backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CONTROL).enabled(!this.session.busy)
              .onChange((value: string) => { this.account = value; this.session.error = '' })
          }.width('100%').alignItems(HorizontalAlign.Start)
          Column({ space: 8 }) {
            Text('密码').fontSize(13).fontColor(AppColors.BRAND)
            TextInput({ text: this.password, placeholder: '输入密码，6～32 个字符' }).type(InputType.Password)
              .height(50).maxLength(32).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CONTROL)
              .enabled(!this.session.busy).onChange((value: string) => { this.password = value; this.session.error = '' })
          }.width('100%').alignItems(HorizontalAlign.Start)
          if (this.session.error.length > 0) {
            Text(this.session.error).fontSize(13).lineHeight(22).fontColor(AppColors.DANGER)
          }
          Button(this.session.busy ? '正在提交…' : this.register ? '注册并登录' : '登录并继续')
            .width('100%').height(50).backgroundColor(AppColors.BRAND).borderRadius(AppRadius.CONTROL)
            .enabled(!this.session.busy).onClick(() => this.submit())
          Button(this.register ? '已有账号，去登录' : '没有账号，创建一个', { type: ButtonType.Normal })
            .width('100%').height(44).fontColor(AppColors.BRAND).backgroundColor(Color.Transparent)
            .enabled(!this.session.busy).onClick(() => { this.register = !this.register; this.session.error = '' })
        }.width('100%').constraintSize({ maxWidth: 520 }).alignItems(HorizontalAlign.Start)
          .padding({ left: 24, right: 24, top: 36, bottom: 32 })
      }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }
}
