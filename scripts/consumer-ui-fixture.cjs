// 仅供本机模拟器界面验收。内存测试数据，不连接真实后端，不写入数据库。
// node scripts/consumer-ui-fixture.cjs；通过 hdc rport tcp:18765 tcp:18765 连接。
const http = require('node:http');
const shops = [{ id: 1001, name: '界面验收 · 数码店', productCount: 24 }];
const products = Array.from({ length: 24 }, (_, i) => ({
  id: 9000 + i, storeId: 1001, storeName: shops[0].name,
  name: i === 0 ? '界面验收 · 蓝牙耳机' : '界面验收商品 ' + (i + 1),
  description: '仅用于检查移动端显示和操作流程，非真实在售商品。',
  minSalePrice: 188 + i, totalAvailableStock: 12, updatedAt: '2026-09-19T04:00:00'
}));
let cart = [], addresses = [], orders = [], next = 1;
const groups = new Map();
const skus = product => [
  { id: product.id * 10, skuName: '白色 / 标准版', salePrice: product.minSalePrice, availableStock: 8 },
  { id: product.id * 10 + 1, skuName: '黑色 / 高配版', salePrice: product.minSalePrice + 80, availableStock: 4 },
  { id: product.id * 10 + 2, skuName: '银色 / 限定版', salePrice: product.minSalePrice + 120, availableStock: 0 }
];
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
    data = { id: 1, username: 'ui-review', userType: 'CONSUMER', tenantId: null };
  } else if (route === '/api/public/stores') data = shops;
  else if (route.endsWith('/products/search') || route === '/api/public/stores/1001/products') {
    const matches = products.filter(p => (p.name + p.storeName).includes(url.searchParams.get('keyword') || ''));
    const page = Number(url.searchParams.get('page') || 1), size = Number(url.searchParams.get('size') || 20);
    data = matches.slice((page - 1) * size, page * size);
  } else if (route.startsWith('/api/public/stores/1001/products/')) {
    const product = products.find(p => p.id === Number(route.split('/').pop()));
    data = { ...product, skus: skus(product) };
  } else if (route.startsWith('/api/cart/items')) {
    if (method === 'POST') {
      const product = products.find(p => skus(p).some(s => s.id === input.skuId));
      const sku = skus(product).find(s => s.id === input.skuId);
      const old = cart.find(p => p.skuId === input.skuId);
      if (old) old.quantity += input.quantity;
      else cart.push({ id: next++, skuId: sku.id, skuName: sku.skuName, productId: product.id, productName: product.name,
        storeId: 1001, storeName: shops[0].name, quantity: input.quantity, salePrice: sku.salePrice,
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
