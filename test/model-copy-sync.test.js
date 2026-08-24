// display-takeover/Model.js has to be a literal copy of the root Model.js
// (omarchy-plugin-validate refuses symlinks inside a plugin folder, and
// the display-takeover plugin needs its own Model.js regardless of where
// the parent plugin is installed -- see display-takeover/README.md). This
// just catches the two silently drifting apart, since nothing else would.
//
// Run with: node test/model-copy-sync.test.js
"use strict";
const fs = require("fs");
const path = require("path");

const root = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8");
const copy = fs.readFileSync(path.join(__dirname, "..", "display-takeover", "Model.js"), "utf8");

if (root === copy) {
  console.log("ok:   display-takeover/Model.js matches Model.js");
  process.exit(0);
} else {
  console.log("FAIL: display-takeover/Model.js has drifted from Model.js -- copy Model.js over it again");
  process.exit(1);
}
