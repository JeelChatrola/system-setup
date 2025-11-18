// Zen Browser / Firefox User Configuration
// This file is copied to your Zen profile directory as user.js
// Preferences here override defaults and are applied on every browser start

// === PRIVACY & SECURITY ===

// Disable telemetry
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);

// Disable Pocket
user_pref("extensions.pocket.enabled", false);

// Enhanced Tracking Protection
user_pref("browser.contentblocking.category", "strict");

// HTTPS-Only Mode
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_ever_enabled", true);

// Disable WebRTC (if you don't need video calls)
// user_pref("media.peerconnection.enabled", false);

// === PERFORMANCE ===

// Hardware acceleration
user_pref("gfx.webrender.all", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.enabled", true);

// Reduce memory usage
user_pref("browser.cache.memory.capacity", 512000);
user_pref("browser.sessionhistory.max_total_viewers", 4);

// Disable animations (useful for tiling WMs)
// user_pref("ui.prefersReducedMotion", 1);

// === UI & BEHAVIOR ===

// Smooth scrolling
user_pref("general.smoothScroll", true);
user_pref("general.smoothScroll.msdPhysics.enabled", true);

// Compact mode (better for tiling window managers)
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1); // 0=normal, 1=compact, 2=touch

// Open bookmarks in new tab
user_pref("browser.tabs.loadBookmarksInTabs", true);

// Don't warn when closing multiple tabs
user_pref("browser.tabs.warnOnClose", false);

// Middle-click paste (Linux)
user_pref("middlemouse.paste", true);

// === SEARCH ===

// Show search suggestions
user_pref("browser.search.suggest.enabled", true);
user_pref("browser.urlbar.suggest.searches", true);

// === DOWNLOADS ===

// Always ask where to save files
user_pref("browser.download.useDownloadDir", false);

// === NEW TAB PAGE ===

// Customize what appears on new tab
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

// === WINDOW MANAGER SPECIFIC ===

// Disable window animations (better for tiling WMs)
// user_pref("toolkit.cosmeticAnimations.enabled", false);

// Use system window decorations (better for WM control)
// user_pref("browser.tabs.drawInTitlebar", false);

// Disable fullscreen warnings (annoying in tiling WMs)
user_pref("full-screen-api.warning.timeout", 0);

// === ZEN-SPECIFIC FEATURES ===

// Enable Zen's split view
user_pref("zen.view.split-view.enabled", true);

// Zen's sidebar
user_pref("zen.sidebar.enabled", true);

// Vertical tabs (Zen's signature feature)
user_pref("zen.tabs.vertical.enabled", true);

// === CUSTOM ADDITIONS ===

// Add your own preferences below this line

// === NOTES ===
// - Edit this file: nano ~/.config/zen-user.js
// - Reapply: ./debian/setup-zen-config.sh
// - Or manually: cp configs/zen-user.js ~/.zen-browser/<profile>/user.js
// - Changes take effect after browser restart
// - To find more prefs, visit: about:config in Zen Browser

