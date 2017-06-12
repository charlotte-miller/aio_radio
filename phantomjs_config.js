"use strict";
var page = require("webpage").create(),
  system = require("system"),
  address;

page.settings.userAgent = "SmartTV";
page.settings.loadImages = false;

page.onInitialized = function () {
  page.evaluate(function () {
    (function () {
      // Fake VideoTag
      var create = document.createElement;
      document.createElement = function (tag) {
        var elem = create.call(document, tag);
        if (tag === "video") {
          elem = create.call(document, "embed");
          elem.className = "video";
          elem.canPlayType = function () { return "probably"; };
        }
        return elem;
      };
    })();
  });
};

if (system.args.length === 1) {
  console.log("Missing <some URL>");
  phantom.exit(1);
} else {
  address = system.args[1];
  // console.log("Checking " + address + "...");
  page.open(address, function (status) {
    if (status !== "success") {
      console.log("FAIL to load the address");
      phantom.exit();
    } else {
      window.setTimeout(function () {
        page.render("click.png");
        var media_link = page.evaluate(function () {
          return (function () {
            return document.getElementById("mediaplayer").getElementsByClassName("video")[0].src;
          })();
        });
        console.log(media_link || "NO Media");
        phantom.exit();
      }, 2000);
    }
  });
}
