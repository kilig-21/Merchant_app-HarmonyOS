import { DiscoveryProduct, ProductDetail, ProductSkuAvailability } from '../model/ProductModels'
import { ProductSummary } from '../model/StoreModels'
import { HttpClient, QueryParam, RequestOptions } from '../network/HttpClient'

export class ProductApi {
  static async searchProducts(keyword: string, storeId?: number, page: number = 1, size: number = 20): Promise<DiscoveryProduct[]> {
    const query: QueryParam[] = [new QueryParam('keyword', keyword), new QueryParam('page', page), new QueryParam('size', size)]
    if (storeId !== undefined) {
      query.push(new QueryParam('storeId', storeId))
    }
    return await HttpClient.request<DiscoveryProduct[]>('/api/public/stores/products/search',
      new RequestOptions(undefined, undefined, query))
  }

  static async getProducts(storeId: number, page: number = 1, size: number = 20): Promise<ProductSummary[]> {
    const query: QueryParam[] = [new QueryParam('page', page), new QueryParam('size', size)]
    return await HttpClient.request<ProductSummary[]>(`/api/public/stores/${storeId}/products`,
      new RequestOptions(undefined, undefined, query))
  }

  static async getProduct(storeId: number, productId: number): Promise<ProductDetail> {
    return await HttpClient.request<ProductDetail>(`/api/public/stores/${storeId}/products/${productId}`)
  }

  static async getSkuAvailability(skuId: number): Promise<ProductSkuAvailability> {
    return await HttpClient.request<ProductSkuAvailability>(`/api/public/skus/${skuId}/availability`)
  }
}
