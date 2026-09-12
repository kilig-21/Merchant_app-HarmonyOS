import { ProductSummary } from './StoreModels'

export interface ProductSku {
  id: number
  skuName: string
  salePrice: number
  availableStock: number
}
export interface ProductDetail {
  id: number
  name: string
  description: string
  updatedAt: string
  skus: ProductSku[]
}
export interface ProductRoute {
  storeId: number
  productId: number
}
export interface DiscoveryProduct extends ProductSummary {
  storeId: number
  storeName: string
}
