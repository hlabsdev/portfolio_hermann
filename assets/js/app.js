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

// Import dependencies
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {initTypingEffect} from "./typing-effect"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.DarkMode = {
  mounted() {
    // Initialisation
    const root = document.documentElement;
    const darkModeKey = 'darkMode';
    const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

    // Fonction pour mettre à jour le mode
    const updateTheme = (isDark) => {
      root.classList.toggle('dark', isDark);
      localStorage.setItem(darkModeKey, isDark);
    };

    // Initialiser le mode sombre en fonction des préférences
    const storedDarkMode = localStorage.getItem(darkModeKey);
    if (storedDarkMode === null) {
      // Pas de préférence stockée, utiliser la préférence système
      updateTheme(darkModeMediaQuery.matches);
    } else {
      // Utiliser la préférence stockée
      updateTheme(storedDarkMode === 'true');
    }

    // Ajouter le gestionnaire de clic
    this.el.addEventListener('click', () => {
      const isDark = !root.classList.contains('dark');
      updateTheme(isDark);
    });

    // Écouter les changements de préférence système
    const handleSystemThemeChange = (e) => {
      if (localStorage.getItem(darkModeKey) === null) {
        updateTheme(e.matches);
      }
    };

    darkModeMediaQuery.addEventListener('change', handleSystemThemeChange);
    
    // Nettoyer l'écouteur lors du démontage
    this.destroy = () => {
      darkModeMediaQuery.removeEventListener('change', handleSystemThemeChange);
    };
  },

  destroyed() {
    if (this.destroy) {
      this.destroy();
    }
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    }
  }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#f39d8d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
window.liveSocket = liveSocket

// Initialize typing effect
document.addEventListener("DOMContentLoaded", initTypingEffect)

