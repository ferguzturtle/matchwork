// Main JavaScript for MatchWork Landing Page

document.addEventListener('DOMContentLoaded', () => {
  // Smooth scrolling for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      
      const targetId = this.getAttribute('href');
      if(targetId === '#') return;
      
      const targetElement = document.querySelector(targetId);
      if(targetElement) {
        targetElement.scrollIntoView({
          behavior: 'smooth'
        });
      }
    });
  });

  // Optional: Add simple scroll animation for nav background
  const header = document.querySelector('header');
  window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
      header.style.backgroundColor = 'rgba(15, 23, 42, 0.95)';
      header.style.backdropFilter = 'blur(10px)';
      header.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
      header.style.padding = '16px 0';
      header.style.position = 'fixed';
    } else {
      header.style.backgroundColor = 'transparent';
      header.style.backdropFilter = 'none';
      header.style.boxShadow = 'none';
      header.style.padding = '24px 0';
      header.style.position = 'absolute';
    }
  });
});
