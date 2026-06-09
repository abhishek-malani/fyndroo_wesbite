const JSON_HEADERS = { "content-type": "application/json; charset=utf-8" };

function json(status, body) {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

function isEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

async function verifyTurnstile(token, secret, ip) {
  const form = new URLSearchParams();
  form.set("secret", secret);
  form.set("response", token);
  if (ip) form.set("remoteip", ip);

  const res = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    body: form,
  });
  const data = await res.json();
  return Boolean(data.success);
}

export async function onRequestPost({ request, env }) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json(400, { ok: false, error: "Invalid JSON body." });
  }

  const plan = String(body.plan || "").trim().toLowerCase();
  const name = String(body.name || "").trim();
  const email = String(body.email || "").trim();
  const company = String(body.company || "").trim();
  const website = String(body.website || "").trim();
  const message = String(body.message || "").trim();
  const clients = String(body.clients || "").trim();
  const turnstileToken = String(body.turnstileToken || "").trim();

  const allowedPlans = new Set(["basic", "pro", "agency"]);
  if (!allowedPlans.has(plan)) {
    return json(400, { ok: false, error: "Invalid plan." });
  }
  if (!name || name.length < 2) {
    return json(400, { ok: false, error: "Please enter your name." });
  }
  if (!isEmail(email)) {
    return json(400, { ok: false, error: "Please enter a valid email." });
  }
  if (!company || company.length < 2) {
    return json(400, { ok: false, error: "Please enter your company name." });
  }

  const turnstileSecret = env.TURNSTILE_SECRET_KEY;
  if (turnstileSecret) {
    if (!turnstileToken) {
      return json(400, { ok: false, error: "Captcha verification required." });
    }
    const ip = request.headers.get("CF-Connecting-IP");
    const valid = await verifyTurnstile(turnstileToken, turnstileSecret, ip);
    if (!valid) {
      return json(400, { ok: false, error: "Captcha verification failed." });
    }
  }

  const webhookUrl = env.GOOGLE_SHEETS_WEBHOOK_URL;
  if (!webhookUrl) {
    return json(503, { ok: false, error: "Signup is not configured yet." });
  }

  const payload = {
    secret: env.WEBHOOK_SECRET || "",
    submittedAt: new Date().toISOString(),
    source: "biz.fyndroo.com",
    plan,
    name,
    email,
    company,
    website,
    message,
    clients,
  };

  let sheetsRes;
  try {
    sheetsRes = await fetch(webhookUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload),
    });
  } catch {
    return json(502, { ok: false, error: "Could not reach Google Sheets." });
  }

  const raw = await sheetsRes.text();
  let sheetsBody = null;
  try {
    sheetsBody = JSON.parse(raw);
  } catch {
    return json(502, {
      ok: false,
      error: "Google Sheets returned an invalid response. Redeploy Apps Script with doPost saved.",
    });
  }

  if (!sheetsRes.ok || sheetsBody.ok !== true) {
    return json(502, {
      ok: false,
      error: sheetsBody.error || "Google Sheets rejected the submission.",
    });
  }

  return json(200, { ok: true });
}
