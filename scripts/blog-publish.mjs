#!/usr/bin/env node
/**
 * Client de publication du blog Portfolio Hermann.
 *
 * Utilise l'API privee documentee dans docs/blog-automation.md.
 * Le jeton BLOG_PUBLISH_TOKEN est lu dans l'environnement et n'est jamais affiche.
 *
 * Usage :
 *   node scripts/blog-publish.mjs check
 *   node scripts/blog-publish.mjs article --file article.json [--status draft|scheduled|published] [--dry-run]
 *   node scripts/blog-publish.mjs media --file cover.webp --alt "Description"
 *   node scripts/blog-publish.mjs delete --slug mon-slug
 *
 * Codes de sortie : 0 succes, 1 erreur API, 2 usage ou configuration.
 */

import { readFile } from "node:fs/promises";
import { basename, extname } from "node:path";

const BASE_URL = (process.env.BLOG_API_URL || "https://portfolio-hermann.fly.dev").replace(/\/+$/, "");
const TOKEN = process.env.BLOG_PUBLISH_TOKEN || "";
const STATUSES = ["draft", "scheduled", "published"];
const IMAGE_TYPES = {
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".gif": "image/gif",
  ".webp": "image/webp",
};

function fail(message, code = 1) {
  console.error("ERREUR: " + message);
  process.exit(code);
}

function parseArgs(argv) {
  const [command, ...rest] = argv;
  const options = {};
  for (let i = 0; i < rest.length; i += 1) {
    const arg = rest[i];
    if (!arg.startsWith("--")) fail("argument inattendu: " + arg, 2);
    const key = arg.slice(2);
    if (key === "dry-run") {
      options["dry-run"] = true;
    } else {
      const value = rest[i + 1];
      if (value === undefined || value.startsWith("--")) fail("valeur manquante pour " + arg, 2);
      options[key] = value;
      i += 1;
    }
  }
  return { command, options };
}

function requireToken() {
  if (!TOKEN) {
    fail(
      "BLOG_PUBLISH_TOKEN est absent de l'environnement. Configurez le secret Fly puis le coffre de secrets de la tache, sans jamais coller le jeton dans un fichier du depot.",
      2,
    );
  }
}

async function api(path, init = {}) {
  const headers = { ...(init.headers || {}), Authorization: "Bearer " + TOKEN };
  let response;
  try {
    response = await fetch(BASE_URL + path, { ...init, headers });
  } catch (error) {
    fail("reseau injoignable (" + BASE_URL + path + "): " + error.message);
  }
  const raw = await response.text();
  let payload = null;
  try {
    payload = raw ? JSON.parse(raw) : null;
  } catch {
    payload = null;
  }
  return { status: response.status, payload, raw };
}

function apiError(result, context) {
  const code = (result.payload && result.payload.error && result.payload.error.code) || "unknown";
  const message =
    (result.payload && result.payload.error && result.payload.error.message) || result.raw.slice(0, 300);
  const hints = {
    not_configured: "BLOG_PUBLISH_TOKEN n'est pas configure sur Fly.io (503).",
    unauthorized:
      "Jeton refuse (401): le secret Fly et le coffre de la tache divergent ou le jeton a ete revoque.",
  };
  fail(context + ": HTTP " + result.status + " [" + code + "] " + message + (hints[code] ? "\n" + hints[code] : ""));
}

function validateArticle(article) {
  const problems = [];
  if (!article.title || String(article.title).trim() === "") problems.push("title est obligatoire");
  if (!article.body_markdown || String(article.body_markdown).trim().length < 500) {
    problems.push("body_markdown est obligatoire et doit contenir un vrai article (>= 500 caracteres)");
  }
  if (article.status !== undefined && !STATUSES.includes(article.status)) {
    problems.push("status doit valoir " + STATUSES.join(", "));
  }
  if (article.status === "scheduled") {
    if (!article.published_at) {
      problems.push("published_at est obligatoire pour une publication programmee");
    } else {
      const when = new Date(article.published_at);
      if (Number.isNaN(when.getTime())) problems.push("published_at doit etre une date ISO 8601 valide");
      else if (when.getTime() <= Date.now()) problems.push("published_at doit etre dans le futur");
    }
  }
  if (article.body_markdown && /<[a-z][\s\S]*>/i.test(article.body_markdown)) {
    problems.push("le HTML brut n'est pas rendu: utilisez uniquement du Markdown");
  }
  if (article.cover_url && !String(article.cover_url).startsWith("/article-media/")) {
    problems.push("cover_url doit provenir de l'endpoint media (/article-media/...)");
  }
  return problems;
}

