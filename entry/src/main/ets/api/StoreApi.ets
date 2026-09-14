import { StoreSummary } from '../model/StoreModels'
import { HttpClient } from '../network/HttpClient'

export class StoreApi {
  static async getStores(): Promise<StoreSummary[]> {
    return await HttpClient.request<StoreSummary[]>('/api/public/stores')
  }
}
