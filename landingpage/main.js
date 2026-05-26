document.addEventListener('DOMContentLoaded', () => {

  // 1. Header scroll effect
  const header = document.getElementById('main-header');
  window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
      header.classList.add('scrolled');
    } else {
      header.classList.remove('scrolled');
    }
  });

  // 2. Mobile Menu toggle
  const menuToggle = document.getElementById('mobile-menu-toggle');
  const navMenu = document.getElementById('nav-menu');
  menuToggle.addEventListener('click', () => {
    navMenu.classList.toggle('active');
    const icon = menuToggle.querySelector('.material-symbols-outlined');
    if (navMenu.classList.contains('active')) {
      icon.textContent = 'close';
    } else {
      icon.textContent = 'menu';
    }
  });

  // Close mobile menu when a link is clicked
  const navLinks = navMenu.querySelectorAll('a');
  navLinks.forEach(link => {
    link.addEventListener('click', () => {
      navMenu.classList.remove('active');
      const icon = menuToggle.querySelector('.material-symbols-outlined');
      if (icon) icon.textContent = 'menu';
    });
  });

  // 3. Tab switching (How It Works)
  const tabClient = document.getElementById('tab-client-btn');
  const tabProvider = document.getElementById('tab-provider-btn');
  const panelClient = document.getElementById('panel-client');
  const panelProvider = document.getElementById('panel-provider');

  tabClient.addEventListener('click', () => {
    tabClient.classList.add('active');
    tabProvider.classList.remove('active');
    panelClient.classList.add('active');
    panelProvider.classList.remove('active');
  });

  tabProvider.addEventListener('click', () => {
    tabProvider.classList.add('active');
    tabClient.classList.remove('active');
    panelProvider.classList.add('active');
    panelClient.classList.remove('active');
  });

  // 4. Hero mock app interactive pins
  const mockPins = document.querySelectorAll('.mock-pin');
  const heroPopup = document.getElementById('hero-provider-popup');
  const popupAvatar = document.getElementById('hero-popup-avatar');
  const popupName = document.getElementById('hero-popup-name');
  const popupProfession = document.getElementById('hero-popup-profession');
  const popupRating = document.getElementById('hero-popup-rating');

  const mockProviderData = {
    '1': {
      name: 'Carlos Mendoza',
      profession: 'Maestro Gasfitero Autorizado',
      rating: '4.9',
      avatar: 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?auto=format&fit=crop&w=150&q=80'
    },
    '2': {
      name: 'Francisco Javier',
      profession: 'Electricista Certificado SEC',
      rating: '4.8',
      avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCkkUwOuvyN2Qm4vmOiICtijtED3CJu4s_rWpmOyynM4l801tEL6X3P_Jnr2IcpevBIYD4BSbXAPRUX2AMCBP8C5k_9XtGS38PGXsVoaf30OkmuoOH1-NpV9avYaTU5tjbgLhRGTa8Y5KeSeBg1dMPTM9SnJLZSiAOb3S3am7yhuZGkkS1GljZv7wprS8rV-uwaf6C96yBq8oywa5GT9o_AHsvRQnNRgE1GlSjXCa1b0-qJOwT0wK_lP8Z1AL7t0M3nAKYbJgL9kn0'
    },
    '3': {
      name: 'Ana Silva',
      profession: 'Especialista en Limpieza Profunda',
      rating: '5.0',
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80'
    }
  };

  // Show first provider popup initially in Hero
  setTimeout(() => {
    showHeroPopup('1');
  }, 1000);

  mockPins.forEach(pin => {
    pin.addEventListener('click', () => {
      const id = pin.getAttribute('data-provider-id');
      showHeroPopup(id);
    });
  });

  function showHeroPopup(id) {
    const data = mockProviderData[id];
    if (data) {
      popupAvatar.src = data.avatar;
      popupName.textContent = data.name;
      popupProfession.textContent = data.profession;
      popupRating.textContent = data.rating;
      heroPopup.classList.add('active');
    }
  }

  // 5. Dynamic Interactive Category Showcase Simulator
  const demoItems = document.querySelectorAll('.demo-select-item');
  const simPin = document.getElementById('sim-pin');
  const simPinIcon = document.getElementById('sim-pin-icon');
  const simLoader = document.getElementById('sim-loader');
  const simCard = document.getElementById('sim-card');
  const simCardAvatar = document.getElementById('sim-card-avatar');
  const simCardName = document.getElementById('sim-card-name');
  const simCardProfession = document.getElementById('sim-card-profession');
  const simCardRating = document.getElementById('sim-card-rating-num');

  const categoryIcons = {
    'gasfiteria': 'plumbing',
    'electricidad': 'bolt',
    'limpieza': 'cleaning_services'
  };

  demoItems.forEach(item => {
    item.addEventListener('click', () => {
      if (item.classList.contains('active')) return;

      // Reset active state for buttons
      demoItems.forEach(i => i.classList.remove('active'));
      item.classList.add('active');

      // 1. Hide current details
      simCard.classList.remove('active');
      simPin.classList.remove('active');

      // 2. Show map search loader
      simLoader.classList.add('active');

      // 3. Simulates geolocalization delay
      setTimeout(() => {
        simLoader.classList.remove('active');

        // Extract metadata from item
        const category = item.getAttribute('data-category');
        const name = item.getAttribute('data-name');
        const avatar = item.getAttribute('data-avatar');
        const profession = item.getAttribute('data-profession');
        const rating = item.getAttribute('data-rating');
        const topVal = item.getAttribute('data-lat');
        const leftVal = item.getAttribute('data-lng');

        // Update pin position and icon
        simPin.style.top = topVal;
        simPin.style.left = leftVal;
        simPinIcon.textContent = categoryIcons[category] || 'plumbing';

        // Update card info
        simCardAvatar.src = avatar;
        simCardName.textContent = name;
        simCardProfession.textContent = profession;
        simCardRating.textContent = rating;

        // Animate elements back in
        simPin.classList.add('active');
        
        setTimeout(() => {
          simCard.classList.add('active');
        }, 300);

      }, 1200);

    });
  });

  // 6. Modal waitlist / newsletter control
  const waitlistModal = document.getElementById('waitlist-modal');
  const openButtons = document.querySelectorAll('.open-waitlist-btn');
  const closeButton = document.getElementById('modal-close-btn');
  const waitlistForm = document.getElementById('waitlist-form');
  const waitlistSuccess = document.getElementById('waitlist-success');

  openButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      waitlistModal.classList.add('active');
      // Reset form view
      waitlistForm.style.display = 'flex';
      waitlistSuccess.style.display = 'none';
      document.getElementById('waitlist-email').value = '';
    });
  });

  closeButton.addEventListener('click', () => {
    waitlistModal.classList.remove('active');
  });

  // Close modal when clicking background overlay
  waitlistModal.addEventListener('click', (e) => {
    if (e.target === waitlistModal) {
      waitlistModal.classList.remove('active');
    }
  });

  // Handle Waitlist Form Submit
  waitlistForm.addEventListener('submit', (e) => {
    e.preventDefault();
    
    // Animate loader inside button or just show success
    waitlistForm.style.display = 'none';
    waitlistSuccess.style.display = 'block';
    
    // Automatically close the modal after 2.5 seconds
    setTimeout(() => {
      waitlistModal.classList.remove('active');
    }, 2500);
  });
});
