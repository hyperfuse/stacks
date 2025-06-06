import { release } from "node:process";

export {};

chrome.action.onClicked.addListener((tab) => {
  const url = tab.url;
  fetch("http://localhost:4000/api/articles", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Origin: "http://localhost:4000",
    },
    body: JSON.stringify({
      article: {
        source_url: url,
      },
    }),
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  const url = info.linkUrl || tab.url;
  fetch("http://localhost:4000/api/articles", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Origin: "http://localhost:4000",
    },
    body: JSON.stringify({
      article: {
        source_url: url,
      },
    }),
  });
});

chrome.runtime.onInstalled.addListener(function () {
  let title = "Stack it";
  chrome.contextMenus.create({
    title: title,
    contexts: ["page", "selection", "link", "image", "video", "audio"],
    id: "pouet",
  });
});
