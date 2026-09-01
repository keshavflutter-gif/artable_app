/* =========================================================
   ARTABLE — shared behaviors for Home / Challenges module.
   Pure UI logic + static-data rendering. No backend calls —
   every spot that would eventually hit an API is marked
   "// TODO(api):".
   ========================================================= */

const ICONS = {
  star: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2 15 9 22 9.3 16.6 14 18.2 21 12 17.3 5.8 21 7.4 14 2 9.3 9 9 Z"/></svg>',
  trophy: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M7 3h10v4a5 5 0 0 1-4 4.9V15h2a1 1 0 0 1 1 1v1H8v-1a1 1 0 0 1 1-1h2v-3.1A5 5 0 0 1 7 7V3Z"/><path d="M7 4H4a3 3 0 0 0 3 5.3V4Z"/><path d="M17 4h3a3 3 0 0 1-3 5.3V4Z"/><rect x="7" y="19" width="10" height="2" rx="1"/></svg>',
  users: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v2"/><circle cx="10" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
  calendar: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="3"/><path d="M16 3v4M8 3v4M3 10h18"/></svg>',
  play: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>',
  chevronRight: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 6 15 12 9 18"/></svg>',
  prize: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 4h8v4a4 4 0 0 1-8 0V4Z"/><path d="M8 5H5a3 3 0 0 0 3 5M16 5h3a3 3 0 0 1-3 5M10 15h4v3h-4zM8 21h8"/></svg>',
  checkCircle: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="m8.5 12.5 2.5 2.5 4.5-5"/></svg>',
  crown: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 8.5 7 11l5-6 5 6 4-2.5-1.5 9.5h-15L3 8.5Z"/></svg>',
  medal: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="15" r="6"/><path d="M9 10 6 3M15 10l3-7M9.5 15l1.7 1.7L15 13"/></svg>',
  /* ---------- studio (video recording module) ---------- */
  flash: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M13 2 4 14h6l-1 8 9-12h-6l1-8Z"/></svg>',
  flashOff: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2 8.5 8.7M4 14h6l-1 8 3.6-4.8M18 8.7 20 6h-6l.6-4M2 2l20 20"/></svg>',
  musicNote: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/></svg>',
  cameraSwitch: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 15a8 8 0 0 1-14.3 4.9M4 9a8 8 0 0 1 14.3-4.9"/><polyline points="4 4 4 9 9 9"/><polyline points="20 20 20 15 15 15"/></svg>',
  retake: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><path d="M3.5 15a9 9 0 1 0 2-9.4L1 10"/></svg>',
  search: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>',
  pause: '<svg viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/></svg>',
  trash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
  cloudUpload: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 18a5 5 0 0 1-1-9.9A6 6 0 0 1 17.6 7 4.5 4.5 0 0 1 17 16"/><polyline points="12 12 12 21"/><polyline points="9 15 12 12 15 15"/></svg>',
  bulb: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18h6M10 22h4M12 2a7 7 0 0 0-4 12.7c.6.5 1 1.3 1 2.3h6c0-1 .4-1.8 1-2.3A7 7 0 0 0 12 2Z"/></svg>',
  mic: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="2" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v4M8 22h8"/></svg>',
  target: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/></svg>',
  clock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><polyline points="12 7 12 12 15.5 14"/></svg>',
  sparkle: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2 13.8 9 21 12l-7.2 3L12 22l-1.8-7L3 12l7.2-3Z"/></svg>',
  /* ---------- reels & video feed module ---------- */
  heart: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>',
  heartFilled: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>',
  comment: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 11.5a8.4 8.4 0 0 1-8.9 8.4 8.6 8.6 0 0 1-3.5-.7L3 21l1.8-5.4A8.4 8.4 0 0 1 3.6 11.5 8.4 8.4 0 0 1 12 3a8.4 8.4 0 0 1 9 8.5Z"/></svg>',
  shareIcon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.6" y1="10.6" x2="15.4" y2="6.4"/><line x1="8.6" y1="13.4" x2="15.4" y2="17.6"/></svg>',
  bookmark: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h12a1 1 0 0 1 1 1v17l-7-4-7 4V4a1 1 0 0 1 1-1Z"/></svg>',
  bookmarkFilled: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M6 3h12a1 1 0 0 1 1 1v17l-7-4-7 4V4a1 1 0 0 1 1-1Z"/></svg>',
  bell: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></svg>',
  flag: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V4s-1 1-4 1-5-2-8-2-4 1-4 1Z"/><line x1="4" y1="22" x2="4" y2="4"/></svg>',
  link: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 17H7a5 5 0 0 1 0-10h2"/><path d="M15 7h2a5 5 0 0 1 0 10h-2"/><line x1="8" y1="12" x2="16" y2="12"/></svg>',
  whatsapp: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2a10 10 0 0 0-8.6 15L2 22l5.2-1.4A10 10 0 1 0 12 2Zm5.7 14.2c-.2.6-1.3 1.2-1.9 1.3-.5.1-1.1.1-1.8-.1-.4-.1-1-.3-1.7-.6-3-1.3-4.9-4.3-5.1-4.5-.1-.2-1.2-1.6-1.2-3.1s.8-2.2 1.1-2.5c.3-.3.6-.4.8-.4h.6c.2 0 .4 0 .6.5.2.6.7 1.9.8 2 .1.2.1.3 0 .5-.1.2-.1.3-.3.5-.1.2-.3.4-.4.5-.1.1-.3.3-.1.6.2.3.9 1.4 1.9 2.3 1.3 1.2 2.4 1.5 2.7 1.7.3.2.5.1.7-.1.2-.2.8-.9 1-1.2.2-.3.4-.2.7-.1.3.1 1.7.8 2 1 .3.1.5.2.6.3.1.2.1.9-.1 1.5Z"/></svg>',
  sms: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2Z"/></svg>',
  email: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m2 6 10 7 10-7"/></svg>',
  follow: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" y1="8" x2="19" y2="14"/><line x1="16" y1="11" x2="22" y2="11"/></svg>',
  moreHoriz: '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="19" cy="12" r="2"/></svg>',
  send: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>',
  eyeSolid: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z"/><circle cx="12" cy="12" r="3" fill="#150C2B"/></svg>',
  /* ---------- search / leaderboard / profile modules ---------- */
  edit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>',
  settings: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1-1.6 1.7 1.7 0 0 0-1.9.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.9 1.7 1.7 0 0 0-1.6-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.6-1 1.7 1.7 0 0 0-.3-1.9l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.9.3H9a1.7 1.7 0 0 0 1-1.6V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.6 1.7 1.7 0 0 0 1.9-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.9V9a1.7 1.7 0 0 0 1.6 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.6 1Z"/></svg>',
  lock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>',
  chevronDown: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>',
  verified: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2l2.4 1.4L17 3l.6 2.6L20 7l-1 2.4L20 12l-2 1.6L17 16l-2.6.4L12 18l-2.4-1.6L7 16l-.6-2.4L4 12l1-2.6L4 7l3-1.4L7 3l2.6.4Z"/><path fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="m8.3 12.1 2.3 2.3 5-5"/></svg>',
  camera: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2Z"/><circle cx="12" cy="13" r="4"/></svg>',
  wallet: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12V7a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5Z"/><path d="M17 12h.01"/><path d="M12 12h5v5h-5a2.5 2.5 0 0 1 0-5Z"/></svg>',
  /* ---------- rewards & wallet module ---------- */
  cash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M6 6v.01M18 17.99V18"/></svg>',
  ticket: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v2a2 2 0 0 0 0 4v2a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-2a2 2 0 0 0 0-4V8Z"/><line x1="10" y1="6" x2="10" y2="18" stroke-dasharray="2 3"/></svg>',
  box: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 8v8a2 2 0 0 1-1 1.7l-7 4a2 2 0 0 1-2 0l-7-4A2 2 0 0 1 3 16V8a2 2 0 0 1 1-1.7l7-4a2 2 0 0 1 2 0l7 4A2 2 0 0 1 21 8Z"/><polyline points="3.3 7 12 12 20.7 7"/><line x1="12" y1="22" x2="12" y2="12"/></svg>',
  handshake: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m11 17 1.5 1.5a2.1 2.1 0 0 0 3-3L12 12"/><path d="m14.5 14 1.5-1.5a2 2 0 0 0-3-2.7L11 12"/><path d="M4 12h3l4-4 3 3-1.5 1.5"/><path d="M2 10.5 6 7l3.5 3.5"/></svg>',
  arrowDownCircle: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><polyline points="8 12 12 16 16 12"/><line x1="12" y1="8" x2="12" y2="16"/></svg>',
  arrowUpCircle: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><polyline points="16 12 12 8 8 12"/><line x1="12" y1="16" x2="12" y2="8"/></svg>',
  truck: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="6" width="14" height="11" rx="1"/><path d="M15 9h4l3 3v5h-7z"/><circle cx="6" cy="19" r="2"/><circle cx="17.5" cy="19" r="2"/></svg>',
  bankCard: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/><line x1="6" y1="15" x2="10" y2="15"/></svg>',
  /* ---------- winners / referral / music / bonus / notifications / membership modules ---------- */
  copy: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>',
  diamond: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M6 3h12l4 6-10 12L2 9Z"/></svg>',
  flame: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2c1 4-3 5-3 9a3 3 0 0 0 6 0c0-1.5-1-2-1-3.5 2 1 3 3.5 3 5.5a5 5 0 0 1-10 0C7 8 10 6 12 2Z"/></svg>',
  gift: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="9" width="18" height="12" rx="2"/><path d="M3 13h18M12 9v12M8 9c-2 0-3-1.5-2-3s3.5-1 4 1c.5-2 3-2.5 4-1s0 3-2 3H8Z"/></svg>',
  pieChart: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.2 15a10 10 0 1 1-9.2-14"/><path d="M12 2v10l7 7"/></svg>',
  noAds: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><line x1="7" y1="7" x2="17" y2="17"/></svg>',
  headphones: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 14v-2a9 9 0 0 1 18 0v2"/><rect x="3" y="14" width="5" height="7" rx="1.5"/><rect x="16" y="14" width="5" height="7" rx="1.5"/></svg>',
  /* ---------- settings & support module ---------- */
  eyeOff: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.94 10.94 0 0 1 12 20C5 20 1 12 1 12a20.6 20.6 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a20.6 20.6 0 0 1-2.16 3.19"/><path d="M9.5 9.5a3 3 0 0 0 4.24 4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>',
  shield: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2 4 5v6c0 5 3.4 8.7 8 11 4.6-2.3 8-6 8-11V5l-8-3Z"/></svg>',
  logout: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>',
  fileText: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/></svg>',
  helpCircle: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 0 1 5 0c0 1.5-2 1.7-2 3.3"/><line x1="12" y1="16.2" x2="12" y2="16.2"/></svg>',
};

/* ---------- real-photo fallback ----------
   LoremFlickr occasionally times out / rate-limits / has no match for a
   keyword pair, which shows up as a broken-image icon or a grey box.
   Any <img onerror="imgFallback(this)"> swaps to Picsum's CDN (very
   reliable, still a real photograph — just not keyword-matched) using a
   seed derived from the alt text, so the same item keeps the same
   fallback photo across reloads instead of a broken image ever showing. */
function imgFallback(el) {
  if (el.dataset.fallbackApplied) return;
  el.dataset.fallbackApplied = '1';
  const seed = encodeURIComponent(el.alt || el.currentSrc || el.src || String(Math.floor(Math.random() * 9999)));
  const w = el.naturalWidth || el.width || 400;
  const h = el.naturalHeight || el.height || 400;
  el.src = `https://picsum.photos/seed/${seed}/${Math.max(w, 200)}/${Math.max(h, 200)}`;
}

/* ---------- formatting helpers ---------- */
function formatDate(iso) {
  const d = new Date(iso + 'T00:00:00');
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}
function daysRemaining(iso) {
  const end = new Date(iso + 'T00:00:00');
  const today = new Date('2026-07-11T00:00:00'); // fixed "today" for a stable static prototype
  const diff = Math.ceil((end - today) / 86400000);
  return diff;
}
function formatParticipants(n) {
  return n >= 1000 ? `${(n / 1000).toFixed(1).replace(/\.0$/, '')}K` : String(n);
}

/* ---------- badges ---------- */
function ratingBadgeHtml(rating) {
  if (!rating) return `<span class="rating-badge rating-badge--new">New</span>`;
  return `<span class="rating-badge">${ICONS.star}${rating.toFixed(1)}</span>`;
}
function statusBadgeHtml(status) {
  const labels = { active: 'Active', upcoming: 'Upcoming', completed: 'Completed', featured: 'Featured' };
  return `<span class="status-badge status-badge--${status}">${labels[status] || status}</span>`;
}

/* ---------- card renderers ---------- */
function challengeCardHtml(c) {
  const remaining = daysRemaining(c.endDate);
  const dateLabel = c.status === 'completed'
    ? `Ended ${formatDate(c.endDate)}`
    : c.status === 'upcoming'
      ? `Starts ${formatDate(c.endDate)}`
      : `${remaining > 0 ? remaining + 'd left' : 'Ending today'}`;
  const ctaLabel = c.status === 'completed' ? 'View Results' : c.status === 'upcoming' ? 'View Details' : 'Join Challenge';

  return `
  <article class="challenge-card">
    <a class="challenge-card__media" href="challenge-detail.html?id=${c.id}">
      <img src="${c.imageUrl}" alt="${c.title}" loading="lazy">
      ${statusBadgeHtml(c.status)}
      ${ratingBadgeHtml(c.rating)}
    </a>
    <div class="challenge-card__body">
      <span class="challenge-card__category">${c.category}</span>
      <h3 class="challenge-card__title">
        <a href="challenge-detail.html?id=${c.id}">${c.title}</a>
      </h3>
      <div class="challenge-card__stats">
        <span class="stat-chip">${ICONS.prize}<span>${c.prize}</span></span>
        <span class="stat-chip">${ICONS.calendar}<span>${dateLabel}</span></span>
      </div>
      <div class="challenge-card__footer">
        <span class="challenge-card__participants">${ICONS.users}${formatParticipants(c.participants)} joined</span>
      </div>
      <a class="btn-gradient challenge-card__cta" href="challenge-detail.html?id=${c.id}">
        <span>${ctaLabel}</span>${ICONS.chevronRight}
      </a>
    </div>
  </article>`;
}

function challengeAdCardHtml() {
  return `
  <div class="challenge-ad-card">
    <span class="challenge-ad-card__tag">Ad</span>
    <div class="challenge-ad-card__media">
      <img src="https://images.unsplash.com/photo-1698440235228-9c617924c06e?w=340&h=340&q=80&auto=format&fit=crop" alt="Sponsored" loading="lazy" onerror="imgFallback(this)">
    </div>
    <div class="challenge-ad-card__body">
      <p class="challenge-ad-card__brand">SPORTIFY</p>
      <h3 class="challenge-ad-card__headline">Run Faster.<br>Be Stronger.</h3>
      <a class="challenge-ad-card__cta" href="#" onclick="return comingSoon(event)">Shop Now</a>
    </div>
  </div>`;
}

function categoryCardHtml(cat) {
  return `
  <a class="category-card" href="challenges.html?category=${cat.id}">
    <img src="${cat.imageUrl}" alt="${cat.name}" loading="lazy">
    <div class="category-card__overlay"></div>
    <div class="category-card__icon">${categoryIconSvg(cat.icon)}</div>
    <div class="category-card__text">
      <span class="category-card__name">${cat.name}</span>
      <span class="category-card__count-chip">${cat.count} live</span>
    </div>
  </a>`;
}

function reelThumbHtml(reel) {
  const categoryTint = {
    Dance: '#E01D5C', Comedy: '#3450D6', Fitness: '#1FAE6A',
    Singing: '#FF3D77', Magic: '#7420E8', Art: '#E8631F',
  }[reel.category] || 'var(--color-purple)';

  return `
  <a class="reel-thumb" href="#" onclick="return comingSoon(event)">
    <img src="${reel.imageUrl}" alt="${reel.title}" loading="lazy" onerror="imgFallback(this)">
    ${reel.category ? `<span class="reel-thumb__category" style="background:${categoryTint}">${reel.category}</span>` : ''}
    <div class="reel-thumb__info">
      <span class="reel-thumb__meta">${ICONS.play}${reel.views}</span>
      <span class="reel-thumb__creator-row">
        ${reel.avatarUrl ? `<img class="reel-thumb__avatar" src="${reel.avatarUrl}" alt="">` : ''}
        <span class="reel-thumb__handle">${reel.handle || reel.creator}</span>
        ${reel.verified ? `<svg class="reel-thumb__verified" viewBox="0 0 24 24" fill="currentColor"><path d="m9 12 2 2 4-4M12 2l2.4 1.4L17 3l.6 2.6L20 7l-1 2.4L20 12l-2 1.6L17 16l-2.6.4L12 18l-2.4-1.6L7 16l-.6-2.4L4 12l1-2.6L4 7l3-1.4L7 3l2.6.4Z"/></svg>` : ''}
      </span>
    </div>
  </a>`;
}

function categoryIconSvg(key) {
  const icons = {
    dance: '<path d="M12 4a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z" transform="translate(0 3)"/><path d="M12 7v5l-4 6M12 12l4 6M8 11l-3 2M16 11l3 2"/>',
    mic: '<rect x="9" y="2" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v4M8 22h8"/>',
    mask: '<circle cx="12" cy="12" r="9"/><path d="M8 10h.01M16 10h.01M8 15c1.5 1.3 6.5 1.3 8 0"/>',
    dumbbell: '<path d="M6 7v10M18 7v10M2 10v4M22 10v4M6 12h12"/>',
    wand: '<path d="M15 4V2M15 8V6M12 6h2M18 6h2M3 21l9-9M17 3l4 4-3 3-4-4Z"/>',
    brush: '<path d="M9 15c-1 3-3 4-6 4 1-3 0-5 2-7l9-9 4 4-9 8Z"/>',
    drama: '<circle cx="9" cy="9" r="3"/><circle cx="15" cy="15" r="3"/><path d="M9 12v3a3 3 0 0 0 3 3M15 12V9a3 3 0 0 0-3-3"/>',
    trophy: '<path d="M8 4h8v4a4 4 0 0 1-8 0V4Z"/><path d="M8 5H5a3 3 0 0 0 3 5M16 5h3a3 3 0 0 1-3 5M10 15h4v3h-4zM8 21h8"/>',
    sparkle: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8Z"/>',
  };
  return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${icons[key] || icons.sparkle}</svg>`;
}

function quickActionIconSvg(key) {
  const icons = {
    upload: '<path d="M12 16V4M7 9l5-5 5 5M4 16v3a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-3"/>',
    flame: '<path d="M12 2c1 4-3 5-3 9a3 3 0 0 0 6 0c0-1.5-1-2-1-3.5 2 1 3 3.5 3 5.5a5 5 0 0 1-10 0C7 8 10 6 12 2Z"/>',
    medal: '<circle cx="12" cy="15" r="6"/><path d="M9 10 6 3M15 10l3-7M9.5 15l1.7 1.7L15 13"/>',
    gift: '<rect x="3" y="9" width="18" height="12" rx="2"/><path d="M3 13h18M12 9v12M8 9c-2 0-3-1.5-2-3s3.5-1 4 1c.5-2 3-2.5 4-1s0 3-2 3H8Z"/>',
    invite: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/>',
    chart: '<path d="M4 20V10M11 20V4M18 20v-7"/><path d="M3 20h18"/>',
    music: '<circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/><path d="M9 18V5l12-2v13"/>',
    calendarBonus: '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M16 3v4M8 3v4M3 10h18"/><path d="M8 15l2 2 4-4"/>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M16 3v4M8 3v4M3 10h18"/><path d="M8 15l2 2 4-4"/>',
    video: '<rect x="2" y="6" width="14" height="12" rx="2"/><path d="M16 10.5 22 7v10l-6-3.5Z"/>',
    shield: '<path d="M12 3 4 6v6c0 5 3.5 8.5 8 9 4.5-.5 8-4 8-9V6l-8-3Z"/><path d="m9.5 12 2 2 4-4"/>',
    star: '<path d="M12 2 15 9 22 9.3 16.6 14 18.2 21 12 17.3 5.8 21 7.4 14 2 9.3 9 9 Z"/>',
    play: '<circle cx="12" cy="12" r="9"/><path d="M10 8.5v7l6-3.5Z"/>',
    trophy: '<path d="M8 4h8v4a4 4 0 0 1-8 0V4Z"/><path d="M8 5H5a3 3 0 0 0 3 5M16 5h3a3 3 0 0 1-3 5M10 15h4v3h-4zM8 21h8"/>',
    more: '<circle cx="5" cy="12" r="1.6" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.6" fill="currentColor" stroke="none"/><circle cx="19" cy="12" r="1.6" fill="currentColor" stroke="none"/>',
    chevronRight: '<polyline points="9 6 15 12 9 18"/>',
  };
  return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${icons[key] || icons.gift}</svg>`;
}

