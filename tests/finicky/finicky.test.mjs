/**
 * Tests for the Finicky browser-routing config.
 *
 * Imports the static buildConfig() factory from the source tree and exercises
 * it against every fixture in ./fixtures/. No rendering required — fixtures
 * encode each variant's expected extras-shaped data, and the matrix of
 * (variant × assertions) covers both moov and non-moov paths in one run.
 */

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

// Finicky exposes these globals — stub them so the factory can run.
globalThis.finicky = {
  notify() {},
  log() {},
};

import { buildConfig } from "../../dot_config/finicky/buildConfig.js";

// Machine-derived defaults: filled in by chezmoi at render time. Tests use
// stable stub values so fixtures don't need to spell out paths derived from
// the runner's HOME (which would force per-machine fixtures).
const machineStub = {
  meet_app_path: "/test-home/Applications/OpenMeetInChrome.app",
};

const fixturesDir = fileURLToPath(new URL("./fixtures/", import.meta.url));
const fixtures = readdirSync(fixturesDir)
  .filter((f) => f.endsWith(".json"))
  .map((f) => ({
    name: path.basename(f, ".json"),
    data: { ...machineStub, ...JSON.parse(readFileSync(path.join(fixturesDir, f), "utf8")) },
  }));

// ---------------------------------------------------------------------------
// Helpers: replicate Finicky's URL matching against a built config.
// ---------------------------------------------------------------------------

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

function globToRegex(glob) {
  const escaped = glob.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*");
  return new RegExp(`^${escaped}$`);
}

function matchGlob(pattern, url) {
  const re = globToRegex(pattern);
  return re.test(url.href) || re.test(url.host + url.pathname + (url.search ? "?" + url.search : ""));
}

function matchOne(matcher, url) {
  if (typeof matcher === "function") return matcher(url);
  if (matcher instanceof RegExp) return matcher.test(url.href);
  if (typeof matcher === "string") return matchGlob(matcher, url);
  return false;
}

function matches(handler, url) {
  const m = handler.match;
  if (Array.isArray(m)) return m.some((sub) => matchOne(sub, url));
  return matchOne(m, url);
}

function resolveHandler(config, urlString) {
  const url = parseUrl(urlString);
  return config.handlers.find((h) => matches(h, url)) ?? null;
}

function browserName(handler) {
  if (!handler) return null;
  const b = handler.browser;
  if (typeof b === "string") return b;
  if (typeof b === "object" && b.name) return b.name;
  if (typeof b === "function") return "<custom>";
  return null;
}

function routesTo(config, urlString) {
  return browserName(resolveHandler(config, urlString));
}

// ---------------------------------------------------------------------------
// Per-variant tests
// ---------------------------------------------------------------------------

for (const { name, data } of fixtures) {
  describe(`variant: ${name}`, () => {
    const config = buildConfig(data);

    describe("default browser", () => {
      it("uses fixture-specified browser name", () => {
        assert.equal(config.defaultBrowser.name, data.default_browser_name);
      });
      it("includes profile only when fixture sets one", () => {
        assert.equal(config.defaultBrowser.profile ?? null, data.default_browser_profile);
      });
    });

    describe("GitHub", () => {
      if (data.github_browser) {
        it("routes to fixture-specified browser/profile", () => {
          const h = resolveHandler(config, "https://github.com/moov-io/repo");
          assert.ok(h, "expected a handler match");
          assert.equal(h.browser.name, data.github_browser.name);
          assert.equal(h.browser.profile, data.github_browser.profile);
        });
      } else {
        it("falls through to default browser", () => {
          assert.equal(routesTo(config, "https://github.com/moov-io/repo"), null);
        });
      }
    });

    describe("Spacelift (moov)", () => {
      if (data.spacelift_browser) {
        it("routes to fixture-specified browser/profile", () => {
          const h = resolveHandler(config, "https://moovfinancial.app.spacelift.io/");
          assert.ok(h, "expected a handler match");
          assert.equal(h.browser.profile, data.spacelift_browser.profile);
        });
      } else {
        it("falls through to default browser", () => {
          assert.equal(routesTo(config, "https://moovfinancial.app.spacelift.io/"), null);
        });
      }
    });

    // -- Variant-agnostic assertions, exercised against every variant -------

    describe("Linear", () => {
      const workspaceUrls = [
        "https://linear.app/moov/issue/INFRA-4513/add-per-app-team-vault-policies",
        "https://linear.app/moov/team/INFRA/all",
        "https://linear.app/moov/projects/all",
        "https://linear.app/moov/inbox",
      ];
      for (const url of workspaceUrls) {
        it(`opens ${url.replace("https://linear.app", "")} in Linear app`, () => {
          assert.equal(routesTo(config, url), "Linear");
        });
      }

      const browserUrls = [
        "https://linear.app/changelog/2026-02-13-advanced-filters",
        "https://linear.app/docs/some-doc",
        "https://linear.app/help",
        "https://linear.app/integrations/github",
        "https://linear.app/",
      ];
      for (const url of browserUrls) {
        it(`opens ${url.replace("https://linear.app", "") || "/"} in default browser`, () => {
          assert.notEqual(routesTo(config, url), "Linear");
        });
      }

      it("noRedirect=1 forces default browser even for workspace URLs", () => {
        assert.notEqual(
          routesTo(config, "https://linear.app/moov/issue/INFRA-100?noRedirect=1"),
          "Linear",
        );
      });
    });

    describe("Google Meet", () => {
      it("routes meet links to OpenMeetInChrome app", () => {
        const b = routesTo(config, "https://meet.google.com/abc-defg-hij");
        assert.ok(b && b.includes("OpenMeetInChrome"), `expected OpenMeetInChrome, got ${b}`);
      });

      it("does not match bare meet.google.com", () => {
        const b = routesTo(config, "https://meet.google.com/");
        assert.ok(!b || !b.includes("OpenMeetInChrome"));
      });
    });

    describe("Zoom", () => {
      it("routes zoom join links", () => {
        assert.equal(routesTo(config, "https://zoom.us/join"), "us.zoom.xos");
      });
    });

    describe("Discord", () => {
      it("routes discord links", () => {
        assert.equal(routesTo(config, "https://discord.com/channels/123"), "Discord");
      });
    });

    describe("Notion", () => {
      it("routes notion links", () => {
        assert.equal(routesTo(config, "https://www.notion.so/some-page"), "Notion");
      });
    });

    describe("Apple Music", () => {
      it("routes music.apple.com links", () => {
        assert.equal(routesTo(config, "https://music.apple.com/album/123"), "Music");
      });
    });

    describe("Phishing blocker", () => {
      it("catches donotreply.biz links", () => {
        const handler = resolveHandler(config, "https://evil.donotreply.biz/click");
        assert.ok(handler, "should match phishing handler");
      });
    });

    describe("Default fallthrough", () => {
      it("unmatched URLs fall through to default", () => {
        assert.equal(routesTo(config, "https://example.com/something"), null);
      });
    });
  });
}
