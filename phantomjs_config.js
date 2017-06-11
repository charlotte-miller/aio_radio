// Detect if a web page sniffs the user agent or not.

"use strict";
// var page = require('webpage').create(),
//     system = require('system'),
//     sniffed,
//     address;
//
// page.onInitialized = function () {
//     page.evaluate(function () {
//         (function () {
//           Object.defineProperty(window.navigator, 'platform', {
//             value: 'iPhone', configurable: true
//           });
//
//           console.log(window.navigator.platform)
//         })();
//     });
//
// };

console.log(window.navigator.platform)
Object.defineProperty(window.navigator, 'platform', {
  value: 'iPhone', configurable: true
});
console.log(window.navigator.platform)
phantom.exit();

// if (system.args.length === 1) {
//     console.log('Usage: detectsniff.js <some URL>');
//     phantom.exit(1);
// } else {
//     address = system.args[1];
//     console.log('Checking ' + address + '...');
//     page.open(address, function (status) {
//         if (status !== 'success') {
//             console.log('FAIL to load the address');
//             phantom.exit();
//         } else {
//             window.setTimeout(function () {
//                 sniffed = page.evaluate(function () {
//                     return navigator.sniffed;
//                 });
//                 if (sniffed) {
//                     console.log('The page tried to sniff the user agent.');
//                 } else {
//                     console.log('The page did not try to sniff the user agent.');
//                 }
//                 phantom.exit();
//             }, 1500);
//         }
//     });
// }