/* ---------- bottom nav active state ---------- */
function initBottomNav() {
  const path = (location.pathname.split('/').pop() || 'home.html');
  document.querySelectorAll('.bottom-nav__item').forEach((item) => {
    const target = item.getAttribute('data-page');
    item.classList.toggle('active', target === path);
  });
}

/* ---------- banner slider dot sync ---------- */
function initBannerSlider() {
  const track = document.querySelector('.banner-slider');
  const dots = document.querySelectorAll('.banner-dots .dot');
  if (!track || !dots.length) return;
  track.addEventListener('scroll', () => {
    const index = Math.round(track.scrollLeft / track.clientWidth);
    dots.forEach((d, i) => d.classList.toggle('active', i === index));
  }, { passive: true });
}

/* ---------- challenge list tab filter ---------- */
function initChallengeTabs() {
  const tabs = document.querySelectorAll('.tab-row .tab-btn');
  const grid = document.getElementById('challengeGrid');
  const emptyState = document.getElementById('challengeEmpty');
  if (!tabs.length || !grid) return;

  function render(status) {
    const list = CHALLENGES.filter((c) => (status === 'featured' ? c.featured : c.status === status));
    // Insert one native ad card after the 1st challenge (live in-feed ad slot).
    const cardsHtml = list.map(challengeCardHtml);
    if (cardsHtml.length > 1) cardsHtml.splice(1, 0, challengeAdCardHtml());
    grid.innerHTML = cardsHtml.join('');
    if (emptyState) emptyState.classList.toggle('hidden', list.length > 0);
  }

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      render(tab.dataset.status);
    });
  });

  const params = new URLSearchParams(location.search);
  const initial = params.get('tab') || 'active';
  const initialTab = document.querySelector(`.tab-row .tab-btn[data-status="${initial}"]`) || tabs[0];
  tabs.forEach((t) => t.classList.remove('active'));
  initialTab.classList.add('active');
  render(initialTab.dataset.status);
}

/* ---------- challenge detail hydration ---------- */
function hydrateChallengeDetail() {
  const params = new URLSearchParams(location.search);
  const challenge = CHALLENGES.find((c) => c.id === (params.get('id') || 'c1')) || CHALLENGES[0];

  document.title = `Artable — ${challenge.title}`;
  document.querySelectorAll('[data-field="heroImage"]').forEach((el) => el.setAttribute('src', challenge.imageUrl));
  document.querySelectorAll('[data-field="title"]').forEach((el) => { el.textContent = challenge.title; });
  document.querySelectorAll('[data-field="category"]').forEach((el) => { el.textContent = challenge.category; });
  document.querySelectorAll('[data-field="prize"]').forEach((el) => { el.textContent = challenge.prize; });
  document.querySelectorAll('[data-field="description"]').forEach((el) => { el.textContent = challenge.description; });
  document.querySelectorAll('[data-field="participants"]').forEach((el) => { el.textContent = `${formatParticipants(challenge.participants)} joined`; });
  document.querySelectorAll('[data-field="status"]').forEach((el) => { el.outerHTML = statusBadgeHtml(challenge.status); });

  const remaining = daysRemaining(challenge.endDate);
  const countdownMainEl = document.querySelector('[data-field="countdownMain"]');
  const countdownSubEl = document.querySelector('[data-field="countdownSub"]');
  if (countdownMainEl && countdownSubEl) {
    if (challenge.status === 'completed') {
      countdownMainEl.textContent = 'Ended';
      countdownSubEl.textContent = formatDate(challenge.endDate);
    } else if (challenge.status === 'upcoming') {
      countdownMainEl.textContent = 'Starts soon';
      countdownSubEl.textContent = formatDate(challenge.endDate);
    } else {
      countdownMainEl.textContent = remaining > 0 ? `${remaining} days left` : 'Ending today';
      countdownSubEl.textContent = `Ends ${formatDate(challenge.endDate)}`;
    }
  }

  const rulesList = document.getElementById('rulesList');
  if (rulesList) {
    rulesList.innerHTML = challenge.rules.map((r) => `
      <div class="rule-item">${ICONS.checkCircle}<span>${r}</span></div>
    `).join('');
  }

  const prizeList = document.getElementById('prizeList');
  if (prizeList) {
    prizeList.innerHTML = challenge.prizeBreakdown.map((p, i) => {
      const rank = i + 1;
      // reward strings look like "$2,500 + Champion Badge" — split the
      // cash amount (shown big) from the badge reward (shown as a chip)
      const [amount, badgeLabel] = p.reward.split(' + ');
      return `
      <div class="reward-card reward-card--${rank}">
        <span class="reward-card__rank">
          ${rank}
          ${rank === 1 ? `<span class="reward-card__rank-crown">${ICONS.crown}</span>` : ''}
        </span>
        <div class="reward-card__info">
          <p class="reward-card__place">${p.place}</p>
          <p class="reward-card__amount">${amount}</p>
          ${badgeLabel ? `<span class="reward-card__badge">${ICONS.medal}${badgeLabel}</span>` : ''}
        </div>
      </div>`;
    }).join('');
  }

  const topList = document.getElementById('topParticipants');
  if (topList) {
    topList.innerHTML = challenge.topParticipants.length
      ? challenge.topParticipants.map((p) => `
        <div class="top-participant">
          <img src="${p.avatarUrl}" alt="${p.name}">
          <span class="top-participant__name">${p.name}</span>
          <span class="rating-badge">${ICONS.star}${p.score.toFixed(1)}</span>
        </div>`).join('')
      : `<p class="empty-note">No entries yet — be the first to join.</p>`;
  }

  const joinBtn = document.getElementById('joinChallengeBtn');
  if (joinBtn) joinBtn.setAttribute('href', `submit-entry.html?id=${challenge.id}`);

  const shareBtn = document.getElementById('shareBtn');
  if (shareBtn) {
    shareBtn.addEventListener('click', () => {
      // TODO(api): replace with real deep link once challenge routes exist.
      if (navigator.share) {
        navigator.share({ title: challenge.title, text: `Check out "${challenge.title}" on Artable!` }).catch(() => {});
      }
    });
  }
}

/* ---------- submit-entry hydration + draft selection ---------- */
/* Shared by submit-entry.html and every Studio page: fills any
   [data-field="summary*"] elements from a CHALLENGES entry. */
function fillChallengeSummary(challenge) {
  document.querySelectorAll('[data-field="summaryImage"]').forEach((el) => el.setAttribute('src', challenge.imageUrl));
  document.querySelectorAll('[data-field="summaryTitle"]').forEach((el) => { el.textContent = challenge.title; });
  document.querySelectorAll('[data-field="summaryCategory"]').forEach((el) => { el.textContent = challenge.category; });
  document.querySelectorAll('[data-field="summaryPrize"]').forEach((el) => { el.textContent = challenge.prize; });
  document.querySelectorAll('[data-field="summaryEndDate"]').forEach((el) => { el.textContent = `Ends ${formatDate(challenge.endDate)}`; });
}

function currentChallenge() {
  const params = new URLSearchParams(location.search);
  return CHALLENGES.find((c) => c.id === (params.get('id') || 'c1')) || CHALLENGES[0];
}

function hydrateSubmitEntry() {
  const challenge = currentChallenge();
  fillChallengeSummary(challenge);

  const recordBtn = document.getElementById('recordStudioBtn');
  const draftsToggle = document.getElementById('viewDraftsBtn');
  const draftsPanel = document.getElementById('draftsPanel');
  const submitBtn = document.getElementById('submitEntryBtn');
  const selectedNote = document.getElementById('selectedDraftNote');
  const rulesCheck = document.getElementById('rulesConfirmCheck');

  function updateSubmitState() {
    const hasDraft = !!document.querySelector('.draft-option.selected');
    const rulesOk = !rulesCheck || rulesCheck.checked;
    submitBtn.disabled = !(hasDraft && rulesOk);
  }

  if (recordBtn) {
    recordBtn.addEventListener('click', () => {
      window.location.href = `studio-start.html?id=${challenge.id}`;
    });
  }

  if (draftsToggle && draftsPanel) {
    draftsToggle.addEventListener('click', () => {
      draftsPanel.classList.toggle('hidden');
    });
    draftsPanel.querySelectorAll('.draft-option').forEach((opt) => {
      opt.addEventListener('click', () => {
        draftsPanel.querySelectorAll('.draft-option').forEach((o) => o.classList.remove('selected'));
        opt.classList.add('selected');
        if (selectedNote) {
          selectedNote.textContent = `Selected: ${opt.dataset.name}`;
          selectedNote.classList.remove('hidden');
        }
        updateSubmitState();
      });
    });
  }

  if (rulesCheck) rulesCheck.addEventListener('change', updateSubmitState);

  if (submitBtn) {
    submitBtn.addEventListener('click', (e) => {
      if (submitBtn.disabled) { e.preventDefault(); return; }
      // TODO(api): POST the selected draft + challenge id to the entries endpoint.
      // Route through the existing Upload/Submission Progress screen, which
      // already navigates to the Entry Submitted screen (studio-success.html)
      // once it completes.
      window.location.href = `studio-upload.html?id=${challenge.id}`;
    });
  }

  updateSubmitState();
}

/* =========================================================
   Video Recording Studio (module 3) — pure UI logic + static
   data rendering, same conventions as the rest of app.js.
   Gallery upload is intentionally never offered anywhere below.
   ========================================================= */

function formatDraftTimestamp(iso) {
  const d = new Date(iso);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) + ', ' +
    d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

/* ---------- reusable card templates ---------- */

// Shared 4-step progress indicator (StudioStepIndicator), used on the
// Start screen (step 0) and Add Video Details screen (step 2).
const STUDIO_STEPS = ['Challenge', 'Record', 'Details', 'Preview'];
const STUDIO_STEP_CHECK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
function studioStepIndicatorHtml(activeIndex) {
  const progressPct = (activeIndex / (STUDIO_STEPS.length - 1)) * 100;
  return `
  <div class="studio-step-row">
    <div class="studio-step-track"><div class="studio-step-track__fill" style="width:${progressPct}%"></div></div>
    <div class="studio-step-list">
      ${STUDIO_STEPS.map((label, i) => `
        <div class="studio-step${i === activeIndex ? ' active' : i < activeIndex ? ' done' : ''}">
          <span class="studio-step__dot">${i < activeIndex ? STUDIO_STEP_CHECK : i + 1}</span>
          <span class="studio-step__label">${label}</span>
        </div>`).join('')}
    </div>
  </div>`;
}

const STUDIO_FILTER_ICONS = {
  natural: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><path d="M12 1v3M12 20v3M4.2 4.2l2.2 2.2M17.6 17.6l2.2 2.2M1 12h3M20 12h3M4.2 19.8l2.2-2.2M17.6 6.4l2.2-2.2"/></svg>',
  glow:    '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2 13.8 9 21 12l-7.2 3L12 22l-1.8-7L3 12l7.2-3Z"/></svg>',
  warm:    '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2c1 4-3 5-3 9a3 3 0 0 0 6 0c0-1.5-1-2-1-3.5 2 1 3 3.5 3 5.5a5 5 0 0 1-10 0C7 8 10 6 12 2Z"/></svg>',
  studio:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 7l-7 5 7 5V7Z"/><rect x="1" y="5" width="15" height="14" rx="2"/></svg>',
  beauty:  '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2 15 9 22 9.3 16.6 14 18.2 21 12 17.3 5.8 21 7.4 14 2 9.3 9 9 Z"/></svg>',
  mono:    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 1 0 18Z" fill="currentColor" stroke="none"/></svg>',
};

function musicTrackCardHtml(track, isSelected, isLiked) {
  return `
  <div class="music-track-card${isSelected ? ' is-selected' : ''}" data-track-id="${track.id}">
    <img class="music-track-card__cover" src="${track.coverUrl}" alt="${track.title}" loading="lazy" onerror="imgFallback(this)">
    <button class="music-track-card__play" type="button" data-play="${track.id}" aria-label="Preview ${track.title}">${ICONS.play}</button>
    <div class="music-track-card__body">
      <span class="music-track-card__title">${track.title}</span>
      <span class="music-track-card__artist">${track.artist} · ${track.duration}</span>
    </div>
    <button class="music-track-card__like${isLiked ? ' is-liked' : ''}" type="button" data-like="${track.id}" aria-label="Favorite ${track.title}">
      <svg viewBox="0 0 24 24" fill="${isLiked ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
    </button>
    <button class="music-track-card__use" type="button" data-use="${track.id}">${isSelected ? 'Selected' : 'Use'}</button>
  </div>`;
}

function draftCardHtml(draft) {
  return `
  <div class="draft-card" data-draft-id="${draft.id}">
    <img class="draft-card__thumb" src="${draft.thumbnailUrl}" alt="${draft.challengeTitle}" loading="lazy" onerror="imgFallback(this)">
    <div class="draft-card__body">
      <span class="draft-card__title">${draft.challengeTitle}</span>
      <span class="draft-card__meta">${formatDraftTimestamp(draft.recordedAt)} · ${draft.duration}</span>
      <span class="draft-card__status">Draft</span>
    </div>
    <div class="draft-card__actions">
      <a class="draft-card__continue" href="studio-preview.html?draft=${draft.id}&id=${draft.challengeId}">Continue</a>
      <button class="draft-card__delete" type="button" data-delete="${draft.id}" aria-label="Delete draft">${ICONS.trash}</button>
    </div>
  </div>`;
}

function uploadStepHtml(label, state) {
  const icon = state === 'done' ? ICONS.checkCircle : state === 'active' ? ICONS.clock : ICONS.clock;
  return `
  <div class="upload-step upload-step--${state}" data-step-label="${label}">
    <span class="upload-step__icon">${icon}</span>
    <span class="upload-step__label">${label}</span>
  </div>`;
}

/* ---------- 13. In-App Studio Start Screen ---------- */
function hydrateStudioStart() {
  const challenge = currentChallenge();
  fillChallengeSummary(challenge);

  const stepRow = document.getElementById('studioStepRow');
  if (stepRow) stepRow.innerHTML = studioStepIndicatorHtml(0);

  const startBtn = document.getElementById('startRecordingBtn');
  const draftsBtn = document.getElementById('viewDraftsStudioBtn');
  if (startBtn) startBtn.addEventListener('click', () => { window.location.href = `studio-camera.html?id=${challenge.id}`; });
  if (draftsBtn) draftsBtn.addEventListener('click', () => { window.location.href = `studio-drafts.html?id=${challenge.id}`; });
}

/* ---------- 14. Camera Recording Screen ---------- */
function hydrateStudioCamera() {
  const challenge = currentChallenge();
  const MAX_SECONDS = 60;

  const timerEl = document.getElementById('cameraTimer');
  const ring = document.getElementById('cameraProgressRing');
  const recordBtn = document.getElementById('recordBtn');
  const retakeBtn = document.getElementById('retakeBtn');
  const nextBtn = document.getElementById('nextToPreviewBtn');
  const flashBtn = document.getElementById('flashBtn');
  const switchBtn = document.getElementById('switchCameraBtn');
  const musicBtn = document.getElementById('cameraMusicBtn');
  const effectsBtn = document.getElementById('cameraEffectsBtn');
  const timerBtn = document.getElementById('timerBtn');
  const speedBtn = document.getElementById('speedBtn');
  const speedLabel = document.getElementById('speedBtnLabel');
  const stage = document.getElementById('cameraStage');
  const RING_LENGTH = 264; // 2 * PI * r(42)

  let seconds = 0;
  let timerHandle = null;
  let state = 'idle'; // idle -> recording -> recorded

  function renderTimer() {
    const m = String(Math.floor(seconds / 60)).padStart(2, '0');
    const s = String(seconds % 60).padStart(2, '0');
    if (timerEl) timerEl.textContent = `${m}:${s}`;
    if (ring) ring.style.strokeDashoffset = String(RING_LENGTH - (RING_LENGTH * seconds) / MAX_SECONDS);
  }

  function setState(next) {
    state = next;
    stage?.classList.toggle('is-recording', state === 'recording');
    recordBtn?.classList.toggle('hidden', state === 'recorded');
    retakeBtn?.classList.toggle('hidden', state !== 'recorded');
    nextBtn?.classList.toggle('hidden', state !== 'recorded');
  }

  recordBtn?.addEventListener('click', () => {
    if (state === 'idle') {
      setState('recording');
      timerHandle = setInterval(() => {
        seconds += 1;
        renderTimer();
        if (seconds >= MAX_SECONDS) stopRecording();
      }, 1000);
    } else if (state === 'recording') {
      stopRecording();
    }
  });

  function stopRecording() {
    clearInterval(timerHandle);
    setState('recorded');
  }

  retakeBtn?.addEventListener('click', () => {
    clearInterval(timerHandle);
    seconds = 0;
    renderTimer();
    setState('idle');
  });

  nextBtn?.addEventListener('click', (e) => {
    e.preventDefault();
    sessionStorage.setItem('artable_recorded_duration', timerEl ? timerEl.textContent : '0:00');
    window.location.href = `studio-preview.html?id=${challenge.id}`;
  });

  flashBtn?.addEventListener('click', () => {
    const isOn = flashBtn.classList.toggle('is-active');
    flashBtn.innerHTML = isOn ? ICONS.flash : ICONS.flashOff;
  });

  switchBtn?.addEventListener('click', () => {
    switchBtn.classList.add('is-spinning');
    setTimeout(() => switchBtn.classList.remove('is-spinning'), 350);
  });

  musicBtn?.addEventListener('click', () => { window.location.href = `studio-music.html?id=${challenge.id}`; });
  effectsBtn?.addEventListener('click', () => { window.location.href = `studio-filters.html?id=${challenge.id}`; });

  // Cosmetic-only toggles — no real timer-delay or playback-speed logic yet.
  timerBtn?.addEventListener('click', () => { timerBtn.classList.toggle('is-active'); });
  const speeds = ['1x', '1.5x', '2x', '0.5x'];
  let speedIdx = 0;
  speedBtn?.addEventListener('click', () => {
    speedIdx = (speedIdx + 1) % speeds.length;
    if (speedLabel) speedLabel.textContent = speeds[speedIdx];
    speedBtn.classList.toggle('is-active', speedIdx !== 0);
  });

  renderTimer();
  setState('idle');
}

/* ---------- 15. Music Selection Screen ---------- */
function hydrateStudioMusic() {
  const list = document.getElementById('musicList');
  const tabs = Array.from(document.querySelectorAll('.music-tabs .tab-btn'));
  const searchInput = document.getElementById('musicSearchInput');
  const selectedBar = document.getElementById('musicSelectedBar');
  const selectedName = document.getElementById('musicSelectedName');
  const doneBtn = document.getElementById('musicDoneBtn');

  let activeTab = 'all';
  let query = '';
  let selectedId = null;
  let playingId = null;
  const likedIds = new Set();

  function render() {
    const rows = MUSIC_TRACKS.filter((t) => (activeTab === 'all' || t.tab === activeTab) &&
      (t.title.toLowerCase().includes(query) || t.artist.toLowerCase().includes(query)));
    list.innerHTML = rows.length
      ? rows.map((t) => musicTrackCardHtml(t, t.id === selectedId, likedIds.has(t.id))).join('')
      : `<p class="empty-note">No tracks match your search.</p>`;
  }

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      activeTab = tab.dataset.tab;
      render();
    });
  });

  searchInput?.addEventListener('input', () => {
    query = searchInput.value.trim().toLowerCase();
    render();
  });

  list.addEventListener('click', (e) => {
    const playBtn = e.target.closest('[data-play]');
    if (playBtn) {
      const id = playBtn.dataset.play;
      playingId = playingId === id ? null : id;
      list.querySelectorAll('.music-track-card__play').forEach((btn) => {
        const cardId = btn.closest('.music-track-card').dataset.trackId;
        btn.innerHTML = cardId === playingId ? ICONS.pause : ICONS.play;
      });
      return;
    }
    const likeBtn = e.target.closest('[data-like]');
    if (likeBtn) {
      const id = likeBtn.dataset.like;
      if (likedIds.has(id)) likedIds.delete(id); else likedIds.add(id);
      likeBtn.classList.toggle('is-liked');
      likeBtn.querySelector('svg').setAttribute('fill', likedIds.has(id) ? 'currentColor' : 'none');
      return;
    }
    const useBtn = e.target.closest('[data-use]');
    if (useBtn) {
      selectedId = useBtn.dataset.use;
      const track = MUSIC_TRACKS.find((t) => t.id === selectedId);
      render();
      if (track && selectedBar && selectedName) {
        selectedName.textContent = `${track.title} — ${track.artist}`;
        selectedBar.classList.remove('hidden');
      }
    }
  });

  doneBtn?.addEventListener('click', () => {
    const track = MUSIC_TRACKS.find((t) => t.id === selectedId);
    if (track) sessionStorage.setItem('artable_selected_music', `${track.title} — ${track.artist}`);
    if (window.history.length > 1) window.history.back();
    else window.location.href = `studio-camera.html?id=${currentChallenge().id}`;
  });

  render();
}

