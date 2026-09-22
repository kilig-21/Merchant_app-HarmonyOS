// 仅供本机模拟器界面验收。内存测试数据，不连接真实后端，不写入数据库。
// node scripts/consumer-ui-fixture.cjs；通过 hdc rport tcp:18765 tcp:18765 连接。
const http = require('node:http');
// --visual 仅替换内存验收数据，便于检查插画、长文案与金额的实际排版。
const visual = process.argv.includes('--visual');
const shops = visual ? [
  { id: 1001, name: '山野杂货铺', productCount: 3 },
  { id: 1002, name: '浮光咖啡研究所', productCount: 2 },
  { id: 1003, name: '慢慢生活馆', productCount: 0 }
] : [{ id: 1001, name: '界面验收 · 数码店', productCount: 24 }];
const products = visual ? [
  { id: 2001, storeId: 1001, name: '云雾白茶', description: '一杯清茶，留一点时间给自己。', minSalePrice: 128 },
  { id: 2002, storeId: 1001, name: '日常手作玻璃杯', description: '通透的杯身，盛下一天的小美好。', minSalePrice: 69 },
  { id: 2003, storeId: 1001, name: '山野木质香氛', description: '把安静的森林气息带回家。', minSalePrice: 89 },
  { id: 2101, storeId: 1002, name: '晨间手冲咖啡豆', description: '从一杯咖啡开始，慢慢醒来。', minSalePrice: 58 },
  { id: 2102, storeId: 1002, name: '浮光季节限定挂耳咖啡礼盒', description: '随时随地，认真喝一杯。', minSalePrice: 42.5, totalAvailableStock: 0 }
].map(p => ({ ...p, storeName: shops.find(s => s.id === p.storeId).name,
  totalAvailableStock: p.totalAvailableStock ?? 12, updatedAt: '2026-09-22T10:00:00' })) : Array.from({ length: 24 }, (_, i) => ({
  id: 9000 + i, storeId: 1001, storeName: shops[0].name,
  name: i === 0 ? '界面验收 · 蓝牙耳机' : '界面验收商品 ' + (i + 1),
  description: '仅用于检查移动端显示和操作流程，非真实在售商品。',
  minSalePrice: 188 + i, totalAvailableStock: 12, updatedAt: '2026-09-19T04:00:00'
}));
let cart = [], addresses = [], orders = [], next = 1;
const groups = new Map();
const skus = product => [
  { id: product.id * 10, skuName: visual ? '日常装' : '白色 / 标准版', salePrice: product.minSalePrice, availableStock: product.totalAvailableStock === 0 ? 0 : 8 },
  { id: product.id * 10 + 1, skuName: visual ? '双份礼盒装' : '黑色 / 高配版', salePrice: product.minSalePrice + 80, availableStock: product.totalAvailableStock === 0 ? 0 : 4 },
  { id: product.id * 10 + 2, skuName: visual ? '季节限定礼盒' : '银色 / 限定版', salePrice: product.minSalePrice + 120, availableStock: 0 }
];
if (visual) {
  addresses.push({ id: next++, receiverName: '界面验收', receiverPhone: '13800000000',
    province: '浙江省', city: '杭州市', district: '西湖区', detailAddress: '测试路 18 号（虚拟地址）',
    isDefault: true, createdAt: '2026-09-22T10:00:00', updatedAt: '2026-09-22T10:00:00' });
}
http.createServer(async (req, res) => {
  let data = null, code = 0, message = 'ok';
  const url = new URL(req.url, 'http://localhost');
  const route = url.pathname, method = req.method;
  let body = '';
  for await (const chunk of req) body += chunk;
  const input = body ? JSON.parse(body) : {};
  if (route === '/api/auth/login') {
    data = { accessToken: 'ui-fixture-only', user: { id: 1, username: input.username, userType: 'CONSUMER', tenantId: null } };
  } else if (route === '/api/auth/me' || route === '/api/auth/register') {
    data = { id: 1, username: visual ? '拾光体验员' : 'ui-review', userType: 'CONSUMER', tenantId: null };
  } else if (route === '/api/public/stores') data = shops;
  else if (route.endsWith('/products/search') || /^\/api\/public\/stores\/\d+\/products$/.test(route)) {
    const storeId = route.endsWith('/products/search') ? 0 : Number(route.split('/')[4]);
    const matches = products.filter(p => (!storeId || p.storeId === storeId) && (p.name + p.storeName).includes(url.searchParams.get('keyword') || ''));
    const page = Number(url.searchParams.get('page') || 1), size = Number(url.searchParams.get('size') || 20);
    data = matches.slice((page - 1) * size, page * size);
  } else if (/^\/api\/public\/stores\/\d+\/products\/\d+$/.test(route)) {
    const product = products.find(p => p.id === Number(route.split('/').pop()));
    data = { ...product, skus: skus(product) };
  } else if (route.startsWith('/api/cart/items')) {
    if (method === 'POST') {
      const product = products.find(p => skus(p).some(s => s.id === input.skuId));
      const sku = skus(product).find(s => s.id === input.skuId);
      const old = cart.find(p => p.skuId === input.skuId);
      if (old) old.quantity += input.quantity;
      else cart.push({ id: next++, skuId: sku.id, skuName: sku.skuName, productId: product.id, productName: product.name,
        storeId: product.storeId, storeName: product.storeName, quantity: input.quantity, salePrice: sku.salePrice,
        availableStock: sku.availableStock, purchasable: true, unavailableReason: null });
    } else if (method === 'PUT') cart.find(p => p.id === Number(route.split('/').pop())).quantity = input.quantity;
    else if (method === 'DELETE') cart = cart.filter(p => p.id !== Number(route.split('/').pop()));
    data = method === 'GET' ? cart : null;
  } else if (route.startsWith('/api/addresses')) {
    if (method === 'POST') addresses.push({ ...input, id: next++, createdAt: '2026-09-19T04:00:00', updatedAt: '2026-09-19T04:00:00' });
    if (method === 'PUT') addresses = addresses.map(a => a.id === Number(route.split('/').pop()) ? { ...a, ...input } : a);
    if (method === 'DELETE') addresses = addresses.filter(a => a.id !== Number(route.split('/').pop()));
    data = method === 'GET' ? addresses : null;
  } else if (route === '/api/checkouts' && method === 'POST') {
    const key = req.headers['idempotency-key'];
    if (groups.has(key)) data = groups.get(key);
    else {
      const items = cart.filter(p => input.cartItemIds.includes(p.id));
      const address = addresses.find(a => a.id === input.addressId);
      if (!address || !items.length) { code = 400; message = '请选择商品和地址'; }
      else {
        const id = next++, total = items.reduce((sum, p) => sum + p.salePrice * p.quantity, 0);
        const order = { id, checkoutGroupId: id, orderNo: 'UI-ORDER-' + id, tenantId: 1001, status: 'PENDING_PAYMENT',
          totalAmount: total, expireAt: null, createdAt: '2026-09-19T04:00:00',
          shippingAddress: { ...address }, items: items.map(p => ({ id: p.id, skuId: p.skuId,
            skuNameSnapshot: p.skuName, salePrice: p.salePrice, quantity: p.quantity })) };
        orders.unshift(order);
        data = { checkoutGroupId: id, checkoutNo: 'UI-CHECKOUT-' + id, status: 'PENDING_PAYMENT', totalAmount: total,
          orders: [{ orderId: id, orderNo: order.orderNo, status: order.status, totalAmount: total, expireAt: null }] };
        groups.set(key, data);
        cart = cart.filter(p => !input.cartItemIds.includes(p.id));
      }
    }
  } else if (route === '/api/orders') data = orders;
  else if (route.startsWith('/api/orders/')) {
    const id = Number(route.split('/')[3]), order = orders.find(o => o.id === id);
    if (route.endsWith('/cancel')) { order.status = 'CANCELLED'; data = null; } else data = order;
  } else { code = 404; message = '界面测试未配置此接口'; }
  res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({ code, message, data }));
}).listen(18765, '127.0.0.1', () => console.log('UI fixture only: 127.0.0.1:18765'));
