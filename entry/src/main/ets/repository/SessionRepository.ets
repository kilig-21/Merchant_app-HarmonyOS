import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { AuthSession, AuthUser } from '../model/AuthModels'

/** 开发期会话存储：不记录密码，持久化 Token 与最小用户信息。 */
export class SessionRepository {
  private static readonly FILE_NAME: string = 'consumer_session'
  private static readonly TOKEN_KEY: string = 'accessToken'
  private static readonly USER_KEY: string = 'user'

  static async load(context: common.Context): Promise<AuthSession | null> {
    try {
      const store = await preferences.getPreferences(context, SessionRepository.FILE_NAME)
      const token = store.getSync(SessionRepository.TOKEN_KEY, '') as string
      const userText = store.getSync(SessionRepository.USER_KEY, '') as string
      if (token.length === 0 || userText.length === 0) {
        return null
      }

      const user = JSON.parse(userText) as AuthUser
      if (typeof user.id !== 'number' || user.username.length === 0) {
        return null
      }
      return new AuthSession(token, user)
    } catch (_) {
      return null
    }
  }

  static async save(context: common.Context, session: AuthSession): Promise<void> {
    try {
      const store = await preferences.getPreferences(context, SessionRepository.FILE_NAME)
      await store.put(SessionRepository.TOKEN_KEY, session.accessToken)
      await store.put(SessionRepository.USER_KEY, JSON.stringify(session.user))
      await store.flush()
    } catch (_) {
      throw new Error('会话保存失败')
    }
  }

  static async clear(context: common.Context): Promise<void> {
    try {
      const store = await preferences.getPreferences(context, SessionRepository.FILE_NAME)
      await store.delete(SessionRepository.TOKEN_KEY)
      await store.delete(SessionRepository.USER_KEY)
      await store.flush()
    } catch (_) {
      throw new Error('会话清理失败')
    }
  }
}
