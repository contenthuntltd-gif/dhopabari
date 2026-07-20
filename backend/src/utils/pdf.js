/**
 * Minimal, dependency-free PDF generator for order invoices. Produces a
 * single-page PDF with plain text lines — enough for a real, openable
 * invoice without pulling in a heavyweight PDF library. Swap for
 * `pdfkit`/`puppeteer` later if branded, multi-page invoices are needed.
 */
function textInvoicePdf(lines) {
  const escape = (s) => String(s).replace(/[()\\]/g, (c) => `\\${c}`);
  const streamLines = lines
    .map((line, i) => `BT /F1 12 Tf 40 ${780 - i * 18} Td (${escape(line)}) Tj ET`)
    .join('\n');
  const content = `${streamLines}\n`;
  const contentLength = Buffer.byteLength(content, 'utf8');

  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    `<< /Length ${contentLength} >>\nstream\n${content}endstream`,
  ];

  let pdf = '%PDF-1.4\n';
  const offsets = [0];
  objects.forEach((obj, i) => {
    offsets.push(pdf.length);
    pdf += `${i + 1} 0 obj\n${obj}\nendobj\n`;
  });
  const xrefStart = pdf.length;
  pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (let i = 1; i <= objects.length; i++) {
    pdf += `${String(offsets[i]).padStart(10, '0')} 00000 n \n`;
  }
  pdf += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF`;

  return Buffer.from(pdf, 'utf8');
}

module.exports = { textInvoicePdf };
