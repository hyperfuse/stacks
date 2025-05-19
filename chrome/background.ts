export {}

chrome.action.onClicked.addListener((tab) => {
  const url = tab.url
  const title = tab.title

  fetch("http://localhost:4000/api/items", {
    method: "POST",
    body: JSON.stringify({ url: url, title: title })
  })
})

chrome.contextMenus.onClicked.addListener((info, tab) => {
  console.log(info, tab)
})

chrome.runtime.onInstalled.addListener(function () {
  let title = "Stack it"
  chrome.contextMenus.create({
    title: title,
    contexts: ["page", "selection", "link", "image", "video", "audio"],
    id: "pouet"
  })
})