/* ---------- 16. Recording Effects / Filters Screen ---------- */
function hydrateStudioFilters() {
  const carousel = document.getElementById('filterCarousel');
  carousel.innerHTML = STUDIO_FILTERS.map((f, i) => `
    <button class="filter-option${i === 0 ? ' active' : ''}" type="button" data-filter="${f.id}">
      <span class="filter-option__swatch" style="background:${f.swatch}">${STUDIO_FILTER_ICONS[f.id] || ''}</span>
      <span class="filter-option__label">${f.label}</span>
    </button>`).join('');

  carousel.addEventListener('click', (e) => {
    const btn = e.target.closest('.filter-option');
    if (!btn) return;
    carousel.querySelectorAll('.filter-option').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
  });

  const speedRow = document.getElementById('speedRow');
  speedRow?.addEventListener('click', (e) => {
    const btn = e.target.closest('.speed-btn');
    if (!btn) return;
    speedRow.querySelectorAll('.speed-btn').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
  });

  const beautyToggle = document.getElementById('beautyToggle');
  const beautyIntensity = document.getElementById('beautyIntensityRow');
  beautyToggle?.addEventListener('change', () => {
    beautyIntensity?.classList.toggle('hidden', !beautyToggle.checked);
  });

  const applyBtn = document.getElementById('applyFiltersBtn');
  applyBtn?.addEventListener('click', () => {
    if (window.history.length > 1) window.history.back();
    else window.location.href = `studio-camera.html?id=${currentChallenge().id}`;
  });
}

/* ---------- 17. Video Preview Screen ---------- */
function hydrateStudioPreview() {
  const challenge = currentChallenge();
  fillChallengeSummary(challenge);

  const params = new URLSearchParams(location.search);
  const draftId = params.get('draft');
  const draft = draftId ? DRAFTS.find((d) => d.id === draftId) : null;

  const posterEl = document.getElementById('previewPoster');
  const durationEl = document.getElementById('previewDuration');
  const musicInfoEl = document.getElementById('previewMusicInfo');
  const playBtn = document.getElementById('previewPlayBtn');
  const stage = document.getElementById('previewStage');

  const duration = draft ? draft.duration : (sessionStorage.getItem('artable_recorded_duration') || '0:42');
  if (posterEl) posterEl.src = draft ? draft.thumbnailUrl : challenge.imageUrl;
  if (durationEl) durationEl.textContent = duration;

  const music = sessionStorage.getItem('artable_selected_music');
  if (musicInfoEl) {
    if (music) { musicInfoEl.innerHTML = `${ICONS.musicNote}<span>${music}</span>`; musicInfoEl.classList.remove('hidden'); }
    else musicInfoEl.classList.add('hidden');
  }

  playBtn?.addEventListener('click', () => {
    const isPlaying = stage.classList.toggle('is-playing');
    playBtn.innerHTML = isPlaying ? ICONS.pause : ICONS.play;
  });

  document.getElementById('retakeFromPreviewBtn')?.addEventListener('click', () => {
    window.location.href = `studio-camera.html?id=${challenge.id}`;
  });

  document.getElementById('saveDraftBtn')?.addEventListener('click', () => {
    const newDraft = {
      id: `d${Date.now()}`,
      challengeId: challenge.id,
      challengeTitle: challenge.title,
      duration,
      recordedAt: new Date().toISOString(),
      thumbnailUrl: challenge.imageUrl,
    };
    DRAFTS.unshift(newDraft);
    window.location.href = `studio-drafts.html?id=${challenge.id}`;
  });

  document.getElementById('continueToDetailsBtn')?.addEventListener('click', () => {
    window.location.href = `studio-details.html?id=${challenge.id}${draftId ? `&draft=${draftId}` : ''}`;
  });
}

/* ---------- 18. Save Draft / Draft List Screen ---------- */
function hydrateStudioDrafts() {
  const list = document.getElementById('draftListEl');
  const emptyState = document.getElementById('draftEmptyState');

  function render() {
    if (!list) return;
    list.innerHTML = DRAFTS.map(draftCardHtml).join('');
    if (emptyState) emptyState.classList.toggle('hidden', DRAFTS.length > 0);
    list.classList.toggle('hidden', DRAFTS.length === 0);
  }

  list?.addEventListener('click', (e) => {
    const delBtn = e.target.closest('[data-delete]');
    if (!delBtn) return;
    const id = delBtn.dataset.delete;
    const idx = DRAFTS.findIndex((d) => d.id === id);
    if (idx > -1) DRAFTS.splice(idx, 1);
    render();
  });

  document.getElementById('emptyStartRecordingBtn')?.addEventListener('click', () => {
    window.location.href = `studio-start.html?id=${currentChallenge().id}`;
  });

  render();
}

