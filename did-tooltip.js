/* ── DID Term Tooltip System ─────────────────────── */
(function () {
  /* ── Dictionary ──────────────────────────────────── */
  const DICT = {
    // FM Functional Language
    "FM": {
      label: "Functional Multiplicity (FM)",
      definition: "An optimized state of being for DID systems. FM prioritizes Systemic Cooperation and Executive Excellence over traditional integration—the goal is not to become one, but to function as an efficiently coordinated many.",
      source: "FM Functional Language"
    },
    "Functional Multiplicity": {
      label: "Functional Multiplicity",
      definition: "An optimized state of being for DID systems. FM prioritizes Systemic Cooperation and Executive Excellence over traditional integration—the goal is not to become one, but to function as an efficiently coordinated many.",
      source: "FM Functional Language"
    },


    "Strategic Architecture": {
      label: "Strategic Architecture",
      definition: "The intentional design of how a system operates: which alters hold which roles, how handoffs occur, how decisions are made, and how the system's structure supports its goals.",
      source: "FM Functional Language"
    },
    "Identity-as-Role": {
      label: "Identity-as-Role",
      definition: "Each alter is understood as a functional role within the system rather than a fragmented sub-personality. Roles have defined responsibilities, competencies, and boundaries—like positions in an organization.",
      source: "FM Functional Language"
    },
    "Sovereign Handoff": {
      label: "Sovereign Handoff",
      definition: "A deliberate, consensual transition of fronting responsibilities from one alter to another. Sovereign Handoffs are planned and intentional, as opposed to involuntary switches.",
      source: "FM Functional Language"
    },

    "Sovereignty": {
      label: "Sovereignty",
      definition: "The FM principle that every Identity in a System has the right to exist, to hold a role, and to participate in decisions that affect the collective. Not independence from the System — authority within it.",
      source: "FM Functional Language"
    },
    "Systemic Cooperation": {
      label: "Systemic Cooperation",
      definition: "The coordinated collaboration between alters toward shared goals—a core FM value. Prioritized over internal competition, suppression, or forced integration.",
      source: "FM Functional Language"
    },
    "Executive Excellence": {
      label: "Executive Excellence",
      definition: "The FM goal of optimized executive function across the system—consistent output, reliable memory, clear communication, and effective decision-making regardless of who is fronting.",
      source: "FM Functional Language"
    },

    // Clinical DID Terms
    "DID": {
      label: "Dissociative Identity Disorder (DID)",
      definition: "A trauma-based dissociative condition in which a person develops two or more distinct Identities that recurrently take control of the body. Formerly called Multiple Personality Disorder.",
      source: "Clinical"
    },
    "system": {
      label: "System",
      definition: "The collective of all alters within one body. 'The system' refers to the whole person—all parts together—rather than any single alter.",
      source: "Clinical / Community"
    },
    "alter": {
      label: "Identity",
      definition: "'Alter' is clinical language — short for 'alternate personality,' a medical framing FM moves away from. In FM: an Identity. A distinct person within a System, complete with their own name, age, experiences, memories, and way of engaging with the world. Not a fragment. A person.",
      source: "FM / Community"
    },
    "alters": {
      label: "Identities",
      definition: "'Alters' is clinical language — short for 'alternate personalities,' a medical framing FM moves away from. In FM: Identities. The distinct people within a System, each complete with their own name, age, experiences, and way of engaging with the world. Not fragments. People.",
      source: "FM / Community"
    },
    "fronting": {
      label: "Fronting",
      definition: "Being the alter currently in control of the body—interacting with the external world. An alter who is fronting is 'out.'",
      source: "Clinical / Community"
    },
    "co-fronting": {
      label: "Co-fronting",
      definition: "When two or more alters are simultaneously present at the front, sharing control of the body and awareness of external reality.",
      source: "Clinical / Community"
    },
    "switching": {
      label: "Switching",
      definition: "The process of one alter taking over the front from another. Switches can be voluntary (planned) or involuntary (triggered).",
      source: "Clinical / Community"
    },
    "switch": {
      label: "Switch",
      definition: "A transition in which one alter takes over the front from another. Switches can be voluntary (planned) or involuntary (triggered).",
      source: "Clinical / Community"
    },
    "host": {
      label: "Host",
      definition: "The alter who fronts most frequently in daily life, often managing primary responsibilities. In FM, roles are distributed rather than centralized in a single host.",
      source: "Clinical / Community"
    },
    "protector": {
      label: "Protector",
      definition: "An alter whose role is to defend the system from perceived threats—external or internal. Protectors may present as aggressive, avoidant, or caretaking depending on their strategy.",
      source: "Clinical / Community"
    },
    "amnesia": {
      label: "Dissociative Amnesia",
      definition: "Memory gaps between alters—one alter may have no memory of what another did or experienced. A diagnostic criterion for DID. FM's approach addresses amnesia as a system design problem to be managed.",
      source: "Clinical"
    },
    "dissociation": {
      label: "Dissociation",
      definition: "A disconnection between thoughts, identity, consciousness, and memory. In trauma contexts, dissociation is a protective mechanism. DID is a chronic, complex form of dissociation.",
      source: "Clinical"
    },
    "headspace": {
      label: "Headspace / Inner World",
      definition: "The internal mental space experienced by many DID systems—a perceived environment where alters exist, interact, and hold memory when not fronting.",
      source: "Community"
    },
    "parts": {
      label: "Parts",
      definition: "Another term for alters. 'Parts work' refers to therapeutic approaches that engage with individual alters. FM uses this term interchangeably with alters.",
      source: "Clinical / Community"
    },
    "integration": {
      label: "Integration",
      definition: "The traditional therapeutic goal of merging alters into a single identity. FM explicitly rejects forced integration as the primary goal, pursuing functional coordination instead.",
      source: "Clinical"
    },
    "plurality": {
      label: "Plurality",
      definition: "The state of having multiple distinct Identities in one body. Used by many Systems as a neutral or affirming descriptor.",
      source: "Community"
    },

    "OSDD": {
      label: "OSDD",
      definition: "Other Specified Dissociative Disorder. A dissociative condition that shares features with DID — including distinct identity states and amnesia — but doesn't meet every clinical criterion for a DID diagnosis. Equally real, equally valid.",
      source: "Clinical"
    },
    "cocon": {
      label: "Cocon (Co-conscious)",
      definition: "Short for co-conscious. A System member who is aware and present alongside the fronting member without fully fronting — able to observe, support, or communicate internally.",
      source: "Community"
    },
    "Psychosis": {
      label: "Psychosis",
      definition: "A state in which a person loses contact with shared reality — experiencing delusions, hallucinations, or severe disorganization of thought. In a DID context, psychosis can interact with switching and identity confusion in ways standard clinical descriptions don't fully account for.",
      source: "Clinical"
    },
    "Amnesia Tax": {
      label: "Amnesia Tax",
      definition: "The cognitive, temporal, and metabolic cost incurred by memory gaps and the energy required to bridge them during identity switches. One of the core problems Functional Multiplicity is built to address.",
      source: "FM"
    },
    "Exocortex": {
      label: "Exocortex (EC)",
      definition: "An external memory and reasoning system — typically an AI — that extends what a System can do together, catches what falls through the gaps, and holds continuity when internal communication breaks down.",
      source: "FM"
    },
    "The Veil": {
      label: "The Veil",
      definition: "The internal barrier that keeps System members unaware of each other and of the System's own plurality. Not a wall — more like a one-way mirror. Lifting the veil means becoming aware. Reforming means the amnesia returning.",
      source: "FM"
    },
    "EMDR": {
      label: "EMDR",
      definition: "Eye Movement Desensitization and Reprocessing. A trauma therapy technique using bilateral stimulation — eye movements, tapping, or audio tones — to help the brain reprocess distressing memories. Requires a distortion in reality to work.",
      source: "Clinical"
    },
    "Backstuck": {
      label: "Backstuck",
      definition: "A DID term for a state in which a member is stuck at the back of the system and unable to front.",
      source: "Community"
    },
    "Introjection": {
      label: "Introjection",
      definition: "The process by which a System unconsciously absorbs a person, character, or entity from outside and forms an internal member based on them. The resulting member is called an introject.",
      source: "Clinical / Community"
    },
    "plural": {
      label: "Plural",
      definition: "Having multiple distinct Identities in one body. Many Systems use 'plural' as an affirming self-descriptor.",
      source: "Community"
    },
    "Proprioception": {
      label: "Proprioception",
      definition: "The body's internal sense of its own position, movement, and spatial orientation — felt without looking. In FM: turning inward to sense who is present, where tension lives, and what the body is telling You right now. Not dissociation — the opposite. Grounding through awareness of the body You all share.",
      source: "FM / Clinical"
    },
    "lexicon": {
      label: "Lexicon",
      definition: "The vocabulary a particular person, community, or System uses for their lived experience. In FM, every System builds its own lexicon — terms They've found that fit Their internal reality. The site's terms are a starting point; Yours, named from the inside, take precedence.",
      source: "Community"
    },
    "Member": {
      label: "Member",
      definition: "An individual person within a System — with Their own name, characteristics, skills, and sense of self. 'Member' is the Plural Association's preferred community term; You may also hear Headmate, Part, Alter, or Identity depending on the System's language. Each Member is a full person, not a fragment.",
      source: "Community (The Plural Association)"
    },

    // Ch 4 — Modulation
    "RMA": {
      label: "RMA (Recursive Meta-Analysis)",
      definition: "A method for breaking a tool into its smallest working pieces — atoms — and asking what each atom does for whoever uses it. RMA surfaces the mechanisms that make a technique actually work.",
      source: "FM"
    },
    "DMA": {
      label: "DMA (Destructive Meta-Analysis)",
      definition: "The companion to RMA. After atoms are surfaced, DMA asks what each atom assumes about the user — and which assumptions don't hold for everyone. DMA is how singularity assumptions get caught.",
      source: "FM"
    },
    "Modulation": {
      label: "Modulation",
      definition: "The general concept comes from music and signal processing — adjusting a signal's properties without losing what carries it. In FM: a method for taking a singlet-assuming tool, breaking it down, and rebuilding it so it explicitly works for plural identity.",
      source: "FM"
    },
    "interoceptive": {
      label: "Interoception",
      definition: "Sensing inside the body — heartbeat, breath, temperature, hunger, tension. Interoceptive techniques use the body's internal signals as the anchor.",
      source: "Clinical"
    },
    "vagal": {
      label: "Vagal",
      definition: "Related to the vagus nerve — the main nerve of the parasympathetic nervous system. Vagal tone influences heart rate, digestion, mood, and the body's ability to shift out of stress states. Many somatic grounding techniques work through vagal pathways.",
      source: "Clinical"
    },
    "meta-atom": {
      label: "Meta-atom",
      definition: "A distilled principle that emerges from running RMA/DMA across multiple atoms. Where atoms are the smallest working pieces of a tool, meta-atoms are higher-order patterns that hold across atoms — and become reusable Library entries for future builds.",
      source: "FM"
    },
    "meta-pattern": {
      label: "Meta-pattern",
      definition: "An observation stage in the Modulation pipeline: noticing patterns across atoms after RMA decomposes a tool. Meta-patterns are the precursors that, once distilled, become meta-atoms entering the Library.",
      source: "FM"
    },
    "singlet": {
      label: "Singlet",
      definition: "A person with one continuous identity — not part of a System. FM uses 'singlet' as a neutral descriptor, parallel to how 'plural' describes multiple-identity Systems. Not 'singleton,' not 'non-DID' — those framings center DID as the deviation. 'Singlet' centers no one.",
      source: "FM / Community"
    }
  };

  /* ── Setup ───────────────────────────────────────── */
  const tip  = document.getElementById('did-tooltip');
  if (!tip) return;
  const lbl  = tip.querySelector('.did-tooltip-label');
  const body = tip.querySelector('.did-tooltip-body');
  const src  = tip.querySelector('.did-tooltip-source');
  const cls  = tip.querySelector('.did-tooltip-close');
  let activeEl = null;

  function showTip(entry, triggerEl) {
    lbl.textContent  = entry.label;
    body.textContent = entry.definition;
    src.textContent  = entry.source;
    tip.removeAttribute('hidden');
    tip.classList.remove('visible');
    // Force reflow for transition
    tip.getBoundingClientRect();
    position(triggerEl);
    tip.classList.add('visible');
    activeEl = triggerEl;
  }

  function hideTip() {
    tip.classList.remove('visible');
    tip.setAttribute('hidden', '');
    if (activeEl) { activeEl = null; }
  }

  function position(el) {
    const tr = el.getBoundingClientRect();
    const tw = tip.offsetWidth;
    const th = tip.offsetHeight;
    const vw = window.innerWidth;
    const vh = window.innerHeight;
    const MARGIN = 8;

    // Horizontal: center on trigger, clamp to viewport
    let left = tr.left + tr.width / 2 - tw / 2;
    left = Math.max(MARGIN, Math.min(vw - tw - MARGIN, left));

    // Vertical: prefer above, fall back to below
    const above = tr.top - th - 10;
    const below = tr.bottom + 10;
    let top, arrowClass;
    if (above >= MARGIN) {
      top = above;
      arrowClass = 'arrow-below';
    } else {
      top = below;
      arrowClass = 'arrow-above';
    }

    // Arrow X relative to tooltip
    const arrowX = (tr.left + tr.width / 2) - left;
    const arrowPct = Math.max(10, Math.min(90, (arrowX / tw) * 100));

    tip.style.left = left + 'px';
    tip.style.top  = top + 'px';
    tip.style.setProperty('--arrow-x', arrowPct + '%');
    tip.classList.toggle('arrow-below', arrowClass === 'arrow-below');
    tip.classList.toggle('arrow-above', arrowClass === 'arrow-above');
  }

  /* ── Events ──────────────────────────────────────── */
  function handleTerm(e) {
    const el = e.currentTarget;
    const key = el.dataset.did;
    const entry = DICT[key];
    if (!entry) return;
    if (activeEl === el && !tip.hidden) {
      hideTip();
    } else {
      showTip(entry, el);
    }
    e.stopPropagation();
  }

  document.addEventListener('DOMContentLoaded', function () {
    // Attach to all .did-term elements
    document.querySelectorAll('.did-term').forEach(function (el) {
      el.setAttribute('tabindex', '0');
      el.setAttribute('role', 'button');
      const key = el.dataset.did || el.textContent.trim();
      if (!el.dataset.did) el.dataset.did = key;
      el.addEventListener('click',   handleTerm);
      el.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); handleTerm(e); }
        if (e.key === 'Escape') hideTip();
      });
      // Desktop hover
      el.addEventListener('mouseenter', function () {
        const entry = DICT[el.dataset.did];
        if (entry) showTip(entry, el);
      });
      el.addEventListener('mouseleave', function () {
        // Small delay — allow moving into tooltip
        setTimeout(function () {
          if (!tip.matches(':hover')) hideTip();
        }, 100);
      });
      // ARIA
      el.setAttribute('aria-label', (el.dataset.did || el.textContent.trim()) + ' — tap for definition');
    });

    // Keep tooltip visible when hovering it
    tip.addEventListener('mouseleave', hideTip);

    // Close button
    cls.addEventListener('click', function (e) { hideTip(); e.stopPropagation(); });

    // Dismiss on outside click
    document.addEventListener('click', function (e) {
      if (!tip.contains(e.target) && !e.target.classList.contains('did-term')) {
        hideTip();
      }
    });

    // Dismiss on Escape
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') hideTip();
    });

    // Reposition on scroll/resize
    window.addEventListener('resize', function () {
      if (activeEl && !tip.hidden) position(activeEl);
    });
  });
}());