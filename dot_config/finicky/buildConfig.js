// Pure factory for the Finicky config. All variant-specific values come in
// through `extras` so this file stays static and testable.

// Slack workspace subdomain → team ID, used to rewrite web links into
// slack:// deep links so they open in the desktop app. Subdomains not listed
// here fall through to the browser. Find a team ID in any existing
// slack://...?team=T... deep link, or in the Slack desktop app's local
// storage (`grep -ro 'T[0-9A-Z]\{8,\}' ~/Library/Application\ Support/Slack/storage`).
const SLACK_TEAM_IDS = {
  moovfinancial: "T07A1C5N35M",
  "moov-io": "TAG0V15PC",
};

export function buildConfig(extras) {
  const handlers = [
    {
      match: "*.donotreply.biz*",
      browser: ({ urlString }) => {
        console.warn(`Finicky: blocked phishing-test link ${urlString}`);
        return null;
      },
    },
    {
      match: /zoom\.us\/join/,
      browser: "us.zoom.xos",
    },
    {
      match: ["music.apple.com*", "geo.music.apple.com*"],
      url: { protocol: "itmss" },
      browser: "Music",
    },
    {
      match: "https://discord.com/*",
      url: { protocol: "discord" },
      browser: "Discord",
    },
    {
      match: /meet\.google\.com\/.+/,
      browser: extras.meet_app_path,
    },
    {
      match: (url) => {
        if (url.host !== "linear.app") return false;
        if (url.search.includes("noRedirect=1")) return false;
        const nonWorkspacePaths =
          /^\/(docs|changelog|help|settings|login|signup|api|blog|integrations|customers|pricing|about|readme|method)(\/|$)/;
        return url.pathname !== "/" && !nonWorkspacePaths.test(url.pathname);
      },
      url: { protocol: "linear" },
      browser: "Linear",
    },
    {
      match: "*.notion.so/*",
      url: { protocol: "notion" },
      browser: "Notion",
    },
  ];

  if (extras.github_browser) {
    handlers.push({
      match: ["https://github.com/*", "http://github.com/*"],
      browser: extras.github_browser,
    });
  }

  if (extras.spacelift_browser) {
    handlers.push({
      match: "https://moovfinancial.app.spacelift.io/",
      browser: extras.spacelift_browser,
    });
  }

  handlers.push({
    match: (url) => url.protocol === "slack",
    browser: "/Applications/Slack.app",
  });

  const defaultBrowser = { name: extras.default_browser_name };
  if (extras.default_browser_profile) {
    defaultBrowser.profile = extras.default_browser_profile;
  }

  return {
    defaultBrowser,
    handlers,
    rewrite: [
      {
        match: () => true,
        url: (url) => {
          const removeKeysStartingWith = ["utm_", "uta_"];
          const removeKeys = ["fbclid", "gclid"];

          const search = url.search
            .split("&")
            .map((parameter) => parameter.split("="))
            .filter(([key]) => !removeKeysStartingWith.some((startingWith) => key.startsWith(startingWith)))
            .filter(([key]) => !removeKeys.some((removeKey) => key === removeKey));

          return {
            ...url,
            search: search.map((parameter) => parameter.join("=")).join("&"),
          };
        },
      },
      {
        match: (url) => url.host.includes("zoom.us") && url.pathname.includes("/j/"),
        url(url) {
          try {
            var pass = "&pwd=" + url.search.match(/pwd=(\w*)/)[1];
          } catch {
            var pass = "";
          }
          var conf = "confno=" + url.pathname.match(/\/j\/(\d+)/)[1];
          return {
            search: conf + pass,
            pathname: "/join",
            protocol: "zoommtg",
          };
        },
      },
      {
        // Slack rewrite from https://github.com/johnste/finicky/issues/96#issuecomment-844571182
        match: ["*.slack.com/*"],
        url: function (url) {
          const urlString = url.href;
          const subdomain = url.host.slice(0, -10);
          const pathParts = url.pathname.split("/");

          let team,
            patterns = {};
          if (subdomain != "app") {
            team = SLACK_TEAM_IDS[subdomain];
            if (!team) {
              console.warn(
                `Finicky: no Slack team ID configured for ${url.host}; opening in browser. ` +
                  `Add it to SLACK_TEAM_IDS in buildConfig.js to deep-link into the app.`,
              );
              return url;
            }

            if (subdomain.slice(-11) == ".enterprise") {
              patterns = {
                file: [/\/files\/\w+\/(?<id>\w+)/],
              };
            } else {
              patterns = {
                file: [/\/messages\/\w+\/files\/(?<id>\w+)/],
                team: [/(?:\/messages\/\w+)?\/team\/(?<id>\w+)/],
                channel: [/\/(?:messages|archives)\/(?<id>\w+)(?:\/(?<message>p\d+))?/],
              };
            }
          } else {
            patterns = {
              file: [
                /\/client\/(?<team>\w+)\/\w+\/files\/(?<id>\w+)/,
                /\/docs\/(?<team>\w+)\/(?<id>\w+)/,
              ],
              team: [/\/client\/(?<team>\w+)\/\w+\/user_profile\/(?<id>\w+)/],
              channel: [/\/client\/(?<team>\w+)\/(?<id>\w+)(?:\/(?<message>[\d.]+))?/],
            };
          }

          for (let [host, host_patterns] of Object.entries(patterns)) {
            for (let pattern of host_patterns) {
              let match = pattern.exec(url.pathname);
              if (match) {
                let search = `team=${team || match.groups.team}`;

                if (match.groups.id) {
                  search += `&id=${match.groups.id}`;
                }

                if (match.groups.message) {
                  let message = match.groups.message;
                  if (message.charAt(0) == "p") {
                    message = message.slice(1, 11) + "." + message.slice(11);
                  }
                  search += `&message=${message}`;
                }

                let output = {
                  protocol: "slack",
                  username: "",
                  password: "",
                  host: host,
                  port: null,
                  pathname: "",
                  search: search,
                  hash: "",
                };
                let outputStr = `${output.protocol}://${output.host}?${output.search}`;
                console.log(`Rewrote Slack URL ${urlString} to deep link ${outputStr}`);
                return output;
              }
            }
          }

          return url;
        },
      },
    ],
  };
}