/* ---------- 19. Add Video Details Screen ---------- */
function hydrateStudioDetails() {
  const params = new URLSearchParams(location.search);
  const draftId = params.get('draft');
  const draft = draftId ? DRAFTS.find((d) => d.id === draftId) : null;
  const initialChallenge = CHALLENGES.find((c) => c.id === (draft ? draft.challengeId : params.get('id'))) || CHALLENGES[0];

  const stepRow = document.getElementById('detailsStepRow');
  if (stepRow) stepRow.innerHTML = studioStepIndicatorHtml(2);

  const posterEl = document.getElementById('detailsPreviewPoster');
  const durationEl = document.getElementById('detailsPreviewDuration');
  const playBtn = document.getElementById('detailsPreviewPlayBtn');
  if (posterEl) posterEl.src = draft ? draft.thumbnailUrl : initialChallenge.imageUrl;
  if (durationEl) durationEl.textContent = draft ? draft.duration : (sessionStorage.getItem('artable_recorded_duration') || '0:00');
  playBtn?.addEventListener('click', () => {
    const isPlaying = playBtn.classList.toggle('is-playing');
    playBtn.innerHTML = isPlaying ? ICONS.pause : '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
  });

  const musicChip = document.getElementById('selectedMusicChip');
  const savedMusic = sessionStorage.getItem('artable_selected_music');
  if (musicChip) {
    if (savedMusic) { musicChip.querySelector('span').textContent = savedMusic; musicChip.classList.remove('hidden'); }
    else musicChip.classList.add('hidden');
  }

  const hashtagsInput = document.getElementById('detailsHashtags');
  const hashtagChipRow = document.getElementById('hashtagChipRow');
  function renderHashtagChips() {
    if (!hashtagChipRow || !hashtagsInput) return;
    const tags = hashtagsInput.value.split(/[\s,]+/).map((t) => t.trim()).filter(Boolean);
    hashtagChipRow.innerHTML = tags.map((t) => `<span class="hashtag-chip">${t.startsWith('#') ? t : `#${t}`}</span>`).join('');
  }
  hashtagsInput?.addEventListener('input', renderHashtagChips);

  const categorySelect = document.getElementById('categorySelect');
  if (categorySelect) categorySelect.innerHTML = CATEGORIES.map((c) => `<option value="${c.id}">${c.name}</option>`).join('');

  const challengeSelect = document.getElementById('challengeSelect');
  if (challengeSelect) {
    challengeSelect.innerHTML = CHALLENGES.map((c) => `<option value="${c.id}">${c.title}</option>`).join('');
    challengeSelect.value = initialChallenge.id;
  }

  function syncSelectedChallengeCard() {
    const c = CHALLENGES.find((x) => x.id === challengeSelect.value) || initialChallenge;
    fillChallengeSummary(c);
    if (categorySelect) {
      const match = CATEGORIES.find((cat) => cat.name === c.category);
      if (match) categorySelect.value = match.id;
    }
  }
  challengeSelect?.addEventListener('change', syncSelectedChallengeCard);
  syncSelectedChallengeCard();

  const titleInput = document.getElementById('detailsTitle');
  const confirmCheck = document.getElementById('detailsConfirmCheck');
  const submitBtn = document.getElementById('submitDetailsBtn');
  function updateSubmitState() {
    const hasTitle = !!titleInput && titleInput.value.trim().length > 0;
    const confirmed = !!confirmCheck && confirmCheck.checked;
    if (submitBtn) submitBtn.disabled = !(hasTitle && confirmed);
  }
  titleInput?.addEventListener('input', updateSubmitState);
  confirmCheck?.addEventListener('change', updateSubmitState);
  updateSubmitState();

  document.getElementById('saveDetailsDraftBtn')?.addEventListener('click', () => {
    window.location.href = `studio-drafts.html?id=${initialChallenge.id}`;
  });

  submitBtn?.addEventListener('click', () => {
    if (submitBtn.disabled) return;
    // TODO(api): POST title/description/category/hashtags + challenge id + video asset.
    const chosenId = challengeSelect ? challengeSelect.value : initialChallenge.id;
    window.location.href = `studio-upload.html?id=${chosenId}`;
  });
}

/* ---------- 20. Upload / Submission Progress Screen ---------- */
function hydrateStudioUpload() {
  const challenge = currentChallenge();
  const steps = ['Compressing video', 'Generating thumbnail', 'Checking content', 'Submitting entry'];
  const stepsEl = document.getElementById('uploadSteps');
  const barEl = document.getElementById('uploadProgressBar');
  const pctEl = document.getElementById('uploadPercent');

  let stepIndex = 0;
  let pct = 0;

  function render() {
    stepsEl.innerHTML = steps.map((label, i) => uploadStepHtml(label, i < stepIndex ? 'done' : i === stepIndex ? 'active' : 'pending')).join('');
    if (barEl) barEl.style.width = `${pct}%`;
    if (pctEl) pctEl.textContent = `${pct}%`;
  }

  render();
  const interval = setInterval(() => {
    pct = Math.min(100, pct + 4);
    stepIndex = Math.min(steps.length - 1, Math.floor((pct / 100) * steps.length));
    render();
    if (pct >= 100) {
      clearInterval(interval);
      stepIndex = steps.length;
      render();
      setTimeout(() => { window.location.href = `studio-success.html?id=${challenge.id}`; }, 500);
    }
  }, 160);
}

/* ---------- 21. Submission Success Screen ---------- */
function hydrateStudioSuccess() {
  const challenge = currentChallenge();
  fillChallengeSummary(challenge);

  document.getElementById('viewEntryBtn')?.addEventListener('click', () => {
    window.location.href = `challenge-detail.html?id=${challenge.id}`;
  });
  document.getElementById('backToHomeBtn')?.addEventListener('click', () => {
    window.location.href = 'home.html';
  });
  document.getElementById('joinMoreBtn')?.addEventListener('click', () => {
    window.location.href = 'categories.html';
  });
}

/* =========================================================
   Reels & Video Feed (module 4) — pure UI logic + static-data
   rendering, same conventions as the rest of app.js. Ratings,
   likes, saves and follows are in-memory only (no backend).
   ========================================================= */

function currentReel() {
  const params = new URLSearchParams(location.search);
  return REELS.find((r) => r.id === (params.get('id') || 'r1')) || REELS[0];
}

function reelCategoryTint(category) {
  return {
    Dance: '#E01D5C', Comedy: '#3450D6', Fitness: '#1FAE6A',
    Singing: '#FF3D77', Magic: '#7420E8', Art: '#E8631F',
  }[category] || 'var(--color-purple)';
}

/* ---------- reusable templates ---------- */
function creatorInfoRowHtml(reel, opts = {}) {
  const identityInner = `
    <img class="creator-info-row__avatar" src="${reel.avatarUrl}" alt="${reel.creator}" loading="lazy" onerror="imgFallback(this)">
    <div class="creator-info-row__body">
      <span class="creator-info-row__handle">${reel.handle}${reel.verified ? ICONS.checkCircle : ''}</span>
      ${opts.subtitle ? `<span class="creator-info-row__subtitle">${opts.subtitle}</span>` : ''}
    </div>`;
  // opts.linkProfile makes the avatar+handle tappable to the Public Profile
  // screen. Only used where creatorInfoRowHtml() isn't already nested inside
  // another <a> (e.g. Video Detail's creator card) to avoid invalid nested anchors.
  let identity = identityInner;
  if (opts.linkProfile) {
    const creator = CREATORS.find((u) => u.handle === reel.handle);
    identity = creator
      ? `<a class="creator-info-row__identity" href="public-profile.html?id=${creator.id}">${identityInner}</a>`
      : `<a class="creator-info-row__identity" href="#" onclick="return comingSoon(event)">${identityInner}</a>`;
  }
  return `
  <div class="creator-info-row">
    ${identity}
    ${opts.showFollow ? `<button class="follow-btn" type="button" id="followBtn">Follow</button>` : ''}
  </div>`;
}

function commentItemHtml(c) {
  return `
  <div class="comment-item">
    <img class="comment-item__avatar" src="${c.avatarUrl}" alt="${c.username}" loading="lazy" onerror="imgFallback(this)">
    <div class="comment-item__body">
      <div class="comment-item__row">
        <span class="comment-item__username">${c.username}</span>
        <span class="comment-item__dot"></span>
        <span class="comment-item__time">${c.time}</span>
      </div>
      <p class="comment-item__text">${c.text}</p>
      <div class="comment-item__actions">
        <button class="comment-item__like" type="button" data-like-comment="${c.id}">${ICONS.heart}<span>${c.likes}</span></button>
        <button class="comment-item__reply" type="button">Reply</button>
      </div>
    </div>
  </div>`;
}

function shareOptionItemHtml(opt) {
  const icons = { link: ICONS.link, whatsapp: ICONS.whatsapp, sms: ICONS.sms, email: ICONS.email, share: ICONS.shareIcon };
  return `
  <button class="share-option-item" type="button" data-share="${opt.id}">
    <span class="share-option-item__icon">${icons[opt.icon] || ICONS.shareIcon}</span>
    <span class="share-option-item__label">${opt.label}</span>
  </button>`;
}

function reportReasonItemHtml(reason) {
  return `
  <label class="report-reason-item">
    <input type="radio" name="reportReason" value="${reason.id}">
    <span class="report-reason-item__dot"></span>
    <span class="report-reason-item__label">${reason.label}</span>
  </label>`;
}

/* ---------- 22. Reels Feed Screen ---------- */
function reelFeedCardHtml(reel, index) {
  return `
  <div class="reel-card" data-reel-id="${reel.id}">
    <img class="reel-card__bg" src="${reel.imageUrl}" alt="${reel.title}" loading="lazy" onerror="imgFallback(this)">
    <div class="reel-card__scrim"></div>
    <span class="reel-card__category" style="background:${reelCategoryTint(reel.category)}">${reel.category}</span>

    <div class="reel-card__actions">
      <button class="reel-action-btn" type="button" data-action="like" data-reel="${reel.id}">
        <span class="reel-action-btn__icon">${ICONS.heart}</span>
        <span class="reel-action-btn__count" data-like-count>${reel.likes}</span>
      </button>
      <a class="reel-action-btn" href="comments.html?id=${reel.id}">
        <span class="reel-action-btn__icon">${ICONS.comment}</span>
        <span class="reel-action-btn__count">${reel.comments}</span>
      </a>
      <a class="reel-action-btn" href="share-report.html?id=${reel.id}">
        <span class="reel-action-btn__icon">${ICONS.shareIcon}</span>
        <span class="reel-action-btn__count">${reel.shares}</span>
      </a>
      <button class="reel-action-btn" type="button" data-action="save" data-reel="${reel.id}">
        <span class="reel-action-btn__icon">${ICONS.bookmark}</span>
        <span class="reel-action-btn__count">Save</span>
      </button>
      <button class="reel-action-btn reel-action-btn--rate" type="button" data-action="rate" data-reel="${reel.id}">
        <span class="reel-action-btn__icon">${ICONS.star}</span>
        <span class="reel-action-btn__count">Rate</span>
      </button>
    </div>

    <a class="reel-card__body" href="video-detail.html?id=${reel.id}">
      ${creatorInfoRowHtml(reel)}
      <span class="reel-card__challenge">${ICONS.trophy}<span>${(CHALLENGES.find((c) => c.id === reel.challengeId) || {}).title || ''}</span></span>
      <span class="reel-card__music">${ICONS.musicNote}<span>${reel.musicName}</span></span>
      <p class="reel-card__caption">${reel.caption}</p>
      <span class="reel-card__views">${ICONS.eyeSolid}<span>${reel.views} views</span></span>
    </a>
  </div>`;
}

function reelAdCardHtml() {
  return `
  <div class="reel-card reel-card--ad">
    <img class="reel-card__bg" src="https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=700&h=1200&q=80&auto=format&fit=crop" alt="Sponsored" onerror="imgFallback(this)">
    <div class="reel-card__scrim"></div>
    <span class="reel-card__ad-tag">Ad</span>
    <div class="reel-card__ad-body">
      <p class="reel-card__ad-headline">Go Prime — Ad-Free Viewing</p>
      <p class="reel-card__ad-sub">Remove ads and get the diamond badge</p>
      <span class="reel-card__ad-cta">Upgrade Now</span>
    </div>
  </div>`;
}

function hydrateReelsFeed() {
  const scroll = document.getElementById('reelsScroll');
  if (!scroll) return;
  const cards = REELS.map((r, i) => reelFeedCardHtml(r, i));
  cards.splice(3, 0, reelAdCardHtml());
  scroll.innerHTML = cards.join('');

  const openRatingPanel = initReelRatingPanel();

  const likedIds = new Set();
  const savedIds = new Set();
  scroll.addEventListener('click', (e) => {
    const likeBtn = e.target.closest('[data-action="like"]');
    if (likeBtn) {
      const id = likeBtn.dataset.reel;
      const icon = likeBtn.querySelector('.reel-action-btn__icon');
      const isLiked = likedIds.has(id);
      if (isLiked) { likedIds.delete(id); icon.innerHTML = ICONS.heart; likeBtn.classList.remove('is-active'); }
      else { likedIds.add(id); icon.innerHTML = ICONS.heartFilled; likeBtn.classList.add('is-active'); }
      return;
    }
    const saveBtn = e.target.closest('[data-action="save"]');
    if (saveBtn) {
      const id = saveBtn.dataset.reel;
      const icon = saveBtn.querySelector('.reel-action-btn__icon');
      const label = saveBtn.querySelector('.reel-action-btn__count');
      const isSaved = savedIds.has(id);
      if (isSaved) { savedIds.delete(id); icon.innerHTML = ICONS.bookmark; label.textContent = 'Save'; saveBtn.classList.remove('is-active'); }
      else { savedIds.add(id); icon.innerHTML = ICONS.bookmarkFilled; label.textContent = 'Saved'; saveBtn.classList.add('is-active'); }
      return;
    }
    const rateBtn = e.target.closest('[data-action="rate"]');
    if (rateBtn) openRatingPanel?.(rateBtn.dataset.reel);
  });
}

/* In-page bottom rating panel (Reels feed only) — opens over the current
   reel card without navigating away, keeping the reel/video visible behind it.
   Returns the `open(reelId)` function, or null if the panel markup isn't present. */
function initReelRatingPanel() {
  const overlay = document.getElementById('reelRatingOverlay');
  const panel = document.getElementById('reelRatingPanel');
  const form = document.getElementById('reelRatingForm');
  const success = document.getElementById('reelRatingSuccess');
  const slider = document.getElementById('reelRatingSlider');
  const bubble = document.getElementById('reelRatingBubble');
  const bubbleValue = document.getElementById('reelRatingBubbleValue');
  const scoreEl = document.getElementById('reelRatingScoreValue');
  const impactEl = document.getElementById('reelRatingImpact');
  const submitBtn = document.getElementById('reelRatingSubmitBtn');
  const doneBtn = document.getElementById('reelRatingDoneBtn');
  const closeBtn = document.getElementById('reelRatingCloseBtn');
  if (!overlay || !panel || !slider) return null;

  function positionBubble() {
    const min = Number(slider.min), max = Number(slider.max);
    const pct = (Number(slider.value) - min) / (max - min);
    const thumbSize = 22;
    const trackWidth = slider.offsetWidth;
    bubble.style.left = `${thumbSize / 2 + pct * (trackWidth - thumbSize)}px`;
  }
  function updateFromSlider() {
    const val = Number(slider.value).toFixed(1);
    bubbleValue.textContent = val;
    scoreEl.textContent = val;
    positionBubble();
  }

  function open(reelId) {
    const reel = REELS.find((r) => r.id === reelId);
    if (!reel) return;
    if (impactEl) impactEl.textContent = String(Math.round(reel.talentScore * 6));
    slider.value = '5';
    form.classList.remove('hidden');
    success.classList.add('hidden');
    overlay.classList.remove('hidden');
    requestAnimationFrame(updateFromSlider);
    panel.dataset.reelId = reelId;
  }
  function close() {
    overlay.classList.add('hidden');
  }

  slider.addEventListener('input', updateFromSlider);
  window.addEventListener('resize', positionBubble, { passive: true });

  closeBtn?.addEventListener('click', close);
  overlay.addEventListener('click', (e) => { if (e.target === overlay) close(); });

  submitBtn?.addEventListener('click', () => {
    const finalScore = Number(slider.value).toFixed(1);
    // TODO(api): POST { reelId: panel.dataset.reelId, score: finalScore } to the ratings endpoint.
    const successScore = document.getElementById('reelRatingSuccessScore');
    if (successScore) successScore.textContent = finalScore;
    form.classList.add('hidden');
    success.classList.remove('hidden');
  });

  doneBtn?.addEventListener('click', close);

  return open;
}

/* ---------- 23. Video Detail Screen ---------- */
function hydrateVideoDetail() {
  const reel = currentReel();
  const challenge = CHALLENGES.find((c) => c.id === reel.challengeId);

  document.querySelectorAll('[data-field="reelPoster"]').forEach((el) => el.setAttribute('src', reel.imageUrl));
  document.querySelectorAll('[data-field="reelCategory"]').forEach((el) => { el.textContent = reel.category; });
  document.querySelectorAll('[data-field="reelCaption"]').forEach((el) => { el.textContent = reel.caption; });
  document.querySelectorAll('[data-field="reelViews"]').forEach((el) => { el.textContent = reel.views; });
  document.querySelectorAll('[data-field="reelLikes"]').forEach((el) => { el.textContent = reel.likes; });
  document.querySelectorAll('[data-field="reelComments"]').forEach((el) => { el.textContent = reel.comments; });
  document.querySelectorAll('[data-field="reelShares"]').forEach((el) => { el.textContent = reel.shares; });
  document.querySelectorAll('[data-field="reelTalentScore"]').forEach((el) => { el.textContent = reel.talentScore.toFixed(1); });
  if (challenge) document.querySelectorAll('[data-field="reelChallengeName"]').forEach((el) => { el.textContent = challenge.title; });

  const creatorRow = document.getElementById('creatorInfoRow');
  if (creatorRow) creatorRow.innerHTML = creatorInfoRowHtml(reel, { subtitle: `${reel.views} views`, showFollow: true, linkProfile: true });

  const playBtn = document.getElementById('detailPlayBtn');
  const stage = document.getElementById('detailVideoStage');
  playBtn?.addEventListener('click', () => {
    const isPlaying = stage.classList.toggle('is-playing');
    playBtn.innerHTML = isPlaying ? ICONS.pause : '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
  });

  document.getElementById('followBtn')?.addEventListener('click', function () {
    this.classList.toggle('is-following');
    this.textContent = this.classList.contains('is-following') ? 'Following' : 'Follow';
  });

  document.getElementById('rateThisTalentBtn')?.addEventListener('click', () => {
    window.location.href = `talent-rating.html?id=${reel.id}`;
  });
  document.getElementById('viewChallengeBtn')?.addEventListener('click', () => {
    if (challenge) window.location.href = `challenge-detail.html?id=${challenge.id}`;
  });
  document.getElementById('detailCommentBtn')?.addEventListener('click', () => { window.location.href = `comments.html?id=${reel.id}`; });
  document.getElementById('detailShareBtn')?.addEventListener('click', () => { window.location.href = `share-report.html?id=${reel.id}`; });

  const relatedEl = document.getElementById('relatedReels');
  if (relatedEl) {
    const related = REELS.filter((r) => r.id !== reel.id);
    relatedEl.innerHTML = related.map(reelThumbHtml).join('');
  }
}

/* ---------- 24. Comments Screen ---------- */
function hydrateComments() {
  const reel = currentReel();
  const list = document.getElementById('commentsList');
  const countEl = document.getElementById('commentsCount');
  const sortBar = document.getElementById('commentsSort');
  let sortMode = 'top';

  function render() {
    const comments = (COMMENTS[reel.id] || []).slice();
    if (sortMode === 'top') comments.sort((a, b) => b.likes - a.likes);
    if (countEl) countEl.textContent = `${comments.length} comment${comments.length === 1 ? '' : 's'}`;
    if (list) list.innerHTML = comments.length
      ? comments.map(commentItemHtml).join('')
      : `<p class="empty-note">No comments yet. Be the first to comment.</p>`;
  }
  render();

  sortBar?.addEventListener('click', (e) => {
    const btn = e.target.closest('.comments-sort__btn');
    if (!btn) return;
    sortMode = btn.dataset.sort;
    sortBar.querySelectorAll('.comments-sort__btn').forEach((b) => b.classList.toggle('is-active', b === btn));
    render();
  });

  list?.addEventListener('click', (e) => {
    const likeBtn = e.target.closest('[data-like-comment]');
    if (!likeBtn) return;
    const isLiked = likeBtn.classList.toggle('is-liked');
    const countSpan = likeBtn.querySelector('span');
    const current = parseInt(countSpan.textContent, 10) || 0;
    countSpan.textContent = String(current + (isLiked ? 1 : -1));
  });

  const input = document.getElementById('commentInput');
  const sendBtn = document.getElementById('commentSendBtn');
  function postComment() {
    const text = input.value.trim();
    if (!text) return;
    const newComment = { id: `local${Date.now()}`, avatarUrl: 'https://i.pravatar.cc/64?u=you', username: '@you', text, time: 'now', likes: 0 };
    (COMMENTS[reel.id] = COMMENTS[reel.id] || []).unshift(newComment);
    input.value = '';
    render();
  }
  sendBtn?.addEventListener('click', postComment);
  input?.addEventListener('keydown', (e) => { if (e.key === 'Enter') postComment(); });
}

/* ---------- 25. Talent Rating Modal ---------- */
function hydrateTalentRating() {
  const reel = currentReel();

  document.querySelectorAll('[data-field="reelPoster"]').forEach((el) => el.setAttribute('src', reel.imageUrl));
  document.querySelectorAll('[data-field="reelAvatar"]').forEach((el) => el.setAttribute('src', reel.avatarUrl));
  document.querySelectorAll('[data-field="reelHandle"]').forEach((el) => { el.textContent = reel.handle; });
  document.querySelectorAll('[data-field="reelLikes"]').forEach((el) => { el.textContent = reel.likes; });
  document.querySelectorAll('[data-field="reelComments"]').forEach((el) => { el.textContent = reel.comments; });
  document.querySelectorAll('[data-field="reelShares"]').forEach((el) => { el.textContent = reel.shares; });
  // Dummy "impact" stat derived from the talent's existing score, purely for
  // visual interest on this modal — not tied to any real scoring endpoint.
  document.querySelectorAll('[data-field="ratingImpact"]').forEach((el) => { el.textContent = String(Math.round(reel.talentScore * 6)); });

  const slider = document.getElementById('ratingSlider');
  const bubble = document.getElementById('ratingBubble');
  const bubbleValue = document.getElementById('ratingBubbleValue');
  const scoreEl = document.getElementById('ratingScoreValue');
  const submitBtn = document.getElementById('submitRatingBtn');
  const formSection = document.getElementById('ratingFormSection');
  const successSection = document.getElementById('ratingSuccessSection');

  function positionBubble() {
    if (!slider || !bubble) return;
    const min = Number(slider.min), max = Number(slider.max);
    const pct = (Number(slider.value) - min) / (max - min);
    const thumbSize = 22;
    const trackWidth = slider.offsetWidth;
    const leftPx = thumbSize / 2 + pct * (trackWidth - thumbSize);
    bubble.style.left = `${leftPx}px`;
  }

  function updateFromSlider() {
    if (!slider) return;
    const val = Number(slider.value).toFixed(1);
    if (bubbleValue) bubbleValue.textContent = val;
    if (scoreEl) scoreEl.textContent = val;
    positionBubble();
  }

  slider?.addEventListener('input', updateFromSlider);
  window.addEventListener('resize', positionBubble, { passive: true });
  requestAnimationFrame(updateFromSlider);

  submitBtn?.addEventListener('click', () => {
    const finalScore = slider ? Number(slider.value).toFixed(1) : '0.0';
    // TODO(api): POST { reelId: reel.id, score: finalScore } to the ratings endpoint.
    formSection?.classList.add('hidden');
    successSection?.classList.remove('hidden');
    const successScore = document.getElementById('ratingSuccessScore');
    if (successScore) successScore.textContent = finalScore;
  });

  document.getElementById('ratingBackToFeedBtn')?.addEventListener('click', () => {
    window.location.href = `video-detail.html?id=${reel.id}`;
  });
}

/* ---------- 26. Share / Report Options Screen ---------- */
function hydrateShareReport() {
  const reel = currentReel();

  const shareGrid = document.getElementById('shareOptionsGrid');
  if (shareGrid) shareGrid.innerHTML = SHARE_OPTIONS.map(shareOptionItemHtml).join('');
  shareGrid?.addEventListener('click', (e) => {
    const btn = e.target.closest('.share-option-item');
    if (!btn) return;
    // TODO(api): trigger the real native share sheet / copy-to-clipboard here.
    btn.classList.add('is-shared');
    setTimeout(() => btn.classList.remove('is-shared'), 900);
  });

  const reportList = document.getElementById('reportReasonList');
  if (reportList) reportList.innerHTML = REPORT_REASONS.map(reportReasonItemHtml).join('');

  const reportBtn = document.getElementById('submitReportBtn');
  reportList?.addEventListener('change', () => { if (reportBtn) reportBtn.disabled = false; });
  reportBtn?.addEventListener('click', () => {
    if (reportBtn.disabled) return;
    // TODO(api): POST { reelId: reel.id, reason: <selected> } to the moderation endpoint.
    const note = document.getElementById('reportConfirmNote');
    note?.classList.remove('hidden');
    reportBtn.disabled = true;
    reportBtn.textContent = 'Reported';
  });
}

/* =========================================================
   Search & Discovery / Leaderboard / Profile (modules 5-7)
   ========================================================= */

function verifiedBadgeHtml() {
  return `<span class="verified-badge">${ICONS.verified}</span>`;
}
function primeBadgeHtml() {
  return `<span class="prime-badge">${ICONS.crown}<span>Prime</span></span>`;
}
function currentUser() {
  return CREATORS.find((u) => u.id === CURRENT_USER_ID) || CREATORS[0];
}
function profileUserFromQuery() {
  const params = new URLSearchParams(location.search);
  return CREATORS.find((u) => u.id === (params.get('id') || 'u1')) || CREATORS[0];
}

/* ---------- reusable result / grid cards ---------- */
function userResultCardHtml(u) {
  return `
  <a class="user-result-card" href="public-profile.html?id=${u.id}">
    <img class="user-result-card__avatar" src="${u.avatarUrl}" alt="${u.name}" loading="lazy" onerror="imgFallback(this)">
    <div class="user-result-card__body">
      <span class="user-result-card__name">${u.name}${u.verified ? verifiedBadgeHtml() : ''}</span>
      <span class="user-result-card__meta">${u.category} · ${u.followers} followers</span>
    </div>
    <span class="user-result-card__score">${ICONS.star}${u.talentScore.toFixed(1)}</span>
  </a>`;
}

function videoResultCardHtml(reel) {
  return `
  <a class="video-result-card" href="video-detail.html?id=${reel.id}">
    <div class="video-result-card__media">
      <img src="${reel.imageUrl}" alt="${reel.title}" loading="lazy" onerror="imgFallback(this)">
      <span class="video-result-card__category" style="background:${reelCategoryTint(reel.category)}">${reel.category}</span>
      <span class="video-result-card__play">${ICONS.play}</span>
    </div>
    <div class="video-result-card__body">
      <span class="video-result-card__creator">${reel.handle}${reel.verified ? verifiedBadgeHtml() : ''}</span>
      <div class="video-result-card__meta">
        <span>${ICONS.eyeSolid}${reel.views}</span>
        <span>${ICONS.star}${reel.talentScore.toFixed(1)}</span>
      </div>
    </div>
  </a>`;
}

function challengeResultCardHtml(c) {
  const remaining = daysRemaining(c.endDate);
  const dayLabel = c.status === 'completed' ? `Ended ${formatDate(c.endDate)}` : remaining > 0 ? `${remaining}d left` : 'Ending today';
  return `
  <a class="challenge-result-card" href="challenge-detail.html?id=${c.id}">
    <img src="${c.imageUrl}" alt="${c.title}" loading="lazy" onerror="imgFallback(this)">
    <div class="challenge-result-card__body">
      <span class="challenge-result-card__title">${c.title}</span>
      <div class="challenge-result-card__meta">
        <span>${ICONS.prize}${c.prize}</span>
        <span>${ICONS.calendar}${dayLabel}</span>
      </div>
    </div>
    <span class="challenge-result-card__cta">${c.status === 'completed' ? 'View' : 'Join'}</span>
  </a>`;
}

function categoryResultCardHtml(cat) {
  return `
  <a class="category-result-card" href="challenges.html?category=${cat.id}">
    <img src="${cat.imageUrl}" alt="${cat.name}" loading="lazy" onerror="imgFallback(this)">
    <div class="category-result-card__overlay"></div>
    <span class="category-result-card__name">${cat.name}</span>
    <span class="category-result-card__count">${cat.count} live</span>
  </a>`;
}

/* ---------- Search Screen only: premium discovery cards ---------- */
function discoverCreatorCardHtml(u) {
  return `
  <a class="discover-creator-card" href="public-profile.html?id=${u.id}">
    <div class="discover-creator-card__top">
      <img src="${u.avatarUrl}" alt="${u.name}" loading="lazy" onerror="imgFallback(this)">
      <span class="discover-creator-card__score">${ICONS.star}${u.talentScore.toFixed(1)}</span>
    </div>
    <span class="discover-creator-card__name">${u.name}${u.verified ? verifiedBadgeHtml() : ''}</span>
    <span class="discover-creator-card__meta">${u.category} · ${u.followers}</span>
    <span class="discover-creator-card__btn">View Profile</span>
  </a>`;
}

function discoverChallengeCardHtml(c) {
  const remaining = daysRemaining(c.endDate);
  const dayLabel = c.status === 'completed' ? 'Ended' : remaining > 0 ? `${remaining}d left` : 'Ending today';
  return `
  <a class="discover-challenge-card" href="challenge-detail.html?id=${c.id}">
    <div class="discover-challenge-card__media">
      <img src="${c.imageUrl}" alt="${c.title}" loading="lazy" onerror="imgFallback(this)">
      <span class="discover-challenge-card__badge">${dayLabel}</span>
    </div>
    <span class="discover-challenge-card__title">${c.title}</span>
    <span class="discover-challenge-card__prize">${ICONS.prize}${c.prize}</span>
    <span class="discover-challenge-card__cta">Join Challenge</span>
  </a>`;
}

function profileVideoThumbHtml(reel) {
  const categoryTint = {
    Dance: '#E01D5C', Comedy: '#3450D6', Fitness: '#1FAE6A',
    Singing: '#FF3D77', Magic: '#7420E8', Art: '#E8631F',
  }[reel.category] || 'var(--color-purple)';
  return `
  <a class="reel-thumb" href="video-detail.html?id=${reel.id}">
    <img src="${reel.imageUrl}" alt="${reel.title}" loading="lazy" onerror="imgFallback(this)">
    ${reel.category ? `<span class="reel-thumb__category" style="background:${categoryTint}">${reel.category}</span>` : ''}
    <div class="reel-thumb__info">
      <span class="reel-thumb__meta">${ICONS.play}${reel.views}</span>
      <span class="reel-thumb__creator-row">
        ${reel.avatarUrl ? `<img class="reel-thumb__avatar" src="${reel.avatarUrl}" alt="">` : ''}
        <span class="reel-thumb__handle">${reel.handle || reel.creator}</span>
        ${reel.verified ? `<svg class="reel-thumb__verified" viewBox="0 0 24 24" fill="currentColor"><path d="m9 12 2 2 4-4M12 2l2.4 1.4L17 3l.6 2.6L20 7l-1 2.4L20 12l-2 1.6L17 16l-2.6.4L12 18l-2.4-1.6L7 16l-.6-2.4L4 12l1-2.6L4 7l3-1.4L7 3l2.6.4Z"/></svg>` : ''}
      </span>
    </div>
  </a>`;
}

function trendingVideoCardHtml(reel, featured) {
  return `
  <a class="trending-video-card${featured ? ' trending-video-card--featured' : ''}" href="video-detail.html?id=${reel.id}">
    <img src="${reel.imageUrl}" alt="${reel.title}" loading="lazy" onerror="imgFallback(this)">
    <div class="trending-video-card__scrim"></div>
    <span class="trending-video-card__category" style="background:${reelCategoryTint(reel.category)}">${reel.category}</span>
    <span class="trending-video-card__play">${ICONS.play}</span>
    <span class="trending-video-card__score">${ICONS.star}${reel.talentScore.toFixed(1)}</span>
    <div class="trending-video-card__body">
      <span class="trending-video-card__views">${ICONS.eyeSolid}${reel.views}</span>
      <span class="trending-video-card__creator">
        ${reel.avatarUrl ? `<img class="trending-video-card__avatar" src="${reel.avatarUrl}" alt="" onerror="imgFallback(this)">` : ''}
        <span>${reel.handle}</span>${reel.verified ? verifiedBadgeHtml() : ''}
      </span>
    </div>
  </a>`;
}

function videoGridCardHtml(v) {
  const statusLabels = { live: 'Live', under_review: 'Under Review', draft: 'Draft', rejected: 'Rejected' };
  const isDraft = v.status === 'draft';
  const isLive = v.status === 'live';
  const mediaHref = isDraft ? `studio-preview.html?draftId=${v.draftId || ''}` : isLive ? 'video-detail.html?id=r1' : '#';
  const mediaAttrs = !isDraft && !isLive ? ' onclick="return comingSoon(event)"' : '';
  return `
  <div class="video-grid-card">
    <a class="video-grid-card__media" href="${mediaHref}"${mediaAttrs}>
      <img src="${v.thumbnailUrl}" alt="${v.challengeTitle}" loading="lazy" onerror="imgFallback(this)">
      <span class="video-grid-card__status video-grid-card__status--${v.status}">${statusLabels[v.status]}</span>
      ${v.talentScore != null ? `<span class="video-grid-card__score">${ICONS.star}${v.talentScore.toFixed(1)}</span>` : ''}
    </a>
    <div class="video-grid-card__body">
      <span class="video-grid-card__title">${v.challengeTitle}</span>
      <div class="video-grid-card__meta">
        <span>${ICONS.eyeSolid}${v.views}</span>
        <span>${ICONS.heart}${v.likes}</span>
        <span class="video-grid-card__date">${formatDate(v.date)}</span>
      </div>
      ${v.status === 'rejected' && v.rejectReason ? `<p class="video-grid-card__reject">${v.rejectReason}</p>` : ''}
      <div class="video-grid-card__actions">
        ${isDraft
          ? `<a class="video-grid-card__action" href="studio-preview.html?draftId=${v.draftId || ''}">${ICONS.edit}<span>Continue Draft</span></a>`
          : `<a class="video-grid-card__action" href="${mediaHref}"${mediaAttrs}>${ICONS.eyeSolid}<span>View</span></a>`}
        <a class="video-grid-card__action" href="share-report.html?id=r1">${ICONS.shareIcon}<span>Share</span></a>
      </div>
    </div>
  </div>`;
}

function badgeCardHtml(b) {
  return `
  <div class="badge-card${b.earned ? ' is-earned' : ' is-locked'}">
    <span class="badge-card__icon">${b.earned ? quickActionIconSvg(b.icon) : ICONS.lock}</span>
    <span class="badge-card__name">${b.name}</span>
    <span class="badge-card__desc">${b.description}</span>
  </div>`;
}

function leaderboardRowHtml(u, rank) {
  return `
  <a class="leaderboard-row${rank <= 3 ? ' is-top' : ''}${u.isCurrentUser ? ' is-you' : ''}" href="public-profile.html?id=${u.id}">
    <span class="leaderboard-row__rank">${rank}</span>
    <img class="leaderboard-row__avatar" src="${u.avatarUrl}" alt="${u.name}" loading="lazy" onerror="imgFallback(this)">
    <div class="leaderboard-row__body">
      <span class="leaderboard-row__name">${u.name}${u.verified ? verifiedBadgeHtml() : ''}</span>
      <span class="leaderboard-row__meta">${u.category} · ${u.votes.toLocaleString()} votes</span>
    </div>
    <span class="leaderboard-row__score">${ICONS.star}${u.talentScore.toFixed(1)}</span>
  </a>`;
}

/* ---------- 27. Search Screen ---------- */
function hydrateSearch() {
  const recentEl = document.getElementById('recentSearches');
  if (recentEl) {
    recentEl.innerHTML = RECENT_SEARCHES.map((q) => `
      <button class="recent-search-chip" type="button" data-query="${q}">
        <span class="recent-search-chip__icon">${ICONS.clock}</span>
        <span class="recent-search-chip__text">${q}</span>
        <span class="recent-search-chip__arrow">${ICONS.chevronRight}</span>
      </button>`).join('');
  }
  const popularEl = document.getElementById('popularSearchChips');
  if (popularEl) {
    popularEl.innerHTML = POPULAR_SEARCHES.map((label) => `<button class="popular-chip" type="button" data-query="${label}">${label}</button>`).join('');
  }
  const creatorsEl = document.getElementById('suggestedCreators');
  if (creatorsEl) creatorsEl.innerHTML = CREATORS.filter((c) => !c.isCurrentUser).slice(0, 5).map(discoverCreatorCardHtml).join('');

  const challengesEl = document.getElementById('suggestedChallenges');
  if (challengesEl) challengesEl.innerHTML = CHALLENGES.filter((c) => c.status === 'active').slice(0, 3).map(discoverChallengeCardHtml).join('');

  const categoriesEl = document.getElementById('trendingCategories');
  if (categoriesEl) categoriesEl.innerHTML = CATEGORIES.slice(0, 6).map(categoryResultCardHtml).join('');

  const input = document.getElementById('searchInput');
  function goToResults(q) {
    const query = (q || input?.value || '').trim();
    window.location.href = `search-results.html?q=${encodeURIComponent(query)}`;
  }
  document.getElementById('searchForm')?.addEventListener('submit', (e) => { e.preventDefault(); goToResults(); });
  document.querySelectorAll('[data-query]').forEach((el) => {
    el.addEventListener('click', () => goToResults(el.dataset.query));
  });
}

/* ---------- 28. Search Results Screen ---------- */
function hydrateSearchResults() {
  const params = new URLSearchParams(location.search);
  const query = params.get('q') || '';
  const input = document.getElementById('searchInput');
  if (input) input.value = query;

  const q = query.trim().toLowerCase();
  const users = (q ? CREATORS.filter((u) => u.name.toLowerCase().includes(q) || u.handle.toLowerCase().includes(q) || u.category.toLowerCase().includes(q)) : CREATORS).filter((u) => !u.isCurrentUser);
  const videos = q ? REELS.filter((r) => r.title.toLowerCase().includes(q) || r.category.toLowerCase().includes(q) || r.handle.toLowerCase().includes(q)) : REELS;
  const challengesList = q ? CHALLENGES.filter((c) => c.title.toLowerCase().includes(q) || c.category.toLowerCase().includes(q)) : CHALLENGES;
  const categoriesList = q ? CATEGORIES.filter((c) => c.name.toLowerCase().includes(q)) : CATEGORIES;

  const tabs = document.querySelectorAll('.results-tab-row .tab-btn');
  const resultsEl = document.getElementById('resultsList');
  const emptyEl = document.getElementById('resultsEmpty');

  function render(tab) {
    let html = '';
    if (tab === 'all') {
      html = users.slice(0, 2).map(userResultCardHtml).join('')
        + videos.slice(0, 2).map(videoResultCardHtml).join('')
        + challengesList.slice(0, 2).map(challengeResultCardHtml).join('')
        + categoriesList.slice(0, 2).map(categoryResultCardHtml).join('');
    } else if (tab === 'users') html = users.map(userResultCardHtml).join('');
    else if (tab === 'videos') html = videos.map(videoResultCardHtml).join('');
    else if (tab === 'challenges') html = challengesList.map(challengeResultCardHtml).join('');
    else if (tab === 'categories') html = categoriesList.map(categoryResultCardHtml).join('');

    if (resultsEl) resultsEl.innerHTML = html;
    if (emptyEl) emptyEl.classList.toggle('hidden', !!html);
  }

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      render(tab.dataset.tab);
    });
  });
  render('all');

  document.getElementById('searchResultsForm')?.addEventListener('submit', (e) => {
    e.preventDefault();
    window.location.href = `search-results.html?q=${encodeURIComponent(input.value.trim())}`;
  });
}

