// MD → HTML converter using marked (npm)
// Usage: node md2html.js <md_path> <html_out> <css_path> <title>
const fs = require('fs');
const { marked } = require('marked');

const [, , mdPath, htmlPath, cssPath, title] = process.argv;

if (!mdPath || !htmlPath) {
  console.error('Usage: node md2html.js <md_path> <html_out> [css_path] [title]');
  process.exit(1);
}

const md = fs.readFileSync(mdPath, 'utf8');
const css = cssPath && fs.existsSync(cssPath) ? fs.readFileSync(cssPath, 'utf8') : '';

marked.setOptions({ gfm: true, breaks: false });
const bodyHtml = marked.parse(md);

const html = `<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<title>${(title || 'document').replace(/[<>&"]/g, c => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', '"': '&quot;' }[c]))}</title>
<style>
${css}
</style>
</head>
<body>
${bodyHtml}
</body>
</html>`;

fs.writeFileSync(htmlPath, html, 'utf8');
console.log(`HTML written: ${htmlPath}`);
