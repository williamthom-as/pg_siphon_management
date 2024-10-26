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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}

Hooks.ScrollToBottom = {
  mounted() {
    this.el.scrollTop = this.el.scrollHeight
  },
  updated() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

Hooks.Accordion = {
  mounted() {
    this.el.querySelectorAll('.accordion-header').forEach(header => {
      header.addEventListener('click', () => {
        const content = header.nextElementSibling;
        const chevron = header.querySelector('.chevron');
        const allContents = this.el.querySelectorAll('.accordion-content');
        const allChevrons = this.el.querySelectorAll('.chevron');
    
        allContents.forEach(item => {
          if (item !== content) {
            item.classList.remove('open');
            item.style.maxHeight = 0;
          }
        });
    
        allChevrons.forEach(item => {
          if (item !== chevron) {
            item.classList.remove('open');
          }
        });
    
        if (content.classList.contains('open')) {
          content.classList.remove('open');
          content.style.maxHeight = 0;
          chevron.classList.remove('open');
        } else {
          content.classList.add('open');
          content.style.maxHeight = content.scrollHeight + 'px';
          chevron.classList.add('open');
        }
      });
    });
  }
}

export default Hooks 

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket