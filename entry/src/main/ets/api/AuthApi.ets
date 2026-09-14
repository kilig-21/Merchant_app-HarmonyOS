import { http } from '@kit.NetworkKit'
import { AuthCredentials, AuthUser, LoginResponse } from '../model/AuthModels'
import { HttpClient, RequestOptions } from '../network/HttpClient'

export class AuthApi {
  static async register(username: string, password: string): Promise<AuthUser> {
    return await HttpClient.request<AuthUser>('/api/auth/register',
      new RequestOptions(http.RequestMethod.POST, new AuthCredentials(username, password)))
  }

  static async login(username: string, password: string): Promise<LoginResponse> {
    return await HttpClient.request<LoginResponse>('/api/auth/login',
      new RequestOptions(http.RequestMethod.POST, new AuthCredentials(username, password)))
  }

  static async getCurrentUser(): Promise<AuthUser> {
    return await HttpClient.request<AuthUser>('/api/auth/me')
  }
}
