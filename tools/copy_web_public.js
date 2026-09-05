/**
 * Copies the hand-written static pages in web_public/ into build/web/ so they
 * ship alongside the Flutter admin web build.
 *
 * `flutter build web` wipes build/web on every run, deleting these pages. This
 * script restores them and is wired as a Firebase Hosting `predeploy` hook in
 * firebase.json, so `firebase deploy --only hosting` always publishes them.
 *
 * Static pages served: privacy.html, delete-account.html, lecture.html
 * (deep-link landing) and .well-known/assetlinks.json (Android App Links).
 */
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const src = path.join(root, "web_public");
const dest = path.join(root, "build", "web");

function copyDir(from, to) {
  fs.mkdirSync(to, { recursive: true });
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    const s = path.join(from, entry.name);
    const d = path.join(to, entry.name);
    if (entry.isDirectory()) {
      copyDir(s, d);
    } else {
      fs.copyFileSync(s, d);
      console.log("  copied", path.relative(root, d));
    }
  }
}

if (!fs.existsSync(src)) {
  console.error("web_public/ not found — nothing to copy.");
  process.exit(1);
}
console.log("Copying static pages from web_public/ into build/web/ ...");
copyDir(src, dest);
console.log("Static pages ready.");
