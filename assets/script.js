(function () {
  const root = document.getElementById('content-root');
  if (root) {
    const children = Array.from(root.childNodes);
    const fragment = document.createDocumentFragment();
    let currentSection = null;

    children.forEach((node) => {
      if (node.nodeType === 1 && node.tagName === 'H2') {
        currentSection = document.createElement('section');
        currentSection.className = 'content-section';
        const id = node.textContent.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
        currentSection.id = id;
        currentSection.appendChild(node);
        fragment.appendChild(currentSection);
      } else if (currentSection) {
        currentSection.appendChild(node);
      } else {
        fragment.appendChild(node);
      }
    });

    root.innerHTML = '';
    root.appendChild(fragment);

    const pubSection = document.getElementById('publications');
    if (pubSection) {
      pubSection.querySelectorAll('ol, ul').forEach((list) => {
        list.classList.add('publication-highlight');
      });
    }
  }

  const input = document.getElementById('pub-search');
  if (input) {
    input.addEventListener('input', function () {
      const query = input.value.trim().toLowerCase();
      const pubSection = document.getElementById('publications');
      if (!pubSection) return;
      const items = pubSection.querySelectorAll('li');
      items.forEach((item) => {
        const text = item.textContent.toLowerCase();
        item.classList.toggle('hidden-by-filter', !!query && !text.includes(query));
      });
    });
  }

  const menuBtn = document.getElementById('menu-btn');
  const nav = document.getElementById('site-nav');
  if (menuBtn && nav) {
    menuBtn.addEventListener('click', function () {
      nav.classList.toggle('open');
    });
    nav.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', function () {
        nav.classList.remove('open');
      });
    });
  }

  const sections = Array.from(document.querySelectorAll('.content-section[id]'));
  const navLinks = Array.from(document.querySelectorAll('.nav a'));
  if (sections.length && navLinks.length) {
    const map = new Map(navLinks.map((link) => [link.getAttribute('href').slice(1), link]));
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          navLinks.forEach((l) => l.classList.remove('active'));
          const active = map.get(entry.target.id);
          if (active) active.classList.add('active');
        }
      });
    }, { rootMargin: '-35% 0px -55% 0px', threshold: 0.01 });

    sections.forEach((section) => observer.observe(section));
  }
})();