async function commandCheck() {
  requireToken();
  const result = await api("/api/articles", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title: "", body_markdown: "" }),
  });
  if (result.status === 400 || result.status === 422) {
    console.log("OK: API joignable sur " + BASE_URL + " et jeton accepte (HTTP " + result.status + " attendu sur une charge vide).");
    return;
  }
  apiError(result, "Verification du jeton");
}

async function commandArticle(options) {
  if (!options.file) fail("--file est obligatoire (JSON de l'article)", 2);
  let article;
  try {
    article = JSON.parse(await readFile(options.file, "utf8"));
  } catch (error) {
    fail("lecture du JSON impossible (" + options.file + "): " + error.message, 2);
  }
  if (options.status) article.status = options.status;
  // Publier immédiatement : ne jamais laisser une ancienne date programmée
  // dans la charge utile, sinon l'article resterait programmé.
  if (article.status === "published") delete article.published_at;
  const problems = validateArticle(article);
  if (problems.length > 0) fail("article invalide:\n- " + problems.join("\n- "), 2);

  if (options["dry-run"]) {
    console.log(
      "DRY RUN: " + (article.status || "draft") + " / slug " + (article.slug || "(derive du titre)") + " / " +
        article.body_markdown.length + " caracteres",
    );
    return;
  }

  requireToken();
  const result = await api("/api/articles", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(article),
  });
  if (result.status !== 200 || !result.payload || result.payload.ok !== true) apiError(result, "Publication");

  const saved = result.payload.article;
  console.log("OK: article " + JSON.stringify(saved.title) + " enregistre.");
  console.log("  slug     : " + saved.slug);
  const published = saved.published_at ? " (publie le " + saved.published_at + ")" : "";
  console.log("  statut   : " + saved.status + published);
  console.log("  public   : " + BASE_URL + "/blog/" + saved.slug);
  console.log("  admin    : " + BASE_URL + "/admin/articles");
}

async function commandMedia(options) {
  requireToken();
  if (!options.file) fail("--file est obligatoire (image)", 2);
  const extension = extname(options.file).toLowerCase();
  const type = IMAGE_TYPES[extension];
  if (!type) fail("format non accepte (" + (extension || "sans extension") + "): JPEG, PNG, GIF ou WebP", 2);

  let bytes;
  try {
    bytes = await readFile(options.file);
  } catch (error) {
    fail("lecture de l'image impossible: " + error.message, 2);
  }
  if (bytes.byteLength > 8000000) fail("image trop lourde: 8 Mo maximum", 2);

  const form = new FormData();
  form.append("file", new Blob([bytes], { type }), basename(options.file));
  form.append("alt", options.alt || "");

  const result = await api("/api/articles/media", { method: "POST", body: form });
  if (result.status !== 200 || !result.payload || result.payload.ok !== true) apiError(result, "Televersement");

  console.log("OK: image " + basename(options.file) + " (" + Math.round(bytes.byteLength / 1024) + " Ko)");
  console.log("  url      : " + result.payload.url);
  console.log("  markdown : " + result.payload.markdown);
}

async function commandDelete(options) {
  requireToken();
  if (!options.slug) fail("--slug est obligatoire", 2);
  const result = await api("/api/articles/" + encodeURIComponent(options.slug), { method: "DELETE" });
  if (result.status !== 200 || !result.payload || result.payload.ok !== true) apiError(result, "Suppression");
  console.log("OK: article supprime (" + result.payload.deleted + ").");
}

const { command, options } = parseArgs(process.argv.slice(2));
switch (command) {
  case "check":
    await commandCheck();
    break;
  case "article":
    await commandArticle(options);
    break;
  case "media":
    await commandMedia(options);
    break;
  case "delete":
    await commandDelete(options);
    break;
  default:
    fail("commandes: check | article | media | delete", 2);
}
