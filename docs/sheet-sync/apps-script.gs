/**
 * Dhopa Bari — Orders → Google Sheet sync.
 *
 * Receives an order (JSON POST) from Supabase and upserts it as a row,
 * keyed by the order's UUID (last column). So a new order adds a row and a
 * later status/detail change updates that SAME row — the sheet always shows
 * each order's latest state.
 *
 * SETUP:
 *  1. Open your Google Sheet → Extensions → Apps Script.
 *  2. Delete any sample code, paste ALL of this, Save.
 *  3. Deploy → New deployment → type "Web app".
 *       - Execute as: Me
 *       - Who has access: Anyone
 *     Deploy → copy the Web app URL (ends with /exec).
 *  4. Put that URL into the Supabase SQL (sheet-sync.sql).
 */

var SHEET_NAME = 'Orders';
var HEADERS = ['অর্ডার আইডি', 'কাস্টমার', 'ফোন', 'সার্ভিস', 'ক্যাটাগরি', 'আইটেম',
               'পিস', 'মোট', 'স্ট্যাটাস', 'অ্যাপ্রুভড', 'রাইডার', 'ঠিকানা',
               'পেমেন্ট', 'তারিখ', 'UUID'];

function doPost(e) {
  var lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    var d = JSON.parse(e.postData.contents);
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);

    if (sheet.getLastRow() === 0) {
      sheet.appendRow(HEADERS);
      sheet.getRange(1, 1, 1, HEADERS.length).setFontWeight('bold');
      sheet.setFrozenRows(1);
    }

    var row = [
      d.order_no, d.customer_name, d.customer_phone, d.service, d.category,
      d.items, d.pieces, d.total, d.status, d.approved ? 'হ্যাঁ' : 'না',
      d.rider_name, d.address, d.payment_method, d.created_at, d.uuid
    ];

    // Upsert by UUID (last column).
    var uuidCol = HEADERS.length;
    var lastRow = sheet.getLastRow();
    var target = 0;
    if (lastRow > 1) {
      var uuids = sheet.getRange(2, uuidCol, lastRow - 1, 1).getValues();
      for (var i = 0; i < uuids.length; i++) {
        if (uuids[i][0] === d.uuid) { target = i + 2; break; }
      }
    }
    if (target > 0) {
      sheet.getRange(target, 1, 1, row.length).setValues([row]);
    } else {
      sheet.appendRow(row);
    }

    return ContentService
      .createTextOutput(JSON.stringify({ ok: true }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ ok: false, error: String(err) }))
      .setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}
