/** 本地演示图映射，不作为后端图片字段。未知商品统一使用占位图。 */
export class ProductArtwork {
  static resolve(productId: number): Resource {
    if (productId === 2002) { return $r('app.media.browse_glass') }
    if (productId === 2003) { return $r('app.media.browse_scent') }
    if (productId === 2101 || productId === 2102) { return $r('app.media.browse_coffee') }
    return $r('app.media.browse_tea')
  }
}
