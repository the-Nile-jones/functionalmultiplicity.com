/* ── Pagefind Search Overlay ───────────────────────── */
(function () {
  'use strict';

  // Inject overlay HTML
  var overlay = document.createElement('div');
  overlay.id = 'search-overlay';
  overlay.className = 'search-overlay';
  overlay.setAttribute('hidden', '');
  overlay.setAttribute('data-pagefind-ignore', 'all');
  overlay.innerHTML =
    '<div class="search-overlay-backdrop"></div>' +
    '<div class="search-container" role="dialog" aria-label="Site search" aria-modal="true">' +
      '<button class="search-close" id="search-close" aria-label="Close search">&times;</button>' +
      '<div id="search"></div>' +
    '</div>';
  document.body.appendChild(overlay);

  var openBtn = document.getElementById('search-toggle');
  var closeBtn = document.getElementById('search-close');
  var searchInit = false;

  function openSearch() {
    if (!searchInit && typeof PagefindUI !== 'undefined') {
      new PagefindUI({
        element: '#search',
        showSubResults: true,
        showImages: false,
        resetStyles: false
      });
      searchInit = true;
    }
    overlay.removeAttribute('hidden');
    document.body.style.overflow = 'hidden';
    // Focus the input after Pagefind renders
    requestAnimationFrame(function () {
      var input = overlay.querySelector('.pagefind-ui__search-input');
      if (input) input.focus();
    });
  }

  function closeSearch() {
    overlay.setAttribute('hidden', '');
    document.body.style.overflow = '';
    if (openBtn) openBtn.focus();
  }

  if (openBtn) openBtn.addEventListener('click', openSearch);
  if (closeBtn) closeBtn.addEventListener('click', closeSearch);
  overlay.querySelector('.search-overlay-backdrop').addEventListener('click', closeSearch);

  document.addEventListener('keydown', function (e) {
    // "/" to open (only when not already typing)
    if (e.key === '/' && overlay.hasAttribute('hidden') &&
        document.activeElement.tagName !== 'INPUT' &&
        document.activeElement.tagName !== 'TEXTAREA' &&
        !document.activeElement.isContentEditable) {
      e.preventDefault();
      openSearch();
    }
    // Escape to close
    if (e.key === 'Escape' && !overlay.hasAttribute('hidden')) {
      e.preventDefault();
      closeSearch();
    }
  });
})();
