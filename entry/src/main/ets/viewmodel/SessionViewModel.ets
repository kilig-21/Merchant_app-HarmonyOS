import { common } from '@kit.AbilityKit'
import { AuthApi } from '../api/AuthApi'
import { AuthSession } from '../model/AuthModels'
import { SessionRepository } from '../repository/SessionRepository'
import { HttpClient } from '../network/HttpClient'
import { ApiError } from '../network/ApiError'

/** 会话由应用根节点持有，切换页面不会重新登录或误清空购物状态。 */
@Observed
export class SessionViewModel {
  username: string = ''
  ready: boolean = false
  busy: boolean = false
  error: string = ''

  async restore(context: common.Context): Promise<void> {
    this.ready = false
    this.error = ''
    try {
      const saved = await SessionRepository.load(context)
      if (saved !== null) {
        this.username = saved.user.username
        HttpClient.setAccessToken(saved.accessToken)
        try {
          const user = await AuthApi.getCurrentUser()
          if (user.userType !== 'CONSUMER') { await this.signOut(context) }
          else { this.username = user.username }
        } catch (error) {
          // 断网保留会话，只有明确失效才要求重新登录。
          if (error instanceof ApiError && error.statusCode === 401) { await this.signOut(context) }
        }
      }
    } catch (_) {
      // 恢复失败不能让首页永久停在加载态；用户仍可主动登录。
      HttpClient.clearAccessToken()
      this.username = ''
      this.error = '账户状态暂时无法恢复，请重新登录'
    } finally {
      this.ready = true
    }
  }

  async signIn(context: common.Context, account: string, password: string, register: boolean): Promise<boolean> {
    if (this.busy) { return false }
    this.error = ''
    const username = account.trim()
    if (username.length < 3 || username.length > 64) { this.error = '账号请输入 3～64 个字符'; return false }
    if (password.length < 6 || password.length > 32) { this.error = '密码请输入 6～32 个字符'; return false }
    this.busy = true
    try {
      if (register) { await AuthApi.register(username, password) }
      const result = await AuthApi.login(username, password)
      if (result.user.userType !== 'CONSUMER') { throw new Error('请使用消费者账号登录') }
      await SessionRepository.save(context, new AuthSession(result.accessToken, result.user))
      HttpClient.setAccessToken(result.accessToken)
      this.username = result.user.username
      return true
    } catch (error) {
      this.error = error instanceof Error ? error.message : '暂时无法登录，请重试'
      return false
    } finally { this.busy = false }
  }

  async signOut(context: common.Context): Promise<boolean> {
    try { await SessionRepository.clear(context) }
    catch (_) { this.error = '退出未完成，请重试'; return false }
    HttpClient.clearAccessToken()
    this.username = ''
    this.error = ''
    return true
  }
}
