// Theme toggling logic
export function initTheme() {
  const themeToggleBtn = document.getElementById("theme-toggle-btn");
  const themeIcon = document.getElementById("theme-toggle-icon");
  const themeText = document.getElementById("theme-toggle-text");

  const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
  const storedTheme = localStorage.getItem("matchwork_theme");

  // Default to light mode as requested, unless previously set
  const initialTheme = storedTheme || "light";

  function applyTheme(theme) {
    if (theme === "dark") {
      document.documentElement.classList.add("dark");
      if (themeIcon) themeIcon.textContent = "light_mode";
      if (themeText) themeText.textContent = "Modo Claro";
    } else {
      document.documentElement.classList.remove("dark");
      if (themeIcon) themeIcon.textContent = "dark_mode";
      if (themeText) themeText.textContent = "Modo Oscuro";
    }
  }

  applyTheme(initialTheme);

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener("click", (e) => {
      e.preventDefault();
      const currentTheme = document.documentElement.classList.contains("dark")
        ? "dark"
        : "light";
      const newTheme = currentTheme === "dark" ? "light" : "dark";
      localStorage.setItem("matchwork_theme", newTheme);
      applyTheme(newTheme);
    });
  }
}

// Auto-initialize when loaded
document.addEventListener("DOMContentLoaded", initTheme);
