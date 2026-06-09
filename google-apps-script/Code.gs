/**
 * Fyndroo signup webhook — append rows to Google Sheets + email notification.
 *
 * Setup: see google-apps-script/SETUP.md
 */

var HEADERS = [
  "Timestamp",
  "Plan",
  "Name",
  "Email",
  "Company",
  "Website",
  "Clients",
  "Message",
  "Source",
];

function setupSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("Signups");
  if (!sheet) {
    sheet = ss.insertSheet("Signups");
  }
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(HEADERS);
    sheet.setFrozenRows(1);
    sheet.getRange(1, 1, 1, HEADERS.length).setFontWeight("bold");
  }
  return sheet;
}

function doGet() {
  return response_({ ok: true, message: "Fyndroo signup webhook is live. Use POST to submit." });
}

function doPost(e) {
  try {
    var props = PropertiesService.getScriptProperties();
    var expectedSecret = props.getProperty("WEBHOOK_SECRET");
    var notifyEmail = props.getProperty("NOTIFY_EMAIL");

    var body = {};
    if (e && e.postData && e.postData.contents) {
      body = JSON.parse(e.postData.contents);
    }

    if (expectedSecret && body.secret !== expectedSecret) {
      return response_({ ok: false, error: "Unauthorized" }, 401);
    }

    var row = [
      body.submittedAt || new Date().toISOString(),
      body.plan || "",
      body.name || "",
      body.email || "",
      body.company || "",
      body.website || "",
      body.clients || "",
      body.message || "",
      body.source || "biz.fyndroo.com",
    ];

    var sheet = setupSheet_();
    sheet.appendRow(row);

    if (notifyEmail) {
      var subject = "New Fyndroo signup — " + (body.plan || "unknown") + " — " + (body.company || body.name);
      var text =
        "Plan: " + (body.plan || "") + "\n" +
        "Name: " + (body.name || "") + "\n" +
        "Email: " + (body.email || "") + "\n" +
        "Company: " + (body.company || "") + "\n" +
        "Website: " + (body.website || "") + "\n" +
        "Clients: " + (body.clients || "") + "\n" +
        "Message: " + (body.message || "") + "\n" +
        "Source: " + (body.source || "") + "\n" +
        "Time: " + (body.submittedAt || new Date().toISOString());

      MailApp.sendEmail(notifyEmail, subject, text);
    }

    return response_({ ok: true });
  } catch (err) {
    return response_({ ok: false, error: String(err) }, 500);
  }
}

function response_(payload, status) {
  var output = ContentService.createTextOutput(JSON.stringify(payload));
  output.setMimeType(ContentService.MimeType.JSON);
  return output;
}
