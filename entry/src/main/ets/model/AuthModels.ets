export interface AuthUser {
  id: number
  username: string
  userType: string
  tenantId: number | null
}

export interface LoginResponse {
  accessToken: string
  user: AuthUser
}

export class AuthCredentials {
  username: string
  password: string

  constructor(username: string, password: string) {
    this.username = username
    this.password = password
  }
}

export class AuthSession {
  accessToken: string
  user: AuthUser

  constructor(accessToken: string, user: AuthUser) {
    this.accessToken = accessToken
    this.user = user
  }
}
