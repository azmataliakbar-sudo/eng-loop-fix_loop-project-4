const fs = require('fs');
const path = require('path');

const mode = process.argv[2] || 'good';
const srcFile = path.join(__dirname, 'src', 'calc.js');

const good = `function add(a, b) { return a + b; }
function subtract(a, b) { return a - b; }
function multiply(a, b) { return a * b; }
module.exports = { add, subtract, multiply };
`;

const bad = `function add(a, b) { return a + b; }
function subtract(a, b) { return a - b; }
function multiply(a, b) { return a - b; }
module.exports = { add, subtract, multiply };
`;

const content = mode === 'bad' ? bad : good;
fs.writeFileSync(srcFile, content);
