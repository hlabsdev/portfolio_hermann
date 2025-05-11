const DarkMode = {
  mounted() {
    // Initialiser le mode sombre en fonction des préférences sauvegardées ou système
    const isDark = localStorage.getItem('darkMode') === 'true' 
      || (!localStorage.getItem('darkMode') && window.matchMedia('(prefers-color-scheme: dark)').matches);

    // Appliquer le mode initial
    if (isDark) {
      document.documentElement.classList.add('dark');
    }

    // Ajouter le gestionnaire de clic
    this.el.addEventListener('click', () => {
      const isDarkMode = document.documentElement.classList.toggle('dark');
      localStorage.setItem('darkMode', isDarkMode);
    });

    // Écouter les changements de préférence système
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    const handleChange = (e) => {
      if (!localStorage.getItem('darkMode')) {
        if (e.matches) {
          document.documentElement.classList.add('dark');
        } else {
          document.documentElement.classList.remove('dark');
        }
      }
    });
  }
};

export default DarkMode;
