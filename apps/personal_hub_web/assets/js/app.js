// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/personal_hub_web"
import topbar from "../vendor/topbar"
import Chart from "../vendor/chart.js"

const ChartJS = {
  mounted() {
    this.chart = null
    this.handleEvent("render-chart", ({type, data}) => {
      if (this.chart) this.chart.destroy()
      const ctx = this.el.getContext("2d")
      this.chart = new Chart(ctx, {
        type: type,
        data: data,
        options: {
          responsive: true,
          maintainAspectRatio: true,
          plugins: {
            legend: { position: "bottom", labels: { padding: 16, usePointStyle: true } }
          }
        }
      })
    })
    this.handleEvent("destroy-chart", () => {
      if (this.chart) { this.chart.destroy(); this.chart = null }
    })
  },
  destroyed() {
    if (this.chart) this.chart.destroy()
  }
}

const LocalStore = {
  mounted() {
    const keys = (this.el.dataset.collections || "").split(",").filter(Boolean)
    const data = {}
    keys.forEach(key => {
      const raw = localStorage.getItem(`hub:${key}`)
      data[key] = raw ? JSON.parse(raw) : []
    })
    this.pushEvent("ls:loaded", data)

    this.handleEvent("ls:store", ({ key, data }) => {
      localStorage.setItem(`hub:${key}`, JSON.stringify(data))
    })
  }
}

const BlogEditor = {
  mounted() {
    this.textarea = this.el.querySelector("#blog-textarea")
    if (!this.textarea) return

    // Handle toolbar insertion events from the server
    this.handleEvent("blog:insert", (payload) => {
      const ta = this.textarea
      const start = ta.selectionStart
      const end = ta.selectionEnd
      const text = ta.value
      const selected = text.substring(start, end)

      let newText, cursorPos

      switch (payload.type) {
        case "wrap":
          newText = text.substring(0, start) + payload.before + (selected || "text") + payload.after + text.substring(end)
          cursorPos = selected ? start + payload.before.length + selected.length + payload.after.length : start + payload.before.length + 4 + payload.after.length
          break

        case "prefix":
          // Insert at the beginning of the current line
          const lineStart = text.lastIndexOf("\n", start - 1) + 1
          newText = text.substring(0, lineStart) + payload.prefix + text.substring(lineStart)
          cursorPos = start + payload.prefix.length
          break

        case "block":
          const blockText = selected || "code here"
          newText = text.substring(0, start) + "\n" + payload.syntax + blockText + "\n```\n" + text.substring(end)
          cursorPos = start + 1 + payload.syntax.length + blockText.length
          break

        case "insert":
          newText = text.substring(0, start) + payload.text + text.substring(end)
          cursorPos = start + payload.text.length
          break

        default:
          return
      }

      ta.value = newText
      ta.selectionStart = ta.selectionEnd = cursorPos
      ta.focus()

      // Trigger LiveView change event
      ta.dispatchEvent(new Event("input", { bubbles: true }))
      this.pushEventTo(this.el, "preview_update", { body: ta.value })
    })

    // Tab key → insert 2 spaces instead of focus change
    this.textarea.addEventListener("keydown", (e) => {
      if (e.key === "Tab") {
        e.preventDefault()
        const ta = e.target
        const start = ta.selectionStart
        ta.value = ta.value.substring(0, start) + "  " + ta.value.substring(ta.selectionEnd)
        ta.selectionStart = ta.selectionEnd = start + 2
      }

      // Enter key: auto-continue lists
      if (e.key === "Enter") {
        const ta = e.target
        const pos = ta.selectionStart
        const beforeCursor = ta.value.substring(0, pos)
        const currentLine = beforeCursor.split("\n").pop()

        // Check for list patterns
        const ulMatch = currentLine.match(/^(\s*[-*+]\s)/)
        const olMatch = currentLine.match(/^(\s*\d+\.\s)/)

        if (ulMatch && currentLine.trim() === ulMatch[0].trim()) {
          // Empty list item → remove it
          e.preventDefault()
          const lineStart = beforeCursor.lastIndexOf("\n") + 1
          ta.value = ta.value.substring(0, lineStart) + "\n" + ta.value.substring(pos)
          ta.selectionStart = ta.selectionEnd = lineStart + 1
        } else if (ulMatch) {
          e.preventDefault()
          const prefix = ulMatch[1]
          ta.value = ta.value.substring(0, pos) + "\n" + prefix + ta.value.substring(pos)
          ta.selectionStart = ta.selectionEnd = pos + 1 + prefix.length
        } else if (olMatch && currentLine.trim() === olMatch[0].trim()) {
          e.preventDefault()
          const lineStart = beforeCursor.lastIndexOf("\n") + 1
          ta.value = ta.value.substring(0, lineStart) + "\n" + ta.value.substring(pos)
          ta.selectionStart = ta.selectionEnd = lineStart + 1
        } else if (olMatch) {
          e.preventDefault()
          const num = parseInt(currentLine.match(/\d+/)[0]) + 1
          const indent = currentLine.match(/^(\s*)/)[1]
          const prefix = `${indent}${num}. `
          ta.value = ta.value.substring(0, pos) + "\n" + prefix + ta.value.substring(pos)
          ta.selectionStart = ta.selectionEnd = pos + 1 + prefix.length
        }
      }
    })

    // Send preview updates on input
    this.textarea.addEventListener("input", () => {
      this.pushEventTo(this.el, "preview_update", { body: this.textarea.value })
    })
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ChartJS, LocalStore, BlogEditor},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Close nav <details> menus on LiveView navigation (hover/focus CSS alone stayed "open" after patch)
const closeAppHeaderDetails = () => {
  document.querySelectorAll("#app-header details[open]").forEach((d) => d.removeAttribute("open"))
}
window.addEventListener("phx:page-loading-start", closeAppHeaderDetails)
window.addEventListener("phx:page-loading-stop", closeAppHeaderDetails)

// Only one app-header menu open at a time
document.addEventListener(
  "toggle",
  (e) => {
    const t = e.target
    if (t.nodeName !== "DETAILS" || !t.open) return
    const header = t.closest("#app-header")
    if (!header) return
    header.querySelectorAll("details[open]").forEach((d) => {
      if (d !== t) d.removeAttribute("open")
    })
  },
  true
)

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

