import { ProductSummary, StoreSummary } from '../model/StoreModels'

export interface MockStoreCatalog {
  store: StoreSummary
  products: ProductSummary[]
}

/** 第三家刻意为空，第二家包含售罄商品。 */
export const MOCK_CATALOGS: MockStoreCatalog[] = [
  {
    store: { id: 1001, name: '山野杂货铺', productCount: 3 },
    products: [
      { id: 2001, name: '云雾白茶', description: '清甜回甘，留一段时间给自己。100g 装。', minSalePrice: 128, totalAvailableStock: 24, updatedAt: '2026-09-12T10:00:00' },
      { id: 2002, name: '手作玻璃杯', description: '光落进杯子里，就是日常的风景。360ml。', minSalePrice: 69, totalAvailableStock: 18, updatedAt: '2026-09-12T10:00:00' },
      { id: 2003, name: '雨后木质香氛', description: '雪松与苔藓气息，安静地陪伴一个房间。100ml。', minSalePrice: 89, totalAvailableStock: 12, updatedAt: '2026-09-12T10:00:00' }
    ]
  },
  {
    store: { id: 1002, name: '浮光咖啡研究所', productCount: 2 },
    products: [
      { id: 2101, name: '云南小粒咖啡豆', description: '山野果香与巧克力余韵，适合慢慢冲一杯。200g。', minSalePrice: 58, totalAvailableStock: 36, updatedAt: '2026-09-12T10:00:00' },
      { id: 2102, name: '日常挂耳咖啡', description: '把一杯好咖啡装进口袋。10 袋装，暂时售罄。', minSalePrice: 42.5, totalAvailableStock: 0, updatedAt: '2026-09-12T10:00:00' }
    ]
  },
  { store: { id: 1003, name: '慢慢生活馆', productCount: 0 }, products: [] }
]