/* ---------- 29. Trending / Popular Videos Screen ---------- */
function hydrateTrendingVideos() {
  const filters = ['Trending', 'Popular', 'Newest', 'Dance', 'Singing', 'Comedy', 'Fitness', 'Magic', 'Art'];
  const filterEl = document.getElementById('trendingFilterChips');
  if (filterEl) filterEl.innerHTML = filters.map((f, i) => `<button class="filter-pill${i === 0 ? ' is-active' : ''}" type="button" data-filter="${f}">${f}</button>`).join('');

  const featured = [...REELS].sort((a, b) => b.talentScore - a.talentScore)[0];
  const featuredEl = document.getElementById('featuredVideo');
  if (featuredEl && featured) featuredEl.innerHTML = trendingVideoCardHtml(featured, true);

  const gridEl = document.getElementById('trendingGrid');
  function render(filter) {
    let list = REELS.filter((r) => r.id !== featured.id);
    if (filter === 'Popular') list = [...list].sort((a, b) => parseFloat(b.likes) - parseFloat(a.likes));
    else if (filter === 'Newest') list = [...list].reverse();
    else if (filter && filter !== 'Trending') list = list.filter((r) => r.category === filter);
    if (gridEl) gridEl.innerHTML = list.map((r) => trendingVideoCardHtml(r, false)).join('');
  }
  render('Trending');

  filterEl?.addEventListener('click', (e) => {
    const btn = e.target.closest('.filter-pill');
    if (!btn) return;
    filterEl.querySelectorAll('.filter-pill').forEach((b) => b.classList.toggle('is-active', b === btn));
    render(btn.dataset.filter);
  });
}

/* ---------- 30. Leaderboard Screen ---------- */
function hydrateLeaderboard() {
  const categories = ['All Categories', 'Dance', 'Singing', 'Comedy', 'Fitness', 'Art'];
  const filterEl = document.getElementById('leaderboardCategoryChips');
  if (filterEl) filterEl.innerHTML = categories.map((c, i) => `<button class="filter-pill${i === 0 ? ' is-active' : ''}" type="button" data-cat="${c}">${c}</button>`).join('');

  const tabs = document.querySelectorAll('.leaderboard-tabs .tab-btn');
  const podiumEl = document.getElementById('leaderboardPodium');
  const listEl = document.getElementById('leaderboardList');
  const yourRankEl = document.getElementById('yourRankCard');

  let activeTab = 'global';
  let activeCategory = 'All Categories';

  function sortValue(u) {
    if (activeTab === 'weekly') return u.votes;
    if (activeTab === 'monthly') return u.challengesWon * 100 + u.talentScore;
    if (activeTab === 'challenge') return u.challengesWon * 100 + u.votes / 1000;
    return u.talentScore;
  }

  function render() {
    let ranked = [...CREATORS].sort((a, b) => sortValue(b) - sortValue(a));
    if (activeCategory !== 'All Categories') ranked = ranked.filter((u) => u.category === activeCategory);

    const top3 = ranked.slice(0, 3);
    if (podiumEl) {
      podiumEl.innerHTML = top3.length
        ? [1, 0, 2].map((i) => {
            const u = top3[i];
            if (!u) return '<span class="podium-spot podium-spot--empty"></span>';
            const place = i + 1;
            return `
            <a class="podium-spot podium-spot--${place}" href="public-profile.html?id=${u.id}">
              ${place === 1 ? `<span class="podium-spot__crown">${ICONS.crown}</span>` : ''}
              <img src="${u.avatarUrl}" alt="${u.name}" onerror="imgFallback(this)">
              <span class="podium-spot__rank">${place}</span>
              <span class="podium-spot__name">${u.name}</span>
              <span class="podium-spot__score">${ICONS.star}${u.talentScore.toFixed(1)}</span>
            </a>`;
          }).join('')
        : `<p class="empty-note">No creators in this category yet.</p>`;
    }

    const rest = ranked.slice(3);
    if (listEl) listEl.innerHTML = rest.map((u, i) => leaderboardRowHtml(u, i + 4)).join('');

    const you = CREATORS.find((u) => u.isCurrentUser);
    if (yourRankEl && you) {
      const fullRanked = [...CREATORS].sort((a, b) => sortValue(b) - sortValue(a));
      const rank = fullRanked.indexOf(you) + 1;
      yourRankEl.innerHTML = `
        <span class="your-rank-card__label">Your Rank</span>
        <div class="your-rank-card__body">
          <span class="your-rank-card__position">#${rank}</span>
          <img src="${you.avatarUrl}" alt="${you.name}" onerror="imgFallback(this)">
          <div class="your-rank-card__meta">
            <strong>${you.name}</strong>
            <span>${you.category}</span>
          </div>
          <span class="your-rank-card__score">${ICONS.star}${you.talentScore.toFixed(1)}</span>
        </div>`;
    }
  }

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      activeTab = tab.dataset.tab;
      render();
    });
  });

  filterEl?.addEventListener('click', (e) => {
    const btn = e.target.closest('.filter-pill');
    if (!btn) return;
    filterEl.querySelectorAll('.filter-pill').forEach((b) => b.classList.toggle('is-active', b === btn));
    activeCategory = btn.dataset.cat;
    render();
  });

  render();
}

/* ---------- 31. My Profile Screen ---------- */
function hydrateMyProfile() {
  const u = currentUser();
  document.querySelectorAll('[data-field="coverUrl"]').forEach((el) => el.setAttribute('src', u.coverUrl));
  document.querySelectorAll('[data-field="avatarUrl"]').forEach((el) => el.setAttribute('src', u.avatarUrl));
  document.querySelectorAll('[data-field="name"]').forEach((el) => { el.textContent = u.name; });
  document.querySelectorAll('[data-field="handle"]').forEach((el) => { el.textContent = u.handle; });
  document.querySelectorAll('[data-field="bio"]').forEach((el) => { el.textContent = u.bio; });
  document.querySelectorAll('[data-field="category"]').forEach((el) => { el.textContent = u.category; });
  document.querySelectorAll('[data-field="videos"]').forEach((el) => { el.textContent = u.videos; });
  document.querySelectorAll('[data-field="likes"]').forEach((el) => { el.textContent = u.likes; });
  document.querySelectorAll('[data-field="talentScore"]').forEach((el) => { el.textContent = u.talentScore.toFixed(1); });
  document.querySelectorAll('[data-field="challengesWon"]').forEach((el) => { el.textContent = u.challengesWon; });
  const primeSlot = document.getElementById('primeBadgeSlot');
  if (primeSlot) primeSlot.innerHTML = u.prime ? primeBadgeHtml() : '';

  const linksEl = document.getElementById('socialLinks');
  if (linksEl) linksEl.innerHTML = u.socialLinks.map((l) => `<a class="social-link-chip" href="${l.url}" onclick="return comingSoon(event)">${ICONS.link}<span>${l.label}</span></a>`).join('');

  const videosEl = document.getElementById('recentVideosGrid');
  if (videosEl) videosEl.innerHTML = MY_VIDEOS.slice(0, 4).map(videoGridCardHtml).join('');

  const badgesEl = document.getElementById('badgesPreview');
  if (badgesEl) badgesEl.innerHTML = BADGES.filter((b) => b.earned).slice(0, 4).map(badgeCardHtml).join('');
}

/* ---------- 32. Public User Profile Screen ---------- */
function hydratePublicProfile() {
  const u = profileUserFromQuery();
  document.querySelectorAll('[data-field="coverUrl"]').forEach((el) => el.setAttribute('src', u.coverUrl));
  document.querySelectorAll('[data-field="avatarUrl"]').forEach((el) => el.setAttribute('src', u.avatarUrl));
  document.querySelectorAll('[data-field="name"]').forEach((el) => { el.textContent = u.name; });
  document.querySelectorAll('[data-field="handle"]').forEach((el) => { el.textContent = u.handle; });
  document.querySelectorAll('[data-field="bio"]').forEach((el) => { el.textContent = u.bio; });
  document.querySelectorAll('[data-field="category"]').forEach((el) => { el.textContent = u.category; });
  document.querySelectorAll('[data-field="videos"]').forEach((el) => { el.textContent = u.videos; });
  document.querySelectorAll('[data-field="likes"]').forEach((el) => { el.textContent = u.likes; });
  document.querySelectorAll('[data-field="talentScore"]').forEach((el) => { el.textContent = u.talentScore.toFixed(1); });
  document.querySelectorAll('[data-field="challengesWon"]').forEach((el) => { el.textContent = u.challengesWon; });
  const verifiedSlot = document.getElementById('verifiedBadgeSlot');
  if (verifiedSlot) verifiedSlot.innerHTML = u.verified ? verifiedBadgeHtml() : '';
  const primeSlot = document.getElementById('primeBadgeSlot');
  if (primeSlot) primeSlot.innerHTML = u.prime ? primeBadgeHtml() : '';

  const matchingReels = REELS.filter((r) => r.handle === u.handle);
  const gridEl = document.getElementById('publicVideoGrid');
  if (gridEl) gridEl.innerHTML = (matchingReels.length ? matchingReels : REELS.slice(0, 3)).map(profileVideoThumbHtml).join('');

  const topReel = (matchingReels.length ? matchingReels : REELS).sort((a, b) => b.talentScore - a.talentScore)[0];
  const topEl = document.getElementById('topVideoCard');
  if (topEl && topReel) topEl.innerHTML = trendingVideoCardHtml(topReel, true);

  const badgesEl = document.getElementById('badgesPreview');
  if (badgesEl) badgesEl.innerHTML = BADGES.filter((b) => b.earned).slice(0, 4).map(badgeCardHtml).join('');

  const followBtn = document.getElementById('followProfileBtn');
  followBtn?.addEventListener('click', function () {
    this.classList.toggle('is-following');
    this.querySelector('span').textContent = this.classList.contains('is-following') ? 'Following' : 'Follow';
  });
  document.getElementById('shareProfileBtn')?.addEventListener('click', (e) => { e.preventDefault(); });
}

/* ---------- 33. Edit Profile Screen ---------- */
function hydrateEditProfile() {
  const u = currentUser();
  const setVal = (id, val) => { const el = document.getElementById(id); if (el) el.value = val; };
  document.querySelectorAll('[data-field="avatarUrl"]').forEach((el) => el.setAttribute('src', u.avatarUrl));
  document.querySelectorAll('[data-field="coverUrl"]').forEach((el) => el.setAttribute('src', u.coverUrl));
  setVal('editFullName', u.name);
  setVal('editUsername', u.handle.replace('@', ''));
  setVal('editBio', u.bio);
  setVal('editCategory', u.category);
  setVal('editSocialLink', u.socialLinks[0]?.url === '#' ? '' : (u.socialLinks[0]?.url || ''));

  const form = document.getElementById('editProfileForm');
  const savedNote = document.getElementById('editSavedNote');
  form?.addEventListener('submit', (e) => {
    e.preventDefault();
    // TODO(api): PATCH the profile fields to the user endpoint.
    savedNote?.classList.remove('hidden');
    setTimeout(() => { window.location.href = 'my-profile.html'; }, 900);
  });
  document.getElementById('editCancelBtn')?.addEventListener('click', () => { history.back(); });
}

/* ---------- 34. My Videos Screen ---------- */
function hydrateMyVideos() {
  const filters = [
    { id: 'all', label: 'All' },
    { id: 'live', label: 'Live' },
    { id: 'under_review', label: 'Under Review' },
    { id: 'draft', label: 'Drafts' },
    { id: 'rejected', label: 'Rejected' },
    { id: 'saved', label: 'Saved Videos' },
  ];
  const filterEl = document.getElementById('myVideosFilterChips');
  if (filterEl) filterEl.innerHTML = filters.map((f, i) => `<button class="filter-pill${i === 0 ? ' is-active' : ''}" type="button" data-status="${f.id}">${f.label}</button>`).join('');

  const gridEl = document.getElementById('myVideosGrid');
  const emptyEl = document.getElementById('myVideosEmpty');
  function render(status) {
    const list = status === 'all' ? MY_VIDEOS : MY_VIDEOS.filter((v) => v.status === status);
    if (gridEl) gridEl.innerHTML = list.map(videoGridCardHtml).join('');
    if (emptyEl) emptyEl.classList.toggle('hidden', list.length > 0);
  }
  render('all');

  filterEl?.addEventListener('click', (e) => {
    const btn = e.target.closest('.filter-pill');
    if (!btn) return;
    filterEl.querySelectorAll('.filter-pill').forEach((b) => b.classList.toggle('is-active', b === btn));
    render(btn.dataset.status);
  });
}

/* ---------- 35. My Achievements / Badges Screen ---------- */
function hydrateAchievements() {
  const earnedCount = BADGES.filter((b) => b.earned).length;
  const levelIndex = Math.min(CREATOR_LEVELS.length - 1, Math.floor(earnedCount / 3));
  const level = CREATOR_LEVELS[levelIndex];
  const nextLevel = CREATOR_LEVELS[levelIndex + 1];

  document.querySelectorAll('[data-field="currentLevel"]').forEach((el) => { el.textContent = level; });
  document.querySelectorAll('[data-field="badgesEarned"]').forEach((el) => { el.textContent = `${earnedCount}/${BADGES.length}`; });
  document.querySelectorAll('[data-field="nextMilestone"]').forEach((el) => { el.textContent = nextLevel ? `${nextLevel} at ${(levelIndex + 1) * 3} badges` : 'Max level reached'; });

  const groups = [
    { id: 'participation', label: 'Participation' },
    { id: 'winner', label: 'Winner' },
    { id: 'referral', label: 'Referral' },
    { id: 'activity', label: 'Activity' },
  ];
  const container = document.getElementById('badgeGroups');
  if (container) {
    container.innerHTML = groups.map((g) => `
      <div class="badge-group">
        <h3 class="badge-group__title">${g.label}</h3>
        <div class="badge-grid">${BADGES.filter((b) => b.category === g.id).map(badgeCardHtml).join('')}</div>
      </div>`).join('');
  }
}

/* ---------- 36. Talent Score / Stats Screen ---------- */
function hydrateTalentStats() {
  const u = currentUser();
  document.querySelectorAll('[data-field="talentScore"]').forEach((el) => { el.textContent = u.talentScore.toFixed(1); });
  document.querySelectorAll('[data-field="avgRating"]').forEach((el) => { el.textContent = (u.talentScore - 0.3).toFixed(1); });
  document.querySelectorAll('[data-field="totalVotes"]').forEach((el) => { el.textContent = u.votes.toLocaleString(); });
  document.querySelectorAll('[data-field="challengesWon"]').forEach((el) => { el.textContent = u.challengesWon; });
  document.querySelectorAll('[data-field="winRate"]').forEach((el) => { el.textContent = `${Math.round((u.challengesWon / u.videos) * 100)}%`; });
  document.querySelectorAll('[data-field="rewardEarnings"]').forEach((el) => { el.textContent = `$${(u.challengesWon * 420).toLocaleString()}`; });
  document.querySelectorAll('[data-field="totalVideos"]').forEach((el) => { el.textContent = u.videos; });
  document.querySelectorAll('[data-field="totalViews"]').forEach((el) => { el.textContent = '128K'; });
  document.querySelectorAll('[data-field="totalLikes"]').forEach((el) => { el.textContent = u.likes; });

  const barsEl = document.getElementById('ratingBreakdown');
  if (barsEl) {
    const max = Math.max(...RATING_DISTRIBUTION);
    barsEl.innerHTML = RATING_DISTRIBUTION.map((count, i) => `
      <div class="score-bar-row">
        <span class="score-bar-row__label">${i + 1}</span>
        <div class="score-bar-row__track"><div class="score-bar-row__fill" style="width:${Math.max(6, Math.round((count / max) * 100))}%"></div></div>
        <span class="score-bar-row__count">${count}</span>
      </div>`).join('');
  }

  const perfEl = document.getElementById('recentPerformance');
  if (perfEl) {
    perfEl.innerHTML = RECENT_PERFORMANCE.map((p) => `
      <a class="performance-row" href="challenge-detail.html?id=${p.challengeId}">
        <div class="performance-row__body">
          <strong>${p.title}</strong>
          <span>${formatDate(p.date)}</span>
        </div>
        <span class="performance-row__result ${p.score ? 'is-scored' : 'is-unscored'}">${p.result}</span>
      </a>`).join('');
  }
}

/* =========================================================
   Rewards & Wallet (module 8)
   ========================================================= */

