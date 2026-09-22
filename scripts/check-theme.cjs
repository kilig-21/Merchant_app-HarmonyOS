// 检查共享色板的文字对比度；不替代设备上的字号、触控和读屏验收。
// 使用项目色板源码，避免另存一份颜色后与实际界面脱节。
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '../entry/src/main/ets/theme/AppTheme.ets'), 'utf8');
const colors = Object.fromEntries(
  [...source.matchAll(/static readonly (\w+): string = '(#[\da-f]{6})'/gi)].map(match => [match[1], match[2]])
);
function luminance(hex) {
  assert.match(hex || '', /^#[\da-f]{6}$/i, '共享主题必须提供六位 RGB 颜色');
  const [red, green, blue] = hex.slice(1).match(/../g).map(value => {
    const channel = parseInt(value, 16) / 255;
    return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
  });
  return red * 0.2126 + green * 0.7152 + blue * 0.0722;
}
function ratio(a, b) {
  const first = luminance(a), second = luminance(b);
  return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05);
}
let pairs = 0;
for (const foreground of ['TEXT_PRIMARY', 'TEXT_SECONDARY', 'TEXT_TERTIARY', 'ACCENT', 'DANGER', 'SUCCESS']) {
  for (const background of ['BACKGROUND', 'SURFACE', 'SAND', 'BRAND_SOFT', 'ACCENT_SOFT']) {
    const contrast = ratio(colors[foreground], colors[background]);
    assert.ok(contrast >= 4.5, `${foreground} / ${background} = ${contrast.toFixed(2)}，小字对比度低于 4.5`);
    pairs++;
  }
}
for (const background of ['BRAND', 'ACCENT', 'SUCCESS']) {
  assert.ok(ratio(colors.SURFACE, colors[background]) >= 4.5, `反白文字 / ${background} 对比度不足`);
  pairs++;
}
console.log(`PASS: ${pairs} 组共享主题文字色与底色对比度均不低于 4.5:1。`);
