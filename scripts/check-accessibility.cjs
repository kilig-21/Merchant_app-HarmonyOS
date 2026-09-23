/* 静态无障碍守卫：覆盖输入名称、图片语义、关闭按钮与无限动画。 */
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '../entry/src/main/ets');
const files = [];
function collect(directory) {
  for (const name of fs.readdirSync(directory)) {
    const full = path.join(directory, name);
    if (fs.statSync(full).isDirectory()) collect(full);
    else if (name.endsWith('.ets')) files.push(full);
  }
}
collect(root);

function nearby(lines, index, count = 6) {
  return lines.slice(index, Math.min(lines.length, index + count)).join('\n');
}

for (const file of files) {
  const source = fs.readFileSync(file, 'utf8');
  const lines = source.split(/\r?\n/);
  lines.forEach((line, index) => {
    if (line.includes('TextInput(') || line.includes('TextArea(')) {
      assert.ok(nearby(lines, index).includes('.accessibilityText('), `${file}:${index + 1} 输入控件缺少无障碍名称`);
    }
    if (line.includes('Image(')) {
      const block = nearby(lines, index, 5);
      assert.ok(block.includes('.accessibilityText(') || block.includes(".accessibilityLevel('no')"),
        `${file}:${index + 1} 图片既没有替代文本，也没有标记为装饰`);
    }
    if (line.includes("Button('×'")) {
      assert.ok(nearby(lines, index, 5).includes('.accessibilityText('), `${file}:${index + 1} 关闭按钮缺少无障碍名称`);
    }
  });
  assert.equal(source.includes('iterations: -1'), false, `${file} 存在无限循环动画`);
}

const home = fs.readFileSync(path.join(root, 'components/home/HomeContent.ets'), 'utf8');
const address = fs.readFileSync(path.join(root, 'pages/AddressManagerPage.ets'), 'utf8');
assert.ok(home.includes("value: ['360vp', '600vp', '840vp']"), '商品目录缺少窗口断点');
assert.ok(address.includes("value: ['360vp']"), '地址表单缺少小屏断点');
console.log(`PASS: ${files.length} 个 ArkTS 文件通过输入名称、图片语义、关闭按钮、有限动画与关键断点检查。`);