const REWARD_TYPE_META = {
  cash: { label: 'Cash', icon: 'cash', color: '#1FAE6A' },
  voucher: { label: 'Gift Voucher', icon: 'ticket', color: '#4C6CF7' },
  product: { label: 'Product', icon: 'box', color: '#FF8A3D' },
  sponsor: { label: 'Sponsor Reward', icon: 'handshake', color: '#FF3D77' },
};
function rewardTypeBadgeHtml(type) {
  const meta = REWARD_TYPE_META[type] || REWARD_TYPE_META.cash;
  return `<span class="reward-type-badge" style="background:${meta.color}1F; color:${meta.color};">${ICONS[meta.icon]}${meta.label}</span>`;
}
function rewardStatusBadgeHtml(status) {
  const labels = { available: 'Available', claimed: 'Claimed', locked: 'Locked' };
  return `<span class="reward-status-badge reward-status-badge--${status}">${labels[status] || status}</span>`;
}
function currentReward() {
  const params = new URLSearchParams(location.search);
  const featuredId = (REWARDS.find((r) => r.featured) || REWARDS[0]).id;
  return REWARDS.find((r) => r.id === (params.get('id') || featuredId)) || REWARDS[0];
}
function formatDateTime(iso) {
  const d = new Date(iso);
  return `${d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} · ${d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}`;
}

function rewardCardHtml(r) {
  const ctaLabel = r.status === 'available' ? 'Claim' : r.status === 'claimed' ? 'View' : 'Locked';
  return `
  <a class="reward-card${r.status === 'locked' ? ' is-locked' : ''}" href="reward-detail.html?id=${r.id}">
    <div class="reward-card__media">
      <img src="${r.imageUrl}" alt="${r.title}" loading="lazy" onerror="imgFallback(this)">
      ${rewardStatusBadgeHtml(r.status)}
    </div>
    <div class="reward-card__body">
      ${rewardTypeBadgeHtml(r.type)}
      <span class="reward-card__title">${r.title}</span>
      <div class="reward-card__footer">
        <span class="reward-card__value">${r.value}</span>
        <span class="reward-card__cta">${ctaLabel}${ICONS.chevronRight}</span>
      </div>
    </div>
  </a>`;
}

function featuredRewardCardHtml(r) {
  return `
  <a class="featured-reward-card" href="reward-detail.html?id=${r.id}">
    <img src="${r.imageUrl}" alt="${r.title}" loading="lazy" onerror="imgFallback(this)">
    <div class="featured-reward-card__scrim"></div>
    <span class="featured-reward-card__tag">${ICONS.sparkle}<span>Featured Reward</span></span>
    <div class="featured-reward-card__body">
      <span class="featured-reward-card__title">Win premium prizes from active challenges</span>
      <span class="featured-reward-card__cta"><span>View Rewards</span>${ICONS.chevronRight}</span>
    </div>
  </a>`;
}

const TX_CATEGORY_ICON = { challenge_win: 'trophy', referral: 'follow', daily_bonus: 'calendar', withdrawal: 'bankCard', voucher: 'ticket' };
function transactionRowHtml(tx, opts) {
  const neutralWithdrawnBadge = !!(opts && opts.neutralWithdrawnBadge);
  const icon = TX_CATEGORY_ICON[tx.category] || 'wallet';
  const statusLabel = tx.status === 'pending' ? 'Pending' : tx.type === 'withdrawn' ? 'Withdrawn' : 'Completed';
  const statusClass = neutralWithdrawnBadge && tx.status !== 'pending' && tx.type === 'withdrawn' ? 'withdrawn' : tx.status;
  const amountClass = tx.type === 'credit' ? 'is-credit' : 'is-debit';
  const inner = `
    <span class="transaction-row__icon transaction-row__icon--${tx.category}">${ICONS[icon]}</span>
    <div class="transaction-row__body">
      <strong>${tx.title}</strong>
      <span>${formatDateTime(tx.date)}</span>
    </div>
    <div class="transaction-row__right">
      <span class="transaction-row__amount ${amountClass}">${tx.amount}</span>
      <span class="transaction-row__status transaction-row__status--${statusClass}">${statusLabel}</span>
    </div>`;
  return tx.rewardId
    ? `<a class="transaction-row" href="reward-detail.html?id=${tx.rewardId}">${inner}</a>`
    : `<div class="transaction-row">${inner}</div>`;
}

/* ---------- 37. Rewards Screen ---------- */
function hydrateRewards() {
  document.querySelectorAll('[data-field="availableBalance"]').forEach((el) => { el.textContent = WALLET_SUMMARY.availableBalance; });
  document.querySelectorAll('[data-field="totalEarned"]').forEach((el) => { el.textContent = WALLET_SUMMARY.totalEarned; });

  const featured = REWARDS.find((r) => r.featured) || REWARDS[0];
  const featuredEl = document.getElementById('featuredReward');
  if (featuredEl) featuredEl.innerHTML = featuredRewardCardHtml(featured);

  const tabs = document.querySelectorAll('.rewards-tab-row .tab-btn');
  const gridEl = document.getElementById('rewardsGrid');
  const typeMap = { cash: 'cash', vouchers: 'voucher', products: 'product', sponsor: 'sponsor' };
  function render(tab) {
    const list = tab === 'all' ? REWARDS : REWARDS.filter((r) => r.type === typeMap[tab]);
    if (gridEl) gridEl.innerHTML = list.length ? list.map(rewardCardHtml).join('') : `<p class="empty-note">No rewards in this category yet.</p>`;
  }
  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      render(tab.dataset.tab);
    });
  });
  render('all');
}

/* ---------- 37b. Reward Category Pages (Cash / Vouchers / Products / Sponsor) ----------
   Each category gets its own dedicated card layout (not the generic reward-card
   grid from the main Rewards Screen) so the four pages read as distinct, purpose-built
   screens instead of the same list with a different header. */
function sumRewardValues(list) {
  return list.reduce((sum, r) => sum + (parseFloat(String(r.value).replace(/[^0-9.]/g, '')) || 0), 0);
}
function rewardChallengeTitle(r) {
  const c = CHALLENGES.find((ch) => ch.id === r.challengeId);
  return c ? c.title : 'General Reward';
}

function cashRewardRowHtml(r) {
  return `
  <a class="cash-reward-row${r.status === 'locked' ? ' is-locked' : ''}" href="reward-detail.html?id=${r.id}">
    <span class="cash-reward-row__icon">${ICONS.cash}</span>
    <div class="cash-reward-row__info">
      <strong>${r.title}</strong>
      <span>${rewardChallengeTitle(r)}</span>
    </div>
    <div class="cash-reward-row__right">
      <span class="cash-reward-row__amount">${r.value}</span>
      ${rewardStatusBadgeHtml(r.status)}
    </div>
    <span class="cash-reward-row__chevron">${ICONS.chevronRight}</span>
  </a>`;
}

function voucherRewardCardHtml(r) {
  const ctaLabel = r.status === 'available' ? 'Claim' : r.status === 'claimed' ? 'View' : 'Locked';
  return `
  <a class="voucher-reward-card${r.status === 'locked' ? ' is-locked' : ''}" href="reward-detail.html?id=${r.id}">
    <div class="voucher-reward-card__media"><img src="${r.imageUrl}" alt="${r.title}" loading="lazy" onerror="imgFallback(this)"></div>
    <div class="voucher-reward-card__body">
      <span class="voucher-reward-card__title">${r.title}</span>
      <span class="voucher-reward-card__value">${r.value}</span>
      <span class="voucher-reward-card__expiry">${ICONS.calendar}${r.expiryDate ? `Expires ${formatDate(r.expiryDate)}` : 'No expiry'}</span>
      <div class="voucher-reward-card__footer">
        ${rewardStatusBadgeHtml(r.status)}
        <span class="voucher-reward-card__cta">${ctaLabel}${ICONS.chevronRight}</span>
      </div>
    </div>
  </a>`;
}

function productRewardCardHtml(r) {
  const ctaLabel = r.status === 'locked' ? 'Locked' : r.trackable ? 'Track' : 'View';
  return `
  <a class="product-reward-card${r.status === 'locked' ? ' is-locked' : ''}" href="reward-detail.html?id=${r.id}">
    <div class="product-reward-card__media">
      <img src="${r.imageUrl}" alt="${r.title}" loading="lazy" onerror="imgFallback(this)">
      ${rewardStatusBadgeHtml(r.status)}
    </div>
    <div class="product-reward-card__body">
      <span class="product-reward-card__name">${r.title}</span>
      <span class="product-reward-card__challenge">${ICONS.trophy}<span>${rewardChallengeTitle(r)}</span></span>
      <div class="product-reward-card__footer">
        <span class="product-reward-card__value">${r.value}</span>
        <span class="product-reward-card__cta">${ctaLabel}${ICONS.chevronRight}</span>
      </div>
    </div>
  </a>`;
}

function sponsorRewardCardHtml(r) {
  const ctaLabel = r.status === 'available' ? 'Claim' : r.status === 'claimed' ? 'View' : 'Locked';
  return `
  <a class="sponsor-reward-card${r.status === 'locked' ? ' is-locked' : ''}" href="reward-detail.html?id=${r.id}">
    <div class="sponsor-reward-card__media">
      <img src="${r.imageUrl}" alt="${r.title}" loading="lazy" onerror="imgFallback(this)">
      <span class="sponsor-reward-card__brand">${r.sponsorName || 'Sponsor'}</span>
    </div>
    <div class="sponsor-reward-card__body">
      <span class="sponsor-reward-card__title">${r.title}</span>
      <span class="sponsor-reward-card__details">${r.value}</span>
      <div class="sponsor-reward-card__footer">
        ${rewardStatusBadgeHtml(r.status)}
        <span class="sponsor-reward-card__cta">${ctaLabel}${ICONS.chevronRight}</span>
      </div>
    </div>
  </a>`;
}

function hydrateCashRewards() {
  const list = REWARDS.filter((r) => r.type === 'cash');
  const available = list.filter((r) => r.status === 'available');
  document.querySelectorAll('[data-field="cashAvailable"]').forEach((el) => { el.textContent = `$${sumRewardValues(available).toLocaleString()}`; });
  document.querySelectorAll('[data-field="cashTotalEarned"]').forEach((el) => { el.textContent = `$${sumRewardValues(list).toLocaleString()}`; });
  const gridEl = document.getElementById('cashRewardsGrid');
  if (gridEl) gridEl.innerHTML = list.length ? list.map(cashRewardRowHtml).join('') : `<p class="empty-note">No cash rewards yet.</p>`;
}

function hydrateVoucherRewards() {
  const list = REWARDS.filter((r) => r.type === 'voucher');
  document.querySelectorAll('[data-field="voucherAvailableCount"]').forEach((el) => { el.textContent = String(list.filter((r) => r.status === 'available').length); });
  document.querySelectorAll('[data-field="voucherClaimedCount"]').forEach((el) => { el.textContent = String(list.filter((r) => r.status === 'claimed').length); });
  const gridEl = document.getElementById('voucherRewardsGrid');
  if (gridEl) gridEl.innerHTML = list.length ? list.map(voucherRewardCardHtml).join('') : `<p class="empty-note">No voucher rewards yet.</p>`;
}

function hydrateProductRewards() {
  const list = REWARDS.filter((r) => r.type === 'product');
  document.querySelectorAll('[data-field="productAvailableCount"]').forEach((el) => { el.textContent = String(list.filter((r) => r.status === 'available').length); });
  document.querySelectorAll('[data-field="productLockedCount"]').forEach((el) => { el.textContent = String(list.filter((r) => r.status === 'locked').length); });
  const gridEl = document.getElementById('productRewardsGrid');
  if (gridEl) gridEl.innerHTML = list.length ? list.map(productRewardCardHtml).join('') : `<p class="empty-note">No product rewards yet.</p>`;
}

function hydrateSponsorRewards() {
  const list = REWARDS.filter((r) => r.type === 'sponsor');
  document.querySelectorAll('[data-field="sponsorTotalCount"]').forEach((el) => { el.textContent = String(list.length); });
  document.querySelectorAll('[data-field="sponsorAvailableCount"]').forEach((el) => { el.textContent = String(list.filter((r) => r.status === 'available').length); });
  const gridEl = document.getElementById('sponsorRewardsGrid');
  if (gridEl) gridEl.innerHTML = list.length ? list.map(sponsorRewardCardHtml).join('') : `<p class="empty-note">No sponsor rewards yet.</p>`;
}

/* ---------- 38. Reward Detail Screen ---------- */
function hydrateRewardDetail() {
  const r = currentReward();
  document.querySelectorAll('[data-field="imageUrl"]').forEach((el) => el.setAttribute('src', r.imageUrl));
  document.querySelectorAll('[data-field="title"]').forEach((el) => { el.textContent = r.title; });
  document.querySelectorAll('[data-field="value"]').forEach((el) => { el.textContent = r.value; });
  document.querySelectorAll('[data-field="description"]').forEach((el) => { el.textContent = r.description; });
  document.querySelectorAll('[data-field="expiry"]').forEach((el) => { el.textContent = r.expiryDate ? `Expires ${formatDate(r.expiryDate)}` : 'No expiry'; });

  const typeSlot = document.getElementById('rewardTypeSlot');
  if (typeSlot) typeSlot.innerHTML = rewardTypeBadgeHtml(r.type);
  const statusSlot = document.getElementById('rewardStatusSlot');
  if (statusSlot) statusSlot.innerHTML = rewardStatusBadgeHtml(r.status);
  const unlockNote = document.getElementById('rewardUnlockNote');
  if (unlockNote) unlockNote.classList.toggle('hidden', r.status !== 'locked');

  const eligList = document.getElementById('eligibilityList');
  if (eligList) eligList.innerHTML = r.eligibility.map((e) => `<div class="eligibility-item"><span class="eligibility-item__icon">${ICONS.checkCircle}</span><span>${e}</span></div>`).join('');

  const ctaBtn = document.getElementById('rewardCtaBtn');
  const claimedNote = document.getElementById('rewardClaimedNote');
  if (ctaBtn) {
    if (r.status === 'available') {
      ctaBtn.innerHTML = '<span>Claim Reward</span>';
      ctaBtn.addEventListener('click', () => {
        // TODO(api): POST claim request; reward value gets credited to the wallet on success.
        ctaBtn.innerHTML = `${ICONS.checkCircle}<span>Claimed</span>`;
        ctaBtn.disabled = true;
        claimedNote?.classList.remove('hidden');
      });
    } else if (r.status === 'claimed') {
      ctaBtn.innerHTML = `${ICONS.wallet}<span>View Wallet</span>`;
      ctaBtn.addEventListener('click', () => { window.location.href = 'wallet.html'; });
    } else {
      ctaBtn.innerHTML = `${ICONS.lock}<span>Locked</span>`;
      ctaBtn.disabled = true;
      ctaBtn.classList.add('is-locked');
    }
  }

  const trackBtn = document.getElementById('trackPrizeBtn');
  if (trackBtn) {
    if (r.trackable && r.status !== 'locked') trackBtn.classList.remove('hidden');
    trackBtn.addEventListener('click', () => { window.location.href = `prize-tracking.html?id=${r.id}`; });
  }
}

/* ---------- 39. Wallet Screen ---------- */
function hydrateWallet() {
  const w = WALLET_SUMMARY;
  document.querySelectorAll('[data-field="availableBalance"]').forEach((el) => { el.textContent = w.availableBalance; });
  document.querySelectorAll('[data-field="pendingRewards"]').forEach((el) => { el.textContent = w.pendingRewards; });
  document.querySelectorAll('[data-field="totalWithdrawn"]').forEach((el) => { el.textContent = w.totalWithdrawn; });
  document.querySelectorAll('[data-field="challengeWins"]').forEach((el) => { el.textContent = w.challengeWins; });
  document.querySelectorAll('[data-field="referralRewards"]').forEach((el) => { el.textContent = w.referralRewards; });
  document.querySelectorAll('[data-field="dailyBonus"]').forEach((el) => { el.textContent = w.dailyBonus; });
  document.querySelectorAll('[data-field="sponsorRewards"]').forEach((el) => { el.textContent = w.sponsorRewards; });
  document.querySelectorAll('[data-field="minWithdrawal"]').forEach((el) => { el.textContent = w.minWithdrawal; });

  const recentEl = document.getElementById('recentTransactions');
  if (recentEl) recentEl.innerHTML = TRANSACTIONS.slice(0, 3).map(transactionRowHtml).join('');
}

/* ---------- 40. Transaction History Screen ---------- */
function hydrateTransactionHistory() {
  const filters = [
    { id: 'all', label: 'All' }, { id: 'credit', label: 'Credit' }, { id: 'debit', label: 'Debit' },
    { id: 'pending', label: 'Pending' }, { id: 'withdrawn', label: 'Withdrawn' },
  ];
  const filterEl = document.getElementById('txFilterChips');
  if (filterEl) filterEl.innerHTML = filters.map((f, i) => `<button class="filter-pill${i === 0 ? ' is-active' : ''}" type="button" data-type="${f.id}">${f.label}</button>`).join('');

  const listEl = document.getElementById('txList');
  const emptyEl = document.getElementById('txEmpty');
  function render(type) {
    const list = type === 'all' ? TRANSACTIONS : TRANSACTIONS.filter((t) => t.type === type);
    if (listEl) listEl.innerHTML = list.map((tx) => transactionRowHtml(tx, { neutralWithdrawnBadge: true })).join('');
    if (emptyEl) emptyEl.classList.toggle('hidden', list.length > 0);
  }
  render('all');

  filterEl?.addEventListener('click', (e) => {
    const btn = e.target.closest('.filter-pill');
    if (!btn) return;
    filterEl.querySelectorAll('.filter-pill').forEach((b) => b.classList.toggle('is-active', b === btn));
    render(btn.dataset.type);
  });
}

/* ---------- 41. Withdrawal Request Screen ---------- */
function hydrateWithdrawalRequest() {
  document.querySelectorAll('[data-field="availableBalance"]').forEach((el) => { el.textContent = WALLET_SUMMARY.availableBalance; });
  document.querySelectorAll('[data-field="minWithdrawal"]').forEach((el) => { el.textContent = WALLET_SUMMARY.minWithdrawal; });

  const form = document.getElementById('withdrawalForm');
  const formSection = document.getElementById('withdrawalFormSection');
  const successSection = document.getElementById('withdrawalSuccessSection');
  const amountInput = document.getElementById('withdrawAmount');

  const quickAmountsEl = document.getElementById('withdrawQuickAmounts');
  if (quickAmountsEl && amountInput) {
    const maxVal = parseFloat(String(WALLET_SUMMARY.availableBalance).replace(/[^0-9.]/g, '')) || 0;
    const chips = quickAmountsEl.querySelectorAll('.withdraw-chip');
    chips.forEach((chip) => {
      chip.addEventListener('click', () => {
        const val = chip.dataset.amount === 'max' ? maxVal : Number(chip.dataset.amount);
        amountInput.value = val;
        chips.forEach((c) => c.classList.toggle('is-active', c === chip));
      });
    });
  }

  form?.addEventListener('submit', (e) => {
    e.preventDefault();
    // TODO(api): create a Razorpay payout / withdrawal request via the backend. UI-only for now.
    const amount = amountInput?.value || '0';
    const successAmount = document.getElementById('withdrawalSuccessAmount');
    if (successAmount) successAmount.textContent = `$${amount}`;
    formSection?.classList.add('hidden');
    successSection?.classList.remove('hidden');
  });

  document.getElementById('withdrawalDoneBtn')?.addEventListener('click', () => { window.location.href = 'wallet.html'; });
}

