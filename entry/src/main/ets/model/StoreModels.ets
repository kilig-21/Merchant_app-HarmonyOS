/** 公开接口响应字段，视觉素材不属于接口合同。 */
export interface StoreSummary {
  id: number
  name: string
  productCount: number
}

export interface ProductSummary {
  id: number
  name: string
  description: string
  minSalePrice: number
  totalAvailableStock: number
  updatedAt: string
}
