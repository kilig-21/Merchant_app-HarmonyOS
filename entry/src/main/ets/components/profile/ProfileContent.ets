import { AppCard } from '../common/AppCard'
import { AppColors } from '../../theme/AppTheme'
import { common } from '@kit.AbilityKit'
import { AuthApi } from '../../api/AuthApi'
import { AuthSession } from '../../model/AuthModels'
import { HttpClient } from '../../network/HttpClient'
import { SessionRepository } from '../../repository/SessionRepository'

@Component
export struct ProfileContent {
  @State notice: string = ''
  @State username: string = ''
  @State authPanelVisible: boolean = false
  @State registerMode: boolean = false
  @State accountInput: string = ''
  @State passwordInput: string = ''
  @State authSubmitting: boolean = false
  @State authMessage: string = ''
  onNavigate: (index: number) => void = () => {}
  onOpenOrders: () => void = () => {}

  aboutToAppear(): void {
    this.restoreSession()
  }

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext
  }

  private async restoreSession(): Promise<void> {
    try {
      const session = await SessionRepository.load(this.getAbilityContext())
      if (session === null) {
        return
      }
      HttpClient.setAccessToken(session.accessToken)
      const user = await AuthApi.getCurrentUser()
      this.username = user.username
      await SessionRepository.save(this.getAbilityContext(), new AuthSession(session.accessToken, user))
    } catch (_) {
      await this.signOut(false)
    }
  }

  private async signOut(showMessage: boolean): Promise<void> {
    HttpClient.clearAccessToken()
    this.username = ''
    this.authPanelVisible = false
    try {
      await SessionRepository.clear(this.getAbilityContext())
    } catch (_) {
      // 本地存储清理失败时，内存 Token 仍已清空，不能继续作为已登录状态使用。
    }
    if (showMessage) {
      this.notice = '已退出当前账号'
    }
  }

  private async submitAuth(): Promise<void> {
    const username = this.accountInput.trim()
    const password = this.passwordInput
    if (username.length < 3 || username.length > 64) {
      this.authMessage = '账号长度应为 3～64 个字符'
      return
    }
    if (password.length < 6 || password.length > 32) {
      this.authMessage = '密码长度应为 6～32 个字符'
      return
    }

    this.authSubmitting = true
    this.authMessage = ''
    try {
      if (this.registerMode) {
        await AuthApi.register(username, password)
      }
      const result = await AuthApi.login(username, password)
      if (result.user.userType !== 'CONSUMER') {
        HttpClient.clearAccessToken()
        this.authMessage = '该账号不是消费者账号，不能登录商城'
        return
      }
      HttpClient.setAccessToken(result.accessToken)
      const session: AuthSession = new AuthSession(result.accessToken, result.user)
      await SessionRepository.save(this.getAbilityContext(), session)
      this.username = result.user.username
      this.passwordInput = ''
      this.authPanelVisible = false
      this.notice = `欢迎回来，${result.user.username}`
    } catch (error) {
      this.authMessage = error instanceof Error ? error.message : '登录失败，请稍后重试'
    } finally {
      this.authSubmitting = false
    }
  }

  @Builder
  authPanel() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.registerMode ? '创建消费者账号' : '登录拾光集')
            .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#263D34')
          Text(this.registerMode ? '注册成功后会自动登录' : '登录后同步购物车与订单')
            .fontSize(12).fontColor('#78857F')
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text('×').fontSize(24).fontColor('#7A8A81').padding(6)
          .onClick(() => { this.authPanelVisible = false; this.authMessage = '' })
      }.width('100%')

      TextInput({ text: this.accountInput, placeholder: '账号（3～64 个字符）' })
        .width('100%').height(46).backgroundColor('#F4F6F2').borderRadius(14)
        .onChange((value: string) => this.accountInput = value)
      TextInput({ text: this.passwordInput, placeholder: '密码（6～32 个字符）' })
        .type(InputType.Password).width('100%').height(46).backgroundColor('#F4F6F2').borderRadius(14)
        .onChange((value: string) => this.passwordInput = value)

      if (this.authMessage.length > 0) {
        Text(this.authMessage).width('100%').fontSize(12).fontColor('#A44A38')
          .padding(10).backgroundColor('#FFF0DF').borderRadius(12)
      }

      Button(this.authSubmitting ? '正在提交…' : (this.registerMode ? '注册并登录' : '登录'))
        .width('100%').height(46).fontSize(15).fontColor('#FFFFFF').backgroundColor('#215C49').borderRadius(14)
        .enabled(!this.authSubmitting).onClick(() => this.submitAuth())
      Text(this.registerMode ? '已有账号，去登录' : '没有账号，去注册')
        .fontSize(12).fontColor('#4D7563').padding(4)
        .onClick(() => { this.registerMode = !this.registerMode; this.authMessage = '' })
    }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(24)
  }

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
            Column({ space: 5 }) {
              Text(this.username.length > 0 ? this.username : '欢迎来到拾光集').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#263D34')
              Text(this.username.length > 0 ? '已同步当前消费者会话' : '登录后同步购物车与订单').fontSize(12).fontColor('#78857F')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text(this.username.length > 0 ? '退出' : '去登录').fontSize(12).fontColor('#FFFFFF').padding({ left: 13, right: 13, top: 8, bottom: 8 }).backgroundColor('#215C49').borderRadius(15)
              .onClick(() => { if (this.username.length > 0) { this.signOut(true) } else { this.authPanelVisible = true } })
          }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(24)

          if (this.authPanelVisible) {
            this.authPanel()
          }

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

          AppCard({
            eyebrow: '拾光集 · 消费者商城',
            title: '让每一次选择，都更接近喜欢',
            description: '关于应用、帮助与服务说明',
            icon: '✦',
            cardBackground: AppColors.BRAND_SOFT,
            onCardClick: () => this.notice = '关于与帮助页面将在后续完善'
          })
          if (this.notice.length > 0) { Text(this.notice).width('100%').fontSize(12).fontColor('#704932').padding(13).backgroundColor('#FFF0DF').borderRadius(15) }
        }.width('100%').padding({ left: 2, right: 2, bottom: 28 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }
}