/* ---------- 42. Prize Tracking Screen ---------- */
const PRIZE_TIMELINE_STEPS = [
  { id: 'winner_verified', label: 'Winner Verified' },
  { id: 'reward_approved', label: 'Reward Approved' },
  { id: 'processing', label: 'Prize Processing' },
  { id: 'shipped', label: 'Shipped / Delivered' },
];
function hydratePrizeTracking() {
  const params = new URLSearchParams(location.search);
  const requestedId = params.get('id');
  const reward = REWARDS.find((r) => r.id === requestedId) || REWARDS.find((r) => PRIZE_TRACKING[r.id]) || REWARDS[0];
  const tracking = PRIZE_TRACKING[reward.id] || Object.values(PRIZE_TRACKING)[0];

  document.querySelectorAll('[data-field="prizeImage"]').forEach((el) => el.setAttribute('src', reward.imageUrl));
  document.querySelectorAll('[data-field="prizeName"]').forEach((el) => { el.textContent = tracking.prizeName; });
  document.querySelectorAll('[data-field="challengeName"]').forEach((el) => { el.textContent = tracking.challengeName; });
  document.querySelectorAll('[data-field="winnerDate"]').forEach((el) => { el.textContent = formatDate(tracking.winnerDate); });
  document.querySelectorAll('[data-field="estimatedDate"]').forEach((el) => { el.textContent = formatDate(tracking.estimatedDate); });
  document.querySelectorAll('[data-field="trackingId"]').forEach((el) => { el.textContent = tracking.trackingId || '—'; });

  const activeIndex = PRIZE_TIMELINE_STEPS.findIndex((s) => s.id === tracking.status);
  const statusBadge = document.getElementById('prizeStatusBadge');
  if (statusBadge) statusBadge.textContent = (PRIZE_TIMELINE_STEPS[activeIndex] || PRIZE_TIMELINE_STEPS[0]).label;

  const timelineEl = document.getElementById('prizeTimeline');
  if (timelineEl) {
    timelineEl.innerHTML = PRIZE_TIMELINE_STEPS.map((step, i) => {
      const state = i < activeIndex ? 'done' : i === activeIndex ? 'active' : 'upcoming';
      const subtext = state === 'done' ? 'Completed' : state === 'active' ? 'In progress' : 'Pending';
      return `
      <div class="prize-timeline-step prize-timeline-step--${state}">
        <span class="prize-timeline-step__dot">${state === 'done' ? ICONS.checkCircle : ''}</span>
        <div class="prize-timeline-step__body">
          <strong>${step.label}</strong>
          <span>${subtext}</span>
        </div>
      </div>`;
    }).join('');
  }

  document.getElementById('viewRewardDetailBtn')?.addEventListener('click', () => { window.location.href = `reward-detail.html?id=${reward.id}`; });
}

/* =========================================================
   Module 9 — Winners (43-44)
   ========================================================= */
function winnerUser(w) { return CREATORS.find((u) => u.id === w.userId) || CREATORS[0]; }
function winnerChallengeOf(w) { return CHALLENGES.find((c) => c.id === w.challengeId); }
function winnerReelOf(w) { return w.reelId ? REELS.find((r) => r.id === w.reelId) : null; }

function rankBadgeHtml(rank) {
  const cls = rank === 1 ? 'is-gold' : rank === 2 ? 'is-silver' : rank === 3 ? 'is-bronze' : 'is-plain';
  return `<span class="rank-badge ${cls}">#${rank}</span>`;
}

function winnerFeaturedCardHtml(w) {
  const u = winnerUser(w);
  const c = winnerChallengeOf(w);
  const reel = winnerReelOf(w);
  const thumb = reel ? reel.imageUrl : u.coverUrl;
  return `
  <a class="winner-spotlight-card" href="winner-detail.html?id=${w.id}">
    <div class="winner-spotlight-card__media">
      <img src="${thumb}" alt="${u.name}" loading="lazy" onerror="imgFallback(this)">
      <div class="winner-spotlight-card__scrim"></div>
      ${rankBadgeHtml(w.rank)}
      <div class="winner-spotlight-card__info">
        <img class="winner-spotlight-card__avatar" src="${u.avatarUrl}" alt="${u.name}" onerror="imgFallback(this)">
        <div class="winner-spotlight-card__text">
          <strong>${u.name}</strong>
          <span>${u.handle}</span>
        </div>
      </div>
    </div>
    <div class="winner-spotlight-card__footer">
      <div class="winner-spotlight-card__footer-text">
        <span class="winner-spotlight-card__challenge">${c ? c.title : ''}</span>
        <span class="winner-spotlight-card__prize">${w.prize}</span>
      </div>
      <span class="winner-spotlight-card__score">${ICONS.star}${w.talentScore.toFixed(1)}</span>
    </div>
  </a>`;
}

function winnerCardHtml(w) {
  const u = winnerUser(w);
  const c = winnerChallengeOf(w);
  return `
  <div class="winner-card">
    <div class="winner-card__avatar-wrap">
      <img class="winner-card__avatar" src="${u.avatarUrl}" alt="${u.name}" onerror="imgFallback(this)">
      ${rankBadgeHtml(w.rank)}
    </div>
    <div class="winner-card__body">
      <strong>${u.name}</strong>
      <span class="winner-card__challenge">${c ? c.title : ''}</span>
      <span class="winner-card__prize">${w.prize}</span>
    </div>
    <div class="winner-card__right">
      <span class="winner-card__score">${ICONS.star}${w.talentScore.toFixed(1)}</span>
      <a class="winner-card__view-btn" href="winner-detail.html?id=${w.id}">View</a>
    </div>
  </div>`;
}

function hydrateWinners() {
  const tabs = document.querySelectorAll('.winners-tab-row .tab-btn');
  const featuredEl = document.getElementById('featuredWinner');
  const listEl = document.getElementById('winnersList');

  function render(period) {
    const list = WINNERS.filter((w) => w.period === period).sort((a, b) => a.rank - b.rank);
    const featured = list.find((w) => w.featured) || list[0] || WINNERS[0];
    if (featuredEl) featuredEl.innerHTML = winnerFeaturedCardHtml(featured);
    const rest = list.filter((w) => w.id !== featured.id);
    const finalList = rest.length ? rest : list.filter((w) => w.id !== featured.id);
    if (listEl) listEl.innerHTML = finalList.length ? finalList.map(winnerCardHtml).join('') : `<p class="empty-note">No winners in this category yet.</p>`;
  }
  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      render(tab.dataset.period);
    });
  });
  render('challenge');
}

function currentWinner() {
  const params = new URLSearchParams(location.search);
  const requestedId = params.get('id');
  return WINNERS.find((w) => w.id === requestedId) || WINNERS.find((w) => w.featured) || WINNERS[0];
}

function hydrateWinnerDetail() {
  const w = currentWinner();
  const u = winnerUser(w);
  const c = winnerChallengeOf(w);
  const reel = winnerReelOf(w);

  document.querySelectorAll('[data-field="avatarUrl"]').forEach((el) => el.setAttribute('src', u.avatarUrl));
  document.querySelectorAll('[data-field="name"]').forEach((el) => { el.textContent = u.name; });
  document.querySelectorAll('[data-field="handle"]').forEach((el) => { el.textContent = u.handle; });
  document.querySelectorAll('[data-field="challengeTitle"]').forEach((el) => { el.textContent = c ? c.title : ''; });
  document.querySelectorAll('[data-field="prize"]').forEach((el) => { el.textContent = w.prize; });
  document.querySelectorAll('[data-field="talentScore"]').forEach((el) => { el.textContent = w.talentScore.toFixed(1); });

  const rankSlot = document.getElementById('winnerRankSlot');
  if (rankSlot) rankSlot.innerHTML = rankBadgeHtml(w.rank);

  const videoCard = document.getElementById('winningVideoCard');
  if (videoCard) {
    videoCard.innerHTML = reel ? `
      <img src="${reel.imageUrl}" alt="${reel.title}" loading="lazy" onerror="imgFallback(this)">
      <span class="winning-video-card__play">${ICONS.play}</span>
      <div class="winning-video-card__stats">
        <span>${ICONS.eyeSolid}${reel.views}</span>
        <span>${ICONS.heartFilled}${reel.likes}</span>
      </div>` : `<p class="empty-note">No video preview available for this win.</p>`;
  }

  document.querySelectorAll('[data-field="finalPosition"]').forEach((el) => { el.textContent = `#${w.rank}`; });
  document.querySelectorAll('[data-field="totalVotes"]').forEach((el) => { el.textContent = w.totalVotes.toLocaleString(); });
  document.querySelectorAll('[data-field="avgRating"]').forEach((el) => { el.textContent = w.avgRating.toFixed(1); });
  document.querySelectorAll('[data-field="winDate"]').forEach((el) => { el.textContent = formatDate(w.winDate); });

  const watchBtn = document.getElementById('watchWinningVideoBtn');
  if (watchBtn) {
    if (reel) watchBtn.addEventListener('click', () => { window.location.href = `video-detail.html?id=${reel.id}`; });
    else { watchBtn.disabled = true; watchBtn.classList.add('is-locked'); }
  }
  document.getElementById('viewWinnerProfileBtn')?.addEventListener('click', () => { window.location.href = `public-profile.html?id=${u.id}`; });
}

/* =========================================================
   Module 10 — Invite & Referral (45-46)
   ========================================================= */
function hydrateInviteFriends() {
  const codeEl = document.getElementById('referralCodeValue');
  if (codeEl) codeEl.textContent = REFERRAL_SUMMARY.code;

  const shareOptions = [
    { id: 'whatsapp', label: 'WhatsApp', icon: 'whatsapp' },
    { id: 'sms', label: 'SMS', icon: 'sms' },
    { id: 'email', label: 'Email', icon: 'email' },
    { id: 'share', label: 'Social Share', icon: 'share' },
  ];
  const shareGridEl = document.getElementById('inviteShareGrid');
  if (shareGridEl) shareGridEl.innerHTML = shareOptions.map(shareOptionItemHtml).join('');

  const copyBtn = document.getElementById('copyReferralCodeBtn');
  if (copyBtn) {
    copyBtn.innerHTML = `${ICONS.copy}<span>Copy Code</span>`;
    copyBtn.addEventListener('click', () => {
      // TODO(api): use navigator.clipboard.writeText with the real referral code.
      copyBtn.innerHTML = `${ICONS.checkCircle}<span>Copied!</span>`;
      setTimeout(() => { copyBtn.innerHTML = `${ICONS.copy}<span>Copy Code</span>`; }, 1800);
    });
  }

  document.getElementById('shareInviteLinkBtn')?.addEventListener('click', () => { window.location.href = 'referral-tracking.html'; });
  document.getElementById('viewReferralTrackingBtn')?.addEventListener('click', () => { window.location.href = 'referral-tracking.html'; });
}

function referralStatusBadgeHtml(status) {
  const map = { invited: 'Invited', joined: 'Joined', rewarded: 'Rewarded' };
  return `<span class="referral-status-badge referral-status-badge--${status}">${map[status] || status}</span>`;
}
function referralRowHtml(rf) {
  const u = CREATORS.find((c) => c.id === rf.userId) || CREATORS[0];
  return `
  <div class="referral-row">
    <span class="referral-row__avatar-wrap referral-row__avatar-wrap--${rf.status}">
      <img src="${u.avatarUrl}" alt="${u.name}" onerror="imgFallback(this)">
    </span>
    <div class="referral-row__body">
      <strong>${u.name}</strong>
      <span>${formatDate(rf.date)}</span>
    </div>
    <div class="referral-row__right">
      ${referralStatusBadgeHtml(rf.status)}
      <span class="referral-row__amount${rf.amount === '—' ? ' is-muted' : ''}">${rf.amount}</span>
    </div>
  </div>`;
}
function hydrateReferralTracking() {
  document.querySelectorAll('[data-field="totalInvites"]').forEach((el) => { el.textContent = REFERRAL_SUMMARY.totalInvites; });
  document.querySelectorAll('[data-field="joinedUsers"]').forEach((el) => { el.textContent = REFERRAL_SUMMARY.joinedUsers; });
  document.querySelectorAll('[data-field="rewardsEarned"]').forEach((el) => { el.textContent = REFERRAL_SUMMARY.rewardsEarned; });
  document.querySelectorAll('[data-field="pendingRewards"]').forEach((el) => { el.textContent = REFERRAL_SUMMARY.pendingRewards; });

  const pct = Math.min(100, Math.round((REFERRAL_MILESTONE.current / REFERRAL_MILESTONE.next) * 100));
  const fillEl = document.getElementById('referralProgressFill');
  if (fillEl) fillEl.style.width = `${pct}%`;
  const pctEl = document.getElementById('referralProgressPct');
  if (pctEl) pctEl.textContent = `${pct}%`;
  document.querySelectorAll('[data-field="milestoneProgress"]').forEach((el) => { el.textContent = `${REFERRAL_MILESTONE.current} / ${REFERRAL_MILESTONE.next} invites`; });
  document.querySelectorAll('[data-field="nextReward"]').forEach((el) => { el.textContent = REFERRAL_MILESTONE.nextReward; });

  const listEl = document.getElementById('referralList');
  if (listEl) listEl.innerHTML = REFERRAL_LIST.map(referralRowHtml).join('');
}

/* =========================================================
   Module 11 — Music Library (47-48)
   ========================================================= */
function musicTrackRowHtml(track) {
  return `
  <div class="music-track-row" data-track-id="${track.id}">
    <img src="${track.coverUrl}" alt="${track.title}" loading="lazy" onerror="imgFallback(this)">
    <button class="music-track-row__play" type="button" data-play="${track.id}">${ICONS.play}</button>
    <div class="music-track-row__body">
      <strong>${track.title}</strong>
      <span>${track.artist} · ${track.duration}</span>
    </div>
    <button class="music-track-row__fav${track.saved ? ' is-active' : ''}" type="button" data-fav="${track.id}">${track.saved ? ICONS.bookmarkFilled : ICONS.bookmark}</button>
    <a class="music-track-row__use" href="music-preview.html?id=${track.id}">Use</a>
  </div>`;
}
function musicFeaturedCardHtml(track) {
  return `
  <a class="music-featured-card" href="music-preview.html?id=${track.id}">
    <img src="${track.coverUrl}" alt="${track.title}" loading="lazy" onerror="imgFallback(this)">
    <div class="music-featured-card__scrim"></div>
    <span class="music-featured-card__tag">${ICONS.flame}<span>Featured Track</span></span>
    <div class="music-featured-card__body">
      <strong>${track.title}</strong>
      <span>${track.artist}</span>
    </div>
    <span class="music-featured-card__play">${ICONS.play}</span>
  </a>`;
}
function hydrateMusicLibrary() {
  const featuredEl = document.getElementById('featuredTrack');
  const featured = MUSIC_LIBRARY_TRACKS.find((t) => t.category === 'trending') || MUSIC_LIBRARY_TRACKS[0];
  if (featuredEl) featuredEl.innerHTML = musicFeaturedCardHtml(featured);

  const tabs = document.querySelectorAll('.music-tab-row .tab-btn');
  const listEl = document.getElementById('musicTrackList');
  const searchInput = document.getElementById('musicSearchInput');

  function render() {
    const activeTab = document.querySelector('.music-tab-row .tab-btn.active');
    const tabVal = activeTab ? activeTab.dataset.tab : 'trending';
    const q = (searchInput?.value || '').trim().toLowerCase();
    let list = tabVal === 'saved' ? MUSIC_LIBRARY_TRACKS.filter((t) => t.saved) : MUSIC_LIBRARY_TRACKS.filter((t) => t.category === tabVal);
    if (q) list = list.filter((t) => t.title.toLowerCase().includes(q) || t.artist.toLowerCase().includes(q));
    if (listEl) listEl.innerHTML = list.length ? list.map(musicTrackRowHtml).join('') : `<p class="empty-note">No tracks found.</p>`;
  }
  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      render();
    });
  });
  searchInput?.addEventListener('input', render);
  render();

  listEl?.addEventListener('click', (e) => {
    const favBtn = e.target.closest('[data-fav]');
    if (!favBtn) return;
    const track = MUSIC_LIBRARY_TRACKS.find((t) => t.id === favBtn.dataset.fav);
    if (track) { track.saved = !track.saved; render(); }
  });
}

function currentMusicTrack() {
  const params = new URLSearchParams(location.search);
  return MUSIC_LIBRARY_TRACKS.find((t) => t.id === params.get('id')) || MUSIC_LIBRARY_TRACKS[0];
}
function relatedTrackChipHtml(track) {
  return `
  <a class="related-track-chip" href="music-preview.html?id=${track.id}">
    <img src="${track.coverUrl}" alt="${track.title}" onerror="imgFallback(this)">
    <span class="related-track-chip__body">
      <strong>${track.title}</strong>
      <span>${track.artist}</span>
    </span>
    <span class="related-track-chip__meta">
      <span class="related-track-chip__duration">${track.duration}</span>
      <span class="related-track-chip__play-icon">${ICONS.play}</span>
    </span>
  </a>`;
}
function musicFormatSec(s) {
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60);
  return `${m}:${sec < 10 ? '0' : ''}${sec}`;
}
/* Deterministic static waveform pattern — a fixed set of bar heights (%)
   repeated to fill the requested bar count. Not derived from real audio
   (dummy data only), purely a premium visual treatment of the progress bar. */
function waveformBarHeights(count) {
  const pattern = [38, 62, 45, 80, 30, 70, 55, 92, 40, 65, 50, 85, 35, 60, 48, 78, 42, 68, 58, 90, 33, 63, 47, 82, 37, 66, 52, 88, 41, 71];
  return Array.from({ length: count }, (_, i) => pattern[i % pattern.length]);
}
function waveformHtml(count) {
  return waveformBarHeights(count).map((h) => `<span class="waveform-bar" style="height:${h}%"></span>`).join('');
}
function hydrateMusicPreview() {
  const track = currentMusicTrack();
  document.querySelectorAll('[data-field="coverUrl"]').forEach((el) => el.setAttribute('src', track.coverUrl));
  document.querySelectorAll('[data-field="title"]').forEach((el) => { el.textContent = track.title; });
  document.querySelectorAll('[data-field="artist"]').forEach((el) => { el.textContent = track.artist; });
  document.querySelectorAll('[data-field="duration"]').forEach((el) => { el.textContent = track.duration; });

  const playBtn = document.getElementById('musicPlayBtn');
  const currentTimeEl = document.getElementById('musicCurrentTime');
  const waveformEl = document.getElementById('musicWaveform');
  const BAR_COUNT = 36;
  if (waveformEl) waveformEl.innerHTML = waveformHtml(BAR_COUNT);
  const bars = waveformEl ? waveformEl.querySelectorAll('.waveform-bar') : [];

  let playing = false;
  let elapsed = 0;
  let timer = null;

  function updateWaveform() {
    const filledCount = Math.round((elapsed / track.durationSec) * BAR_COUNT);
    bars.forEach((bar, i) => { bar.classList.toggle('is-filled', i < filledCount); });
  }
  function tick() {
    elapsed += 1;
    if (elapsed >= track.durationSec) {
      elapsed = track.durationSec; playing = false; clearInterval(timer);
      if (playBtn) playBtn.innerHTML = ICONS.play;
    }
    updateWaveform();
    if (currentTimeEl) currentTimeEl.textContent = musicFormatSec(elapsed);
  }
  updateWaveform();
  playBtn?.addEventListener('click', () => {
    playing = !playing;
    playBtn.innerHTML = playing ? ICONS.pause : ICONS.play;
    if (playing) timer = setInterval(tick, 1000); else clearInterval(timer);
  });

  const relatedEl = document.getElementById('relatedTracks');
  if (relatedEl) {
    const related = MUSIC_LIBRARY_TRACKS.filter((t) => t.category === track.category && t.id !== track.id).slice(0, 4);
    relatedEl.innerHTML = related.length ? related.map(relatedTrackChipHtml).join('') : `<p class="empty-note">No related tracks.</p>`;
  }

  const useBtn = document.getElementById('useMusicBtn');
  useBtn?.addEventListener('click', () => {
    // TODO(api): attach this track to the in-app studio recording flow.
    useBtn.innerHTML = `${ICONS.checkCircle}<span>Added to Studio</span>`;
    useBtn.disabled = true;
    useBtn.classList.add('is-locked');
  });
  const saveBtn = document.getElementById('saveToLibraryBtn');
  if (saveBtn) {
    const renderSaveBtn = () => { saveBtn.innerHTML = track.saved ? `${ICONS.bookmarkFilled}<span>Saved</span>` : `${ICONS.bookmark}<span>Save to Library</span>`; };
    renderSaveBtn();
    saveBtn.addEventListener('click', () => { track.saved = !track.saved; renderSaveBtn(); });
  }
}

/* =========================================================
   Module 12 — Daily Bonus (49-50)
   ========================================================= */
