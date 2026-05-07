(function () {
  const body = document.body;
  const header = document.querySelector('[data-header]');
  const navToggle = document.querySelector('.nav-toggle');
  const nav = document.getElementById('site-nav');

  function updateHeader() {
    if (!header) return;
    header.classList.toggle('is-scrolled', window.scrollY > 8);
  }

  updateHeader();
  window.addEventListener('scroll', updateHeader, { passive: true });

  if (navToggle && nav) {
    navToggle.addEventListener('click', () => {
      const isOpen = navToggle.getAttribute('aria-expanded') === 'true';
      navToggle.setAttribute('aria-expanded', String(!isOpen));
      body.classList.toggle('nav-open', !isOpen);
    });

    nav.addEventListener('click', (event) => {
      if (event.target.closest('a')) {
        navToggle.setAttribute('aria-expanded', 'false');
        body.classList.remove('nav-open');
      }
    });
  }

  const yearTarget = document.querySelector('[data-current-year]');
  if (yearTarget) {
    yearTarget.textContent = new Date().getFullYear();
  }

  const copyButton = document.querySelector('[data-copy-email]');
  if (copyButton) {
    copyButton.addEventListener('click', async () => {
      const email = copyButton.getAttribute('data-copy-email');
      try {
        await navigator.clipboard.writeText(email);
        const original = copyButton.textContent;
        copyButton.textContent = 'Copied';
        setTimeout(() => {
          copyButton.textContent = original;
        }, 1600);
      } catch (error) {
        window.location.href = `mailto:${email}`;
      }
    });
  }

  function setupPublicationSearch() {
    const publicationsHeading = document.getElementById('publications');
    if (!publicationsHeading) return;

    const groups = [];
    let node = publicationsHeading.nextElementSibling;
    let currentHeading = null;

    while (node && node.tagName !== 'H2') {
      if (node.tagName === 'H3') {
        currentHeading = node;
        currentHeading.classList.add('publication-subheading');
      }

      if (node.tagName === 'OL') {
        node.classList.add('publication-list');
        const items = Array.from(node.children).filter((child) => child.tagName === 'LI');
        items.forEach((item) => item.classList.add('publication-card'));
        groups.push({ heading: currentHeading, list: node, items });
      }

      node = node.nextElementSibling;
    }

    const publicationItems = groups.flatMap((group) => group.items);
    if (!publicationItems.length) return;

    const tools = document.createElement('div');
    tools.className = 'publication-tools';
    tools.innerHTML = `
      <label for="publication-search">Search publications</label>
      <input id="publication-search" type="search" placeholder="Search by title, author, venue, or year" autocomplete="off">
      <span class="publication-count" aria-live="polite"></span>
    `;

    const noResults = document.createElement('p');
    noResults.className = 'no-publication-results';
    noResults.hidden = true;
    noResults.textContent = 'No publications match this search.';

    const firstPublicationHeading = groups.find((group) => group.heading)?.heading || groups[0].list;
    firstPublicationHeading.parentNode.insertBefore(tools, firstPublicationHeading);
    groups[groups.length - 1].list.insertAdjacentElement('afterend', noResults);

    const searchInput = tools.querySelector('input');
    const count = tools.querySelector('.publication-count');

    function normalize(value) {
      return value.toLowerCase().replace(/\s+/g, ' ').trim();
    }

    function updateResults() {
      const query = normalize(searchInput.value);
      let visibleCount = 0;

      groups.forEach((group) => {
        let groupVisibleCount = 0;
        group.items.forEach((item) => {
          const visible = !query || normalize(item.textContent).includes(query);
          item.hidden = !visible;
          if (visible) {
            visibleCount += 1;
            groupVisibleCount += 1;
          }
        });
        group.list.hidden = groupVisibleCount === 0;
        if (group.heading) {
          group.heading.hidden = groupVisibleCount === 0;
        }
      });

      count.textContent = `${visibleCount} publication${visibleCount === 1 ? '' : 's'}`;
      noResults.hidden = visibleCount !== 0;
    }

    searchInput.addEventListener('input', updateResults);
    updateResults();
  }

  setupPublicationSearch();

  const revealCandidates = [
    ...document.querySelectorAll('.reveal'),
    ...document.querySelectorAll('.markdown-content > h2, .markdown-content > h3, .markdown-content > p, .markdown-content > ul, .markdown-content > ol, .publication-tools')
  ];

  const uniqueRevealTargets = Array.from(new Set(revealCandidates));

  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12 });

    uniqueRevealTargets.forEach((element) => {
      element.classList.add('reveal');
      observer.observe(element);
    });
  } else {
    uniqueRevealTargets.forEach((element) => element.classList.add('is-visible'));
  }
}());
