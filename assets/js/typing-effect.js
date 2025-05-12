export function initTypingEffect() {
  const text = document.querySelector('.typing-effect');
  if (!text) return;
  
  const phrases = [
    "Ingénieur Logiciel",
    "Créateur d'outils intelligents",
    "Data Scientist",
  ];
  
  let phraseIndex = 0;
  let charIndex = 0;
  let isDeleting = false;
  
  function type() {
    const currentPhrase = phrases[phraseIndex];
    
    if (isDeleting) {
      text.textContent = currentPhrase.substring(0, charIndex - 1);
      charIndex--;
    } else {
      text.textContent = currentPhrase.substring(0, charIndex + 1);
      charIndex++;
    }
    
    if (!isDeleting && charIndex === currentPhrase.length) {
      setTimeout(() => isDeleting = true, 1500);
    } else if (isDeleting && charIndex === 0) {
      isDeleting = false;
      phraseIndex = (phraseIndex + 1) % phrases.length;
    }
    
    const typingSpeed = isDeleting ? 100 : 150;
    setTimeout(type, typingSpeed);
  }
  
  type();
}