function milestoneRowHtml(m, currentStreak) {
  const achieved = currentStreak >= m.days;
  return `
  <div class="milestone-row${achieved ? ' is-achieved' : ''}">
    <span class="milestone-row__icon">${achieved ? ICONS.checkCircle : ICONS.lock}</span>
    <div class="milestone-row__body">
      <strong>${m.days}-Day Streak</strong>
      <span>${m.reward}</span>
    </div>
  </div>`;
}
function weeklyRewardChipHtml(w, effectiveStreak) {
  const state = w.day <= effectiveStreak ? 'done' : w.day === effectiveStreak + 1 ? 'today' : 'upcoming';
  return `
  <div class="weekly-reward-chip weekly-reward-chip--${state}">
    <span class="weekly-reward-chip__day">Day ${w.day}</span>
    <span class="weekly-reward-chip__icon">${state === 'done' ? ICONS.checkCircle : ICONS.flame}</span>
    <span class="weekly-reward-chip__amount">${w.amount}</span>
  </div>`;
}
function hydrateDailyBonus() {
  const d = DAILY_BONUS;
  function effectiveStreak() { return d.currentStreak + (d.claimedToday ? 1 : 0); }

  function renderStreakDependent() {
    document.querySelectorAll('[data-field="currentStreak"]').forEach((el) => { el.textContent = effectiveStreak(); });
    const weeklyEl = document.getElementById('weeklyRewardsRow');
    if (weeklyEl) weeklyEl.innerHTML = d.weeklyRewards.map((w) => weeklyRewardChipHtml(w, effectiveStreak())).join('');
    const milestonesEl = document.getElementById('milestonesList');
    if (milestonesEl) milestonesEl.innerHTML = d.milestones.map((m) => milestoneRowHtml(m, effectiveStreak())).join('');
  }

  document.querySelectorAll('[data-field="todayRewardAmount"]').forEach((el) => { el.textContent = d.todayReward.amount; });
  document.querySelectorAll('[data-field="nextMilestone"]').forEach((el) => { el.textContent = `Day ${d.nextMilestone.day} · ${d.nextMilestone.reward}`; });
  renderStreakDependent();

  const claimBtn = document.getElementById('claimTodayBtn');
  const claimedNote = document.getElementById('bonusClaimedNote');
  if (claimBtn) {
    if (d.claimedToday) {
      claimBtn.innerHTML = `${ICONS.checkCircle}<span>Claimed</span>`;
      claimBtn.disabled = true;
      claimBtn.classList.add('is-locked');
      claimedNote?.classList.remove('hidden');
    } else {
      claimBtn.addEventListener('click', () => {
        d.claimedToday = true;
        claimBtn.innerHTML = `${ICONS.checkCircle}<span>Claimed</span>`;
        claimBtn.disabled = true;
        claimBtn.classList.add('is-locked');
        claimedNote?.classList.remove('hidden');
        renderStreakDependent();
      });
    }
  }

  document.getElementById('viewRewardCalendarBtn')?.addEventListener('click', () => { window.location.href = 'reward-calendar.html'; });
}

function rewardCalendarDayHtml(day, effectiveStreak) {
  const state = day < effectiveStreak ? 'claimed' : day === effectiveStreak ? 'today' : 'locked';
  const icon = state === 'claimed' ? ICONS.checkCircle : state === 'locked' ? ICONS.lock : '';
  return `<div class="reward-calendar-day reward-calendar-day--${state}"><span>${day}</span>${icon ? `<span class="reward-calendar-day__icon">${icon}</span>` : ''}</div>`;
}
/* Dedicated milestone card for the Reward Calendar screen only — forked from
   milestoneRowHtml() (used by Daily Bonus) so that screen's markup/styling
   is left completely untouched while this screen gets a more reward-focused look. */
function calendarMilestoneRowHtml(m, effectiveStreak) {
  const achieved = effectiveStreak >= m.days;
  return `
  <div class="calendar-milestone-row${achieved ? ' is-achieved' : ''}">
    <span class="calendar-milestone-row__icon">${achieved ? ICONS.checkCircle : ICONS.lock}</span>
    <div class="calendar-milestone-row__body">
      <strong>${m.days}-Day Streak</strong>
      <span class="calendar-milestone-row__reward-chip">${ICONS.gift}<span>${m.reward}</span></span>
    </div>
    ${achieved ? `<span class="calendar-milestone-row__badge">Unlocked</span>` : ''}
  </div>`;
}
function hydrateRewardCalendar() {
  const d = DAILY_BONUS;
  const effectiveStreak = d.currentStreak + (d.claimedToday ? 1 : 0);

  const gridEl = document.getElementById('rewardCalendarGrid');
  if (gridEl) gridEl.innerHTML = Array.from({ length: d.totalDays }, (_, i) => i + 1).map((day) => rewardCalendarDayHtml(day, effectiveStreak)).join('');

  const pct = Math.min(100, Math.round((effectiveStreak / d.totalDays) * 100));
  const fillEl = document.getElementById('streakProgressFill');
  if (fillEl) fillEl.style.width = `${pct}%`;
  const pctEl = document.getElementById('streakProgressPct');
  if (pctEl) pctEl.textContent = `${pct}%`;
  document.querySelectorAll('[data-field="streakDays"]').forEach((el) => { el.textContent = effectiveStreak; });
  document.querySelectorAll('[data-field="todayRewardAmount"]').forEach((el) => { el.textContent = d.todayReward.amount; });
  document.querySelectorAll('[data-field="nextMilestoneStreak"]').forEach((el) => { el.textContent = `${d.nextMilestone.day}-Day Streak`; });

  const milestonesEl = document.getElementById('calendarMilestones');
  if (milestonesEl) milestonesEl.innerHTML = d.milestones.map((m) => calendarMilestoneRowHtml(m, effectiveStreak)).join('');

  const actionBtn = document.getElementById('calendarActionBtn');
  if (actionBtn) {
    actionBtn.innerHTML = d.claimedToday ? '<span>View Bonus</span>' : '<span>Claim Today</span>';
    actionBtn.addEventListener('click', () => { window.location.href = 'daily-bonus.html'; });
  }
}

/* =========================================================
   Module 13 — Notifications & Activity (51-52)
   ========================================================= */
function notificationRowHtml(n) {
  const avatarUser = n.avatarId ? CREATORS.find((u) => u.id === n.avatarId) : null;
  const iconHtml = avatarUser
    ? `<img class="notification-row__avatar" src="${avatarUser.avatarUrl}" alt="" onerror="imgFallback(this)">`
    : `<span class="notification-row__icon">${ICONS[n.icon] || ICONS.bell}</span>`;
  return `
  <div class="notification-row${n.read ? '' : ' is-unread'}" data-id="${n.id}">
    ${iconHtml}
    <div class="notification-row__body">
      <strong>${n.title}</strong>
      <span>${n.description}</span>
      <span class="notification-row__time">${n.time}</span>
    </div>
    ${n.read ? '' : '<span class="notification-row__dot"></span>'}
  </div>`;
}
function hydrateNotifications() {
  const filters = [
    { id: 'all', label: 'All' }, { id: 'challenges', label: 'Challenges' }, { id: 'rewards', label: 'Rewards' },
    { id: 'winners', label: 'Winners' }, { id: 'social', label: 'Social' }, { id: 'referrals', label: 'Referrals' },
  ];
  const filterEl = document.getElementById('notificationFilterChips');
  if (filterEl) filterEl.innerHTML = filters.map((f, i) => `<button class="filter-pill${i === 0 ? ' is-active' : ''}" type="button" data-cat="${f.id}">${f.label}</button>`).join('');

  const listEl = document.getElementById('notificationsList');
  function render(cat) {
    const list = cat === 'all' ? NOTIFICATIONS : NOTIFICATIONS.filter((n) => n.category === cat);
    if (listEl) listEl.innerHTML = list.length ? list.map(notificationRowHtml).join('') : `<p class="empty-note">No notifications here yet.</p>`;
  }
  render('all');
  filterEl?.addEventListener('click', (e) => {
    const btn = e.target.closest('.filter-pill');
    if (!btn) return;
    filterEl.querySelectorAll('.filter-pill').forEach((b) => b.classList.toggle('is-active', b === btn));
    render(btn.dataset.cat);
  });

  document.getElementById('markAllReadBtn')?.addEventListener('click', () => {
    NOTIFICATIONS.forEach((n) => { n.read = true; });
    const activeCat = filterEl?.querySelector('.filter-pill.is-active')?.dataset.cat || 'all';
    render(activeCat);
  });
}

function activityRowHtml(a) {
  const avatarUser = a.avatarId ? CREATORS.find((u) => u.id === a.avatarId) : null;
  const iconHtml = avatarUser
    ? `<span class="activity-row__avatar-wrap activity-row__avatar-wrap--${a.type}"><img class="activity-row__avatar" src="${avatarUser.avatarUrl}" alt="" onerror="imgFallback(this)"></span>`
    : `<span class="activity-row__icon activity-row__icon--${a.type}">${ICONS[a.icon] || ICONS.bell}</span>`;
  return `
  <div class="activity-row">
    ${iconHtml}
    <div class="activity-row__body">
      <strong>${a.text}</strong>
      <span>${a.related}</span>
    </div>
    <span class="activity-row__time">${a.time}</span>
  </div>`;
}
function hydrateActivityCenter() {
  const s = ACTIVITY_SUMMARY;
  document.querySelectorAll('[data-field="activityLikes"]').forEach((el) => { el.textContent = s.likes; });
  document.querySelectorAll('[data-field="activityComments"]').forEach((el) => { el.textContent = s.comments; });
  document.querySelectorAll('[data-field="activityRatings"]').forEach((el) => { el.textContent = s.ratings; });
  document.querySelectorAll('[data-field="activityEntries"]').forEach((el) => { el.textContent = s.entries; });

  const tabs = document.querySelectorAll('.activity-tab-row .tab-btn');
  const listEl = document.getElementById('activityList');
  function render(type) {
    const list = type === 'all' ? ACTIVITY_LOG : ACTIVITY_LOG.filter((a) => a.type === type);
    if (listEl) listEl.innerHTML = list.length ? list.map(activityRowHtml).join('') : `<p class="empty-note">No activity yet.</p>`;
  }
  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      render(tab.dataset.type);
    });
  });
  render('all');
}

/* =========================================================
   Module 14 — Subscription / Membership (53-55)
   ========================================================= */
function primeDiamondBadgeHtml() {
  return `<span class="prime-diamond-badge">${ICONS.diamond}<span>Prime</span></span>`;
}
function planFeatureRowHtml(f) {
  const isAdvantage = f.prime !== f.basic;
  return `
  <div class="plan-comparison-row">
    <span class="plan-comparison-row__feature">${f.feature}</span>
    <span class="plan-comparison-row__basic">${f.basic}</span>
    <span class="plan-comparison-row__prime">${isAdvantage ? `<span class="plan-comparison-row__pill">${f.prime}</span>` : f.prime}</span>
  </div>`;
}
function hydrateMembershipPlan() {
  const m = MEMBERSHIP;
  document.querySelectorAll('[data-field="primePrice"]').forEach((el) => { el.textContent = m.primePrice; });

  const currentPlanEl = document.getElementById('currentPlanLabel');
  if (currentPlanEl) currentPlanEl.textContent = m.currentPlan === 'prime' ? 'Prime' : 'Basic';

  const comparisonEl = document.getElementById('planComparisonList');
  if (comparisonEl) comparisonEl.innerHTML = m.comparison.map(planFeatureRowHtml).join('');

  document.getElementById('upgradeToPrimeBtn')?.addEventListener('click', () => { window.location.href = 'prime-payment.html'; });
}

function hydratePrimePayment() {
  document.querySelectorAll('[data-field="primePrice"]').forEach((el) => { el.textContent = MEMBERSHIP.primePrice; });
  document.getElementById('payPrimeBtn')?.addEventListener('click', () => {
    // TODO(api): create a real payment intent via the backend/payment provider. UI-only for now.
    window.location.href = 'subscription-success.html';
  });
}

function hydrateSubscriptionSuccess() {
  document.getElementById('successViewProfileBtn')?.addEventListener('click', () => { window.location.href = 'my-profile.html'; });
  document.getElementById('successBackHomeBtn')?.addEventListener('click', () => { window.location.href = 'home.html'; });
}

/* =========================================================
   Module 15 — Settings & Support (56-63)
   ========================================================= */

/* ---------- 56. Settings Screen ---------- */
function hydrateSettings() {
  const u = currentUser();
  document.querySelectorAll('[data-field="settingsAvatar"]').forEach((el) => el.setAttribute('src', u.avatarUrl));
  document.querySelectorAll('[data-field="settingsName"]').forEach((el) => { el.textContent = u.name; });
  document.querySelectorAll('[data-field="settingsHandle"]').forEach((el) => { el.textContent = u.handle; });
  document.querySelectorAll('[data-field="settingsEmail"]').forEach((el) => { el.textContent = `${u.handle.replace('@', '')}@artable.app`; });
  const badgeSlot = document.getElementById('settingsPrimeBadgeSlot');
  if (badgeSlot) badgeSlot.innerHTML = u.prime ? primeDiamondBadgeHtml() : '';
}

/* ---------- 57. Change Password Screen ---------- */
function passwordStrengthOf(pw) {
  if (!pw) return { level: 0, label: 'Enter a new password' };
  if (pw.length < 6) return { level: 1, label: 'Weak' };
  let score = 0;
  if (pw.length >= 8) score++;
  if (/[a-z]/.test(pw) && /[A-Z]/.test(pw)) score++;
  if (/\d/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  if (score <= 1) return { level: 1, label: 'Weak' };
  if (score === 2) return { level: 2, label: 'Medium' };
  return { level: 3, label: 'Strong' };
}
function hydrateChangePassword() {
  document.querySelectorAll('[data-toggle-eye]').forEach((btn) => {
    const input = document.getElementById(btn.dataset.toggleEye);
    btn.innerHTML = ICONS.eyeOff;
    btn.addEventListener('click', () => {
      if (!input) return;
      const willShow = input.type === 'password';
      input.type = willShow ? 'text' : 'password';
      btn.innerHTML = willShow ? ICONS.eyeSolid : ICONS.eyeOff;
    });
  });

  const newPwInput = document.getElementById('newPasswordInput');
  const strengthFill = document.getElementById('passwordStrengthFill');
  const strengthLabel = document.getElementById('passwordStrengthLabel');
  function updateStrength() {
    const { level, label } = passwordStrengthOf(newPwInput ? newPwInput.value : '');
    if (strengthFill) {
      strengthFill.classList.remove('is-weak', 'is-medium', 'is-strong');
      if (level === 1) strengthFill.classList.add('is-weak');
      if (level === 2) strengthFill.classList.add('is-medium');
      if (level === 3) strengthFill.classList.add('is-strong');
    }
    if (strengthLabel) strengthLabel.textContent = label;
  }
  newPwInput?.addEventListener('input', updateStrength);
  updateStrength();

  const updateBtn = document.getElementById('updatePasswordBtn');
  updateBtn?.addEventListener('click', () => {
    // TODO(api): verify the current password and submit the new password to the backend.
    updateBtn.innerHTML = `${ICONS.checkCircle}<span>Password Updated</span>`;
    updateBtn.disabled = true;
    updateBtn.classList.add('is-locked');
  });
}

/* ---------- 58. Notification Settings Screen ---------- */
function toggleRowHtml(item) {
  return `
  <div class="toggle-row">
    <span class="toggle-row__icon">${ICONS[item.icon] || ICONS.bell}</span>
    <div class="toggle-row__body">
      <strong>${item.title}</strong>
      <span>${item.desc}</span>
    </div>
    <label class="settings-switch">
      <input type="checkbox" data-toggle-input="${item.id}" ${item.enabled ? 'checked' : ''}>
      <span class="settings-switch__track"></span>
    </label>
  </div>`;
}
function hydrateNotificationSettings() {
  const listEl = document.getElementById('notificationSettingsList');
  if (listEl) listEl.innerHTML = NOTIFICATION_SETTINGS.map(toggleRowHtml).join('');

  const masterInput = document.getElementById('pushMasterToggle');
  function applyMasterState() {
    const on = masterInput ? masterInput.checked : true;
    document.querySelectorAll('[data-toggle-input]').forEach((input) => { input.disabled = !on; });
    listEl?.classList.toggle('is-disabled', !on);
  }
  masterInput?.addEventListener('change', applyMasterState);
  applyMasterState();

  listEl?.addEventListener('change', (e) => {
    const input = e.target.closest('[data-toggle-input]');
    if (!input) return;
    const item = NOTIFICATION_SETTINGS.find((n) => n.id === input.dataset.toggleInput);
    if (item) item.enabled = input.checked;
  });
}

/* ---------- 59. Privacy Settings Screen ---------- */
function privacyOptionRowHtml(opt) {
  return `
  <div class="privacy-option-row">
    <div class="privacy-option-row__body">
      <strong>${opt.title}</strong>
      <span>${opt.desc}</span>
    </div>
    <label class="settings-switch">
      <input type="checkbox" data-privacy-input="${opt.id}" ${opt.value ? 'checked' : ''}>
      <span class="settings-switch__track"></span>
    </label>
  </div>`;
}
function hydratePrivacySettings() {
  const p = PRIVACY_SETTINGS;
  const options = [
    { id: 'showTalentScore', title: 'Show Talent Score', desc: 'Display your talent score on your public profile.', value: p.showTalentScore },
    { id: 'showRewardEarnings', title: 'Show Reward Earnings', desc: 'Display your total earnings on your public profile.', value: p.showRewardEarnings },
    { id: 'allowComments', title: 'Allow Comments', desc: 'Let other users comment on your videos.', value: p.allowComments },
    { id: 'allowShares', title: 'Allow Shares', desc: 'Let other users share your videos.', value: p.allowShares },
    { id: 'allowProfileSearch', title: 'Allow Profile Search', desc: 'Let others find your profile via search.', value: p.allowProfileSearch },
  ];
  const listEl = document.getElementById('privacyOptionsList');
  if (listEl) listEl.innerHTML = options.map(privacyOptionRowHtml).join('');
  listEl?.addEventListener('change', (e) => {
    const input = e.target.closest('[data-privacy-input]');
    if (!input) return;
    p[input.dataset.privacyInput] = input.checked;
  });

  const visBtns = document.querySelectorAll('.visibility-toggle .tab-btn');
  visBtns.forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.visibility === p.profileVisibility);
    btn.addEventListener('click', () => {
      visBtns.forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      p.profileVisibility = btn.dataset.visibility;
    });
  });

  document.querySelectorAll('[data-field="blockedUsersCount"]').forEach((el) => { el.textContent = p.blockedUsersCount; });
}

/* ---------- 60. Help & Support Screen ---------- */
function helpTopicCardHtml(topic) {
  return `
  <a class="help-topic-card" href="#" onclick="return comingSoon(event)">
    <span class="help-topic-card__icon">${ICONS[topic.icon] || ICONS.helpCircle}</span>
    <span>${topic.title}</span>
  </a>`;
}
function faqItemHtml(f) {
  return `
  <div class="faq-item" data-faq="${f.id}">
    <button class="faq-item__question" type="button" data-faq-toggle="${f.id}">
      <span>${f.q}</span>
      <span class="faq-item__chevron">${ICONS.chevronDown}</span>
    </button>
    <div class="faq-item__answer"><p>${f.a}</p></div>
  </div>`;
}
function hydrateHelpSupport() {
  const topicsEl = document.getElementById('helpTopicsGrid');
  if (topicsEl) topicsEl.innerHTML = HELP_TOPICS.map(helpTopicCardHtml).join('');

  const faqListEl = document.getElementById('faqList');
  const searchInput = document.getElementById('helpSearchInput');
  function renderFaqs() {
    const q = (searchInput?.value || '').trim().toLowerCase();
    const list = q ? HELP_FAQS.filter((f) => f.q.toLowerCase().includes(q) || f.a.toLowerCase().includes(q)) : HELP_FAQS;
    if (faqListEl) faqListEl.innerHTML = list.length ? list.map(faqItemHtml).join('') : `<p class="empty-note">No help topics found.</p>`;
  }
  renderFaqs();
  searchInput?.addEventListener('input', renderFaqs);

  faqListEl?.addEventListener('click', (e) => {
    const btn = e.target.closest('[data-faq-toggle]');
    if (!btn) return;
    btn.closest('.faq-item')?.classList.toggle('is-open');
  });
}

/* ---------- 63. Logout / Delete Account Confirmation Screen ---------- */
function hydrateLogoutConfirm() {
  const params = new URLSearchParams(location.search);
  const mode = params.get('mode') === 'delete' ? 'delete' : 'logout';

  document.getElementById('logoutConfirmView')?.classList.toggle('hidden', mode !== 'logout');
  document.getElementById('deleteConfirmView')?.classList.toggle('hidden', mode !== 'delete');

  document.getElementById('cancelLogoutBtn')?.addEventListener('click', () => { history.back(); });
  document.getElementById('confirmLogoutBtn')?.addEventListener('click', () => {
    // TODO(api): clear the user's session via the backend/auth provider.
    window.location.href = 'login.html';
  });

  document.getElementById('cancelDeleteBtn')?.addEventListener('click', () => { history.back(); });
  const deleteCheckbox = document.getElementById('deleteConfirmCheckbox');
  const deleteBtn = document.getElementById('confirmDeleteBtn');
  if (deleteCheckbox && deleteBtn) {
    deleteBtn.disabled = true;
    deleteCheckbox.addEventListener('change', () => { deleteBtn.disabled = !deleteCheckbox.checked; });
  }
  deleteBtn?.addEventListener('click', () => {
    if (deleteBtn.disabled) return;
    // TODO(api): permanently delete the user's account via the backend.
    window.location.href = 'login.html';
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initBottomNav();
  initBannerSlider();
});
