import { release } from "node:process";

export {};

chrome.action.onClicked.addListener((tab) => {
  const url = tab.url;
  fetch("http://localhost:4000/api/items", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Origin: "http://localhost:4000",
    },
    body: JSON.stringify({
      item: {
        source_url: url,
        item_type: "webpage",
        text_content: "",
      },
    }),
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  console.log(info, tab);
});

chrome.runtime.onInstalled.addListener(function () {
  let title = "Stack it";
  chrome.contextMenus.create({
    title: title,
    contexts: ["page", "selection", "link", "image", "video", "audio"],
    id: "pouet",
  });
});
