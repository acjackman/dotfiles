/**
 * Tests for the Finicky browser-routing config.
 *
 * Imports the *rendered* config (~/.config/finicky/finicky.js) so we test
 * exactly what Finicky sees at runtime. Run with:
 *
 *   node --test dot_config/finicky/finicky.test.mjs
 */

import { describe, it, before } from "node:test";
import assert from "node:assert/strict";

// Finicky exposes these globals — stub them so the config can load.
globalThis.finicky = {
  notify() {},
  log() {},
};

// Import the rendered (deployed) config.
const { default: config } = await import(
  `${process.env.HOME}/.config/finicky/finicky.js`
);

// ---------------------------------------------------------------------------
// Helpers: replicate Finicky's URL matching
// ---------------------------------------------------------------------------

/** Parse a URL string into the shape Finicky passes to match functions. */
function parseUrl(urlString) {
  const u = new URL(urlString);
  return {
    protocol: u.protocol.replace(/:$/, ""),
    username: u.username,
    password: u.password,
    host: u.hostname,
    port: u.port ? Number(u.port) : null,
    pathname: u.pathname,
    search: u.search.replace(/^\?/, ""),
    hash: u.hash.replace(/^#/, ""),
    href: u.href,
  };
}

/**
 * Convert a Finicky glob string to a regex.
 * Supports `*` (any chars) matching — good enough for the patterns in our config.
 */
function globToRegex(glob) {
  const escaped = glob.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*");
  return new RegExp(`^${escaped}$`);
}

/**
 * Test whether a Finicky string/glob pattern matches a URL.
 * Finicky tries the pattern against the full href, and also against
 * host+pathname (so "music.apple.com*" matches without needing "https://").
 */
function matchGlob(pattern, url) {
  const re = globToRegex(pattern);
  return re.test(url.href) || re.test(url.host + url.pathname + (url.search ? "?" + url.search : ""));
}

/** Test whether a single matcher matches a URL object. */
function matchOne(matcher, url) {
  if (typeof matcher === "function") return matcher(url);
  if (matcher instanceof RegExp) return matcher.test(url.href);
  if (typeof matcher === "string") return matchGlob(matcher, url);
  return false;
}

/** Test whether a handler's match field matches a URL object. */
function matches(handler, url) {
  const m = handler.match;
  if (Array.isArray(m)) return m.some((sub) => matchOne(sub, url));
  return matchOne(m, url);
}

/** Find the first matching handler for a URL string, returns handler or null. */
function resolve(urlString) {
  const url = parseUrl(urlString);
  return config.handlers.find((h) => matches(h, url)) ?? null;
}

/** Get the browser name from a resolved handler. */
function browserName(handler) {
  if (!handler) return null;
  const b = handler.browser;
  if (typeof b === "string") return b;
  if (typeof b === "object" && b.name) return b.name;
  // function-based browser (e.g. phishing blocker) — just mark it as "custom"
  if (typeof b === "function") return "<custom>";
  return null;
}

/** Shorthand: resolve a URL and return its browser name (null = default browser). */
function routesTo(urlString) {
  return browserName(resolve(urlString));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("Linear", () => {
  const app = "Linear";

  describe("opens in Linear app", () => {
    const workspace = [
      "https://linear.app/moov/issue/INFRA-4513/add-per-app-team-vault-policies",
      "https://linear.app/moov/team/INFRA/all",
      "https://linear.app/moov/view/infra-projects-d32f1412d38fd",
      "https://linear.app/moov/team/INFRA/projects/view/d59c1b92-a81c-46a9-be37-6eda379733f2",
      "https://linear.app/moov/projects/all",
      "https://linear.app/moov/teams",
      "https://linear.app/moov/initiatives",
      "https://linear.app/moov/inbox",
      "https://linear.app/moov/cycles",
    ];
    for (const url of workspace) {
      it(url.replace("https://linear.app", ""), () => {
        assert.equal(routesTo(url), app);
      });
    }
  });

  describe("opens in default browser", () => {
    const browser = [
      "https://linear.app/changelog/2026-02-13-advanced-filters",
      "https://linear.app/changelog/2026-02-13-advanced-filters?noRedirect=1",
      "https://linear.app/docs/some-doc",
      "https://linear.app/help",
      "https://linear.app/help/articles/something",
      "https://linear.app/settings",
      "https://linear.app/integrations/github",
      "https://linear.app/",
    ];
    for (const url of browser) {
      it(url.replace("https://linear.app", ""), () => {
        assert.notEqual(routesTo(url), app);
      });
    }
  });

  it("noRedirect=1 forces default browser even for workspace URLs", () => {
    assert.notEqual(
      routesTo("https://linear.app/moov/issue/INFRA-100?noRedirect=1"),
      "Linear"
    );
  });
});

describe("Google Meet", () => {
  it("routes meet links to OpenMeetInChrome app", () => {
    const b = routesTo("https://meet.google.com/abc-defg-hij");
    assert.ok(b && b.includes("OpenMeetInChrome"), `expected OpenMeetInChrome, got ${b}`);
  });

  it("does not match bare meet.google.com", () => {
    const b = routesTo("https://meet.google.com/");
    // bare domain shouldn't match the /. pattern — goes to default
    assert.ok(!b || !b.includes("OpenMeetInChrome"));
  });
});

describe("Zoom", () => {
  it("routes zoom join links", () => {
    assert.equal(routesTo("https://zoom.us/join"), "us.zoom.xos");
  });
});

describe("Discord", () => {
  it("routes discord links", () => {
    assert.equal(routesTo("https://discord.com/channels/123"), "Discord");
  });
});

describe("GitHub", () => {
  it("routes to Chrome", () => {
    assert.equal(routesTo("https://github.com/moov-io/repo"), "Google Chrome");
  });
});

describe("Notion", () => {
  it("routes notion links", () => {
    assert.equal(routesTo("https://www.notion.so/some-page"), "Notion");
  });
});

describe("Apple Music", () => {
  it("routes music.apple.com links", () => {
    assert.equal(routesTo("https://music.apple.com/album/123"), "Music");
  });
});

describe("Phishing blocker", () => {
  it("catches donotreply.biz links", () => {
    const handler = resolve("https://evil.donotreply.biz/click");
    assert.ok(handler, "should match phishing handler");
  });
});

describe("Default browser", () => {
  it("unmatched URLs fall through to default", () => {
    assert.equal(routesTo("https://example.com/something"), null);
  });
});
