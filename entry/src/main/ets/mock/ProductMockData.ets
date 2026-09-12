import { ProductSku } from '../model/ProductModels'

export interface MockProductSkus {
  productId: number
  skus: ProductSku[]
}
/** 规格的最低价、库存和 BrowseMockData 摘要保持一致。 */
export const MOCK_PRODUCT_SKUS: MockProductSkus[] = [
  { productId: 2001, skus: [
    { id: 3001, skuName: '经典罐装 · 100g', salePrice: 128, availableStock: 18 },
    { id: 3002, skuName: '双罐礼盒 · 200g', salePrice: 238, availableStock: 6 },
    { id: 3003, skuName: '便携小袋 · 100g', salePrice: 128, availableStock: 0 }
  ] },
  { productId: 2002, skus: [
    { id: 3011, skuName: '透明 · 360ml', salePrice: 69, availableStock: 12 },
    { id: 3012, skuName: '烟灰 · 360ml', salePrice: 79, availableStock: 6 }
  ] },
  { productId: 2003, skus: [
    { id: 3021, skuName: '雨后雪松 · 100ml', salePrice: 89, availableStock: 8 },
    { id: 3022, skuName: '山间苔藓 · 100ml', salePrice: 99, availableStock: 4 }
  ] },
  { productId: 2101, skus: [
    { id: 3101, skuName: '日晒 · 咖啡豆 200g', salePrice: 58, availableStock: 24 },
    { id: 3102, skuName: '水洗 · 咖啡豆 200g', salePrice: 68, availableStock: 12 }
  ] },
  { productId: 2102, skus: [
    { id: 3111, skuName: '混合风味 · 10 袋', salePrice: 42.5, availableStock: 0 }
  ] }
]
