/* =========================================================
   ARTABLE — static dummy data for Home / Challenges module.
   Pure front-end mock data. Every image is exposed as an
   `imageUrl` field (real photo placeholders via LoremFlickr,
   locked to a fixed id so the same item shows the same photo
   everywhere) — swap these for real CDN/S3 URLs later without
   touching any markup. Backend integration should only need to
   replace the arrays below with API responses of the same shape.
   ========================================================= */

const CATEGORIES = [
  { id: 'dance',   name: 'Dance',   icon: 'dance',   count: 24, imageUrl: 'https://loremflickr.com/480/480/dance,dancer?lock=201' },
  { id: 'singing', name: 'Singing', icon: 'mic',     count: 31, imageUrl: 'https://loremflickr.com/480/480/singer,concert?lock=202' },
  { id: 'comedy',  name: 'Comedy',  icon: 'mask',    count: 12, imageUrl: 'https://loremflickr.com/480/480/comedian,standup?lock=203' },
  { id: 'fitness', name: 'Fitness', icon: 'dumbbell',count: 18, imageUrl: 'https://loremflickr.com/480/480/fitness,gym?lock=204' },
  { id: 'magic',   name: 'Magic',   icon: 'wand',    count: 9,  imageUrl: 'https://loremflickr.com/480/480/magician,magic?lock=205' },
  { id: 'art',     name: 'Art',     icon: 'brush',   count: 15, imageUrl: 'https://loremflickr.com/480/480/painter,artist?lock=206' },
  { id: 'acting',  name: 'Acting',  icon: 'drama',   count: 11, imageUrl: 'https://loremflickr.com/480/480/actor,theater?lock=207' },
  { id: 'sports',  name: 'Sports',  icon: 'trophy',  count: 20, imageUrl: 'https://loremflickr.com/480/480/athlete,sports?lock=208' },
  { id: 'custom',  name: 'Custom',  icon: 'sparkle', count: 7,  imageUrl: 'https://loremflickr.com/480/480/talent,stage?lock=209' },
];

const CHALLENGES = [
  {
    id: 'c1',
    title: 'Monthly Mega Dance Battle',
    category: 'Dance',
    status: 'active',
    featured: true,
    imageUrl: 'https://loremflickr.com/700/440/dance,stage?lock=301',
    prize: '$5,000 Prize Pool',
    endDate: '2026-07-31',
    participants: 1240,
    rating: 8.7,
    description: 'Show off your best choreography — solo or group — for a shot at this month’s biggest dance prize pool. Judged on technique, creativity, and stage presence.',
    rules: [
      'One entry per user for this challenge.',
      'Video must be recorded in the Artable in-app studio.',
      'Maximum entry length: 60 seconds.',
      'Content must be original choreography or a credited routine.',
    ],
    prizeBreakdown: [
      { place: '1st Place', reward: '$2,500 + Champion Badge' },
      { place: '2nd Place', reward: '$1,500 + Rising Star Badge' },
      { place: '3rd Place', reward: '$1,000 + Participation Badge' },
    ],
    topParticipants: [
      { name: 'Maya R.', score: 9.4, avatarUrl: 'https://loremflickr.com/100/100/woman,portrait?lock=401' },
      { name: 'Jordan K.', score: 9.1, avatarUrl: 'https://loremflickr.com/100/100/man,portrait?lock=402' },
      { name: 'Priya S.', score: 8.9, avatarUrl: 'https://loremflickr.com/100/100/woman,portrait?lock=403' },
    ],
  },
  {
    id: 'c2',
    title: 'Weekly Vocal Showdown',
    category: 'Singing',
    status: 'active',
    featured: false,
    imageUrl: 'https://loremflickr.com/700/440/singer,concert?lock=302',
    prize: '$1,200 + Gift Vouchers',
    endDate: '2026-07-18',
    participants: 860,
    rating: 8.9,
    description: 'Bring your vocal range and stage energy to this week’s singing challenge. Any genre welcome.',
    rules: [
      'One entry per user for this challenge.',
      'Video must be recorded in the Artable in-app studio.',
      'Maximum entry length: 45 seconds.',
      'Backing tracks from the Music Library are allowed.',
    ],
    prizeBreakdown: [
      { place: '1st Place', reward: '$700 + Champion Badge' },
      { place: '2nd Place', reward: '$300 + Voucher' },
      { place: '3rd Place', reward: '$200 + Voucher' },
    ],
    topParticipants: [
      { name: 'Aria N.', score: 9.5, avatarUrl: 'https://loremflickr.com/100/100/woman,portrait?lock=404' },
      { name: 'Devon L.', score: 9.0, avatarUrl: 'https://loremflickr.com/100/100/man,portrait?lock=405' },
    ],
  },
  {
    id: 'c3',
    title: 'Stand-Up Spotlight',
    category: 'Comedy',
    status: 'upcoming',
    featured: false,
    imageUrl: 'https://loremflickr.com/700/440/comedian,standup?lock=303',
    prize: '$800 + Featured Placement',
    endDate: '2026-08-05',
    participants: 210,
    rating: 0,
    description: 'A stage for original stand-up bits, impressions, and sketch comedy. Starts next week — get your material ready.',
    rules: [
      'One entry per user for this challenge.',
      'Video must be recorded in the Artable in-app studio.',
      'Maximum entry length: 90 seconds.',
      'Original material only — no reused clips.',
    ],
    prizeBreakdown: [
      { place: '1st Place', reward: '$500 + Featured Placement' },
      { place: '2nd Place', reward: '$300' },
    ],
    topParticipants: [],
  },
  {
    id: 'c4',
    title: 'Fit Fusion Challenge',
    category: 'Fitness',
    status: 'active',
    featured: false,
    imageUrl: 'https://loremflickr.com/700/440/fitness,workout?lock=304',
    prize: '$1,500 + Sponsor Gear',
    endDate: '2026-07-22',
    participants: 640,
    rating: 8.2,
    description: 'Show your strength, flexibility, or a full routine. Trainers and beginners both welcome.',
    rules: [
      'One entry per user for this challenge.',
      'Video must be recorded in the Artable in-app studio.',
      'Maximum entry length: 60 seconds.',
      'Safety first — no unsupervised extreme stunts.',
    ],
    prizeBreakdown: [
      { place: '1st Place', reward: '$900 + Sponsor Gear' },
      { place: '2nd Place', reward: '$400' },
      { place: '3rd Place', reward: '$200' },
    ],
    topParticipants: [
      { name: 'Leo M.', score: 8.8, avatarUrl: 'https://loremflickr.com/100/100/man,portrait?lock=406' },
    ],
  },
  {
    id: 'c5',
    title: 'Illusions After Dark',
    category: 'Magic',
    status: 'completed',
    featured: false,
    imageUrl: 'https://loremflickr.com/700/440/magician,magic?lock=305',
    prize: '$1,000 + Champion Badge',
    endDate: '2026-06-30',
    participants: 320,
    rating: 9.0,
    description: 'Closed challenge — winners have been announced. Check the Winners page for results.',
    rules: [
      'One entry per user for this challenge.',
      'Video must be recorded in the Artable in-app studio.',
      'Maximum entry length: 60 seconds.',
    ],
    prizeBreakdown: [
      { place: '1st Place', reward: '$600 + Champion Badge' },
      { place: '2nd Place', reward: '$400' },
    ],
    topParticipants: [
      { name: 'Nia P.', score: 9.6, avatarUrl: 'https://loremflickr.com/100/100/woman,portrait?lock=407' },
    ],
  },
  {
    id: 'c6',
    title: 'Canvas & Color Sprint',
    category: 'Art',
    status: 'active',
    featured: true,
    imageUrl: 'https://loremflickr.com/700/440/painter,artist?lock=306',
    prize: '$2,000 + Gallery Feature',
    endDate: '2026-07-28',
    participants: 505,
    rating: 8.5,
    description: 'Speed-paint or timelapse your process — traditional or digital art both accepted.',
    rules: [
      'One entry per user for this challenge.',
      'Video must be recorded in the Artable in-app studio.',
      'Maximum entry length: 60 seconds (timelapse allowed).',
      'Original artwork only.',
    ],
    prizeBreakdown: [
      { place: '1st Place', reward: '$1,200 + Gallery Feature' },
      { place: '2nd Place', reward: '$500' },
      { place: '3rd Place', reward: '$300' },
    ],
    topParticipants: [
      { name: 'Sam T.', score: 9.0, avatarUrl: 'https://loremflickr.com/100/100/man,portrait?lock=408' },
      { name: 'Ivy C.', score: 8.7, avatarUrl: 'https://loremflickr.com/100/100/woman,portrait?lock=409' },
    ],
  },
  {
    id: 'c7',
    title: 'Center Stage Acting Reel',
    category: 'Acting',
    status: 'upcoming',
    featured: false,
    imageUrl: 'https://loremflickr.com/700/440/actor,theater?lock=307',
    prize: '$1,000 + Casting Callback',
    endDate: '2026-08-12',
    participants: 95,
    rating: 0,
    description: 'A monologue or scene challenge for performers. Opens soon — start preparing your piece.',
    rules: [
      'One entry per user for this challenge.',
      'Video must be recorded in the Artable in-app studio.',
      'Maximum entry length: 75 seconds.',
    ],
    prizeBreakdown: [
      { place: '1st Place', reward: '$600 + Casting Callback' },
      { place: '2nd Place', reward: '$400' },
    ],
    topParticipants: [],
  },
  {
    id: 'c8',
    title: 'Street Sports Showdown',
    category: 'Sports',
    status: 'active',
    featured: false,
    imageUrl: 'https://loremflickr.com/700/440/athlete,sports?lock=308',
    prize: '$1,800 + Sponsor Kit',
    endDate: '2026-07-25',
    participants: 715,
    rating: 8.4,
    description: 'Freestyle football, parkour, skateboarding, streetball — any street sport skill goes.',
    rules: [
      'One entry per user for this challenge.',
      'Video must be recorded in the Artable in-app studio.',
      'Maximum entry length: 60 seconds.',
      'Wear appropriate safety gear.',
    ],
    prizeBreakdown: [
      { place: '1st Place', reward: '$1,000 + Sponsor Kit' },
      { place: '2nd Place', reward: '$500' },
      { place: '3rd Place', reward: '$300' },
    ],
    topParticipants: [
      { name: 'Kofi A.', score: 8.9, avatarUrl: 'https://loremflickr.com/100/100/man,portrait?lock=410' },
    ],
  },
];

// Every imageUrl below is a hand-verified, real, free-tier Unsplash CDN
// photo (fetched and confirmed individually — not a keyword-matched
// placeholder API). Chosen to match each reel's talent category so Home
// never shows an irrelevant or broken image.
const REELS = [
  { id: 'r1', title: 'Freestyle finale',    creator: 'Maya R.',  handle: '@dance_hero',   category: 'Dance',   verified: true, imageUrl: 'https://images.unsplash.com/photo-1598963561591-3a14d9ba6a7b?w=320&h=520&q=80&auto=format&fit=crop&crop=faces,entropy', avatarUrl: 'https://i.pravatar.cc/64?u=dance_hero',  views: '1.2M',
    challengeId: 'c1', musicName: 'Original Sound — Maya R.', caption: 'Finally landed the closing spin on the first take! 🔥 #dance #freestyle', likes: '124K', comments: '2.4K', shares: '8.1K', talentScore: 8.7 },
  { id: 'r2', title: 'Crowd-work bit',      creator: 'Theo B.',  handle: '@funny_banda',  category: 'Comedy',  verified: true, imageUrl: 'https://images.unsplash.com/photo-1523970592527-a59047319659?w=320&h=520&q=80&auto=format&fit=crop&crop=faces,entropy', avatarUrl: 'https://i.pravatar.cc/64?u=funny_banda', views: '856K',
    challengeId: 'c3', musicName: 'Original Sound — Theo B.', caption: 'The crowd had no idea what was coming 😂 #comedy #standup', likes: '76K', comments: '1.1K', shares: '3.9K', talentScore: 8.1 },
  { id: 'r3', title: 'Sunset flexibility',  creator: 'Leo M.',   handle: '@fit_beat',     category: 'Fitness', verified: true, imageUrl: 'https://images.unsplash.com/photo-1701824429192-74ad7c2246f0?w=320&h=520&q=80&auto=format&fit=crop&crop=faces,entropy', avatarUrl: 'https://i.pravatar.cc/64?u=fit_beat',    views: '1.5M',
    challengeId: 'c4', musicName: 'Sunset Groove — Mira Wave', caption: 'Six months of mobility work leading to this 🌅 #fitness #flexibility', likes: '142K', comments: '3.2K', shares: '9.4K', talentScore: 9.0 },
  { id: 'r4', title: 'High note challenge', creator: 'Aria N.',  handle: '@music_wave',   category: 'Singing', verified: true, imageUrl: 'https://images.unsplash.com/photo-1696946909078-184cd94d3d45?w=320&h=520&q=80&auto=format&fit=crop&crop=faces,entropy', avatarUrl: 'https://i.pravatar.cc/64?u=music_wave',  views: '980K',
    challengeId: 'c2', musicName: 'Original Sound — Aria N.', caption: 'Hit the high note on the 3rd try, worth it 🎤 #singing #vocals', likes: '98K', comments: '1.8K', shares: '4.5K', talentScore: 8.9 },
  { id: 'r5', title: 'Card trick reveal',   creator: 'Ravi K.',  handle: '@magician.07',  category: 'Magic',   verified: true, imageUrl: 'https://images.unsplash.com/photo-1485936233727-d320af1dadd3?w=320&h=520&q=80&auto=format&fit=crop&crop=faces,entropy', avatarUrl: 'https://i.pravatar.cc/64?u=magician07',  views: '670K',
    challengeId: 'c5', musicName: 'Studio Heat — Nova Beats', caption: 'Watch closely... you still won’t catch it 🎩 #magic #cardtrick', likes: '61K', comments: '980', shares: '2.7K', talentScore: 7.9 },
  { id: 'r6', title: 'Canvas in progress',  creator: 'Nina P.',  handle: '@art_life',     category: 'Art',     verified: true, imageUrl: 'https://images.unsplash.com/photo-1634393295821-70a0dea57209?w=320&h=520&q=80&auto=format&fit=crop&crop=faces,entropy', avatarUrl: 'https://i.pravatar.cc/64?u=art_life',    views: '540K',
    challengeId: 'c6', musicName: 'Golden Hour — Levi Shore', caption: 'Two hours of layering to get this light just right 🎨 #art #painting', likes: '54K', comments: '740', shares: '1.9K', talentScore: 8.4 },
];

// Comments shown on the Comments screen for each reel (keyed by reel id).
const COMMENTS = {
  r1: [
    { id: 'cm1', avatarUrl: 'https://i.pravatar.cc/64?u=priya_v', username: '@priya_v', text: 'That closing spin was insane, you nailed it!', time: '2h', likes: 214 },
    { id: 'cm2', avatarUrl: 'https://i.pravatar.cc/64?u=arjun_p', username: '@arjun_p', text: 'The footwork on beat drop 🔥🔥', time: '3h', likes: 132 },
    { id: 'cm3', avatarUrl: 'https://i.pravatar.cc/64?u=simran_k', username: '@simran_k', text: 'My rating is going straight to a 9', time: '5h', likes: 58 },
    { id: 'cm3a', avatarUrl: 'https://i.pravatar.cc/64?u=karan_shah', username: '@karan_shah', text: 'The way you landed that transition, clean 👏', time: '6h', likes: 41 },
    { id: 'cm3b', avatarUrl: 'https://i.pravatar.cc/64?u=meera_j', username: '@meera_j', text: 'Been practicing this all week, still not this smooth lol', time: '8h', likes: 23 },
  ],
  r2: [
    { id: 'cm4', avatarUrl: 'https://i.pravatar.cc/64?u=rohit_dance', username: '@rohit_dance', text: 'I lost it at the second punchline 😂', time: '1h', likes: 96 },
    { id: 'cm5', avatarUrl: 'https://i.pravatar.cc/64?u=neha_k', username: '@neha_k', text: 'Best crowd work I’ve seen on here', time: '4h', likes: 47 },
  ],
  r3: [
    { id: 'cm6', avatarUrl: 'https://i.pravatar.cc/64?u=vikram_m', username: '@vikram_m', text: 'The control on that hold is unreal', time: '30m', likes: 88 },
    { id: 'cm7', avatarUrl: 'https://i.pravatar.cc/64?u=riya_s', username: '@riya_s', text: 'Sunset lighting made this look cinematic', time: '2h', likes: 61 },
  ],
  r4: [
    { id: 'cm8', avatarUrl: 'https://i.pravatar.cc/64?u=karan_j', username: '@karan_j', text: 'That note gave me chills, wow', time: '1h', likes: 173 },
  ],
  r5: [
    { id: 'cm9', avatarUrl: 'https://i.pravatar.cc/64?u=dev_r', username: '@dev_r', text: 'Rewatched this 5 times and still can’t figure it out', time: '6h', likes: 121 },
  ],
  r6: [
    { id: 'cm10', avatarUrl: 'https://i.pravatar.cc/64?u=ananya_t', username: '@ananya_t', text: 'The color blending here is gorgeous', time: '3h', likes: 39 },
  ],
};

const SHARE_OPTIONS = [
  { id: 'copy',     label: 'Copy Link',    icon: 'link' },
  { id: 'whatsapp', label: 'WhatsApp',     icon: 'whatsapp' },
  { id: 'sms',      label: 'SMS',          icon: 'sms' },
  { id: 'email',    label: 'Email',        icon: 'email' },
  { id: 'social',   label: 'Social Share', icon: 'share' },
];

const REPORT_REASONS = [
  { id: 'spam',         label: 'Spam' },
  { id: 'inappropriate', label: 'Inappropriate Content' },
  { id: 'copyright',    label: 'Copyright Issue' },
  { id: 'other',        label: 'Other' },
];

const QUICK_ACTIONS = [
  { label: 'Upload Video',       icon: 'upload',   href: 'submit-entry.html',            highlight: true, tint: 'red' },
  { label: 'Active Challenges',  icon: 'flame',    href: 'challenges.html?tab=active',   tint: 'purple' },
  { label: 'Winners',            icon: 'medal',    href: '#',                            tint: 'orange' },
  { label: 'Rewards',            icon: 'gift',     href: '#',                            tint: 'green' },
  { label: 'Invite Friends',     icon: 'invite',   href: '#',                            tint: 'blue' },
  { label: 'Leaderboard',        icon: 'chart',    href: '#',                            tint: 'red' },
  { label: 'Music Library',      icon: 'music',    href: '#',                            tint: 'cyan' },
  { label: 'Trending Videos',    icon: 'video',    href: '#',                            tint: 'orange' },
  { label: 'Daily Bonus',        icon: 'calendar', href: '#',                            tint: 'purple' },
  { label: 'My Badges',          icon: 'shield',   href: '#',                            tint: 'blue' },
];

// Compact, Home-only challenge cards — intentionally separate from the
// `CHALLENGES` list used by Challenge List/Detail/Submit (which stays in
// $ with day-based countdowns for consistency across those screens).
// These use ₹ + hour-based countdowns to match the Home reference design.
const HOME_ACTIVE_CHALLENGES = [
  { id: 'c1', title: 'Dance Challenge',   timeLeft: '23h 45m Left', prize: '₹5,000',  imageUrl: 'https://images.unsplash.com/photo-1598963561591-3a14d9ba6a7b?w=400&h=320&q=80&auto=format&fit=crop&crop=faces,entropy' },
  { id: 'c3', title: 'Joke Challenge',    timeLeft: '23h 45m Left', prize: '₹3,000',  imageUrl: 'https://images.unsplash.com/photo-1523970592527-a59047319659?w=400&h=320&q=80&auto=format&fit=crop&crop=faces,entropy' },
  { id: 'c4', title: 'Fitness Challenge', timeLeft: '23h 45m Left', prize: '₹10,000', imageUrl: 'https://images.unsplash.com/photo-1701824429192-74ad7c2246f0?w=400&h=320&q=80&auto=format&fit=crop&crop=faces,entropy' },
  { id: 'c2', title: 'Singing Challenge', timeLeft: '23h 45m Left', prize: '₹5,000',  imageUrl: 'https://images.unsplash.com/photo-1696946909078-184cd94d3d45?w=400&h=320&q=80&auto=format&fit=crop&crop=faces,entropy' },
];

// 5-step explainer strip for Home's "How It Works" section.
const HOW_IT_WORKS = [
  { step: 1, icon: 'upload',  title: 'Upload Your Talent', text: 'Upload a video of your talent in any category.' },
  { step: 2, icon: 'play',    title: 'Get Discovered',     text: 'Your video appears in Trending Reels.' },
  { step: 3, icon: 'star',    title: 'Get Rated',          text: 'Users rate your talent from 1 to 10.' },
  { step: 4, icon: 'trophy',  title: 'Top Talents Win',    text: 'Top rated talents win exciting rewards.' },
  { step: 5, icon: 'gift',    title: 'Win Prizes',         text: 'Cash, gifts, and more amazing rewards.' },
];

// Large-format mega challenge banners shown as a horizontal-scroll strip
// near the top of the promo section on Home (matches the promo-strip
// scroll pattern established for the smaller prize cards below it).
const MEGA_PROMO_BANNERS = [
  {
    tag: 'Monthly Mega Challenge', icon: 'trophy', countdown: '24',
    title: 'WIN iPhone 15', subtitle: '& More Exciting Prizes',
    ctaLabel: 'Join Now',
    imageUrl: 'https://images.unsplash.com/photo-1592286927505-1def25115558?w=300&h=380&q=80&auto=format&fit=crop',
  },
  {
    tag: 'Weekly Cash Challenge', icon: 'star', countdown: '5',
    title: 'WIN $500 Cash', subtitle: 'Every Week, New Winners',
    ctaLabel: 'Join Now',
    imageUrl: 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=300&h=380&q=80&auto=format&fit=crop',
  },
  {
    tag: 'Seasonal Grand Prize', icon: 'gift', countdown: '45',
    title: 'WIN a Dream Trip', subtitle: 'Plus Bonus Wallet Coins',
    ctaLabel: 'Join Now',
    imageUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=300&h=380&q=80&auto=format&fit=crop',
  },
];

const BANNERS = [
  {
    id: 'b1',
    title: 'Monthly Mega Challenge',
    subtitle: 'Win exciting rewards — $5,000 prize pool',
    badge: '12 days left',
    ctaLabel: 'Join Now',
    imageUrl: 'https://loremflickr.com/900/460/concert,stage?lock=601',
    href: 'challenge-detail.html?id=c1',
  },
  {
    id: 'b2',
    title: 'Invite friends, earn coins',
    subtitle: 'Get bonus wallet coins for every signup',
    badge: 'Bonus',
    ctaLabel: 'Invite Now',
    imageUrl: 'https://loremflickr.com/900/460/friends,celebration?lock=602',
    href: '#',
  },
  {
    id: 'b3',
    title: 'Go Prime — Ad-Free',
    subtitle: 'Remove ads and get the diamond badge',
    badge: 'Prime',
    ctaLabel: 'Upgrade',
    imageUrl: 'https://loremflickr.com/900/460/premium,spotlight?lock=603',
    href: '#',
  },
];

/* =========================================================
   Video Recording Studio (module 3) — dummy data only.
   Gallery upload is not allowed anywhere in this module; every
   entry originates from the in-app camera/draft flow.
   ========================================================= */

// Saved drafts recorded in-app, shown on the Draft List screen.
const DRAFTS = [
  { id: 'd1', challengeId: 'c1', challengeTitle: 'Monthly Mega Dance Battle', duration: '0:42', recordedAt: '2026-07-18T17:20:00', thumbnailUrl: 'https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=200&h=280&q=80&auto=format&fit=crop&crop=faces,entropy' },
  { id: 'd2', challengeId: 'c1', challengeTitle: 'Monthly Mega Dance Battle', duration: '0:55', recordedAt: '2026-07-15T09:05:00', thumbnailUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&h=280&q=80&auto=format&fit=crop&crop=faces,entropy' },
  { id: 'd3', challengeId: 'c3', challengeTitle: 'Stand-Up Spotlight',        duration: '0:38', recordedAt: '2026-07-11T20:40:00', thumbnailUrl: 'https://images.unsplash.com/photo-1543269664-56d93c1b41a6?w=200&h=280&q=80&auto=format&fit=crop&crop=faces,entropy' },
];

// Background-music picker: Artable's own royalty-free library, grouped
// into category chips (All / Trending / Bollywood / Romantic / Happy).
const MUSIC_TRACKS = [
  { id: 'm1', title: 'Neon Nights',        artist: 'DJ Kairo',      duration: '0:32', tab: 'trending',  coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=160&h=160&q=80&auto=format&fit=crop' },
  { id: 'm2', title: 'Sunset Groove',      artist: 'Mira Wave',     duration: '0:28', tab: 'trending',  coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=160&h=160&q=80&auto=format&fit=crop' },
  { id: 'm3', title: 'Golden Hour',        artist: 'Levi Shore',    duration: '0:35', tab: 'bollywood', coverUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=160&h=160&q=80&auto=format&fit=crop' },
  { id: 'm4', title: 'Studio Heat',        artist: 'Nova Beats',    duration: '0:30', tab: 'bollywood', coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=160&h=160&q=80&auto=format&fit=crop' },
  { id: 'm5', title: 'Fresh Start',        artist: 'Ari Bloom',     duration: '0:26', tab: 'romantic',  coverUrl: 'https://images.unsplash.com/photo-1496293455970-f8581aae0e3b?w=160&h=160&q=80&auto=format&fit=crop' },
  { id: 'm6', title: 'Midnight Drive',     artist: 'Kaza',          duration: '0:33', tab: 'happy',     coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=160&h=160&q=80&auto=format&fit=crop' },
  { id: 'm7', title: 'Encore',             artist: 'Mira Wave',     duration: '0:29', tab: 'happy',     coverUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=160&h=160&q=80&auto=format&fit=crop' },
];

// Recording filters shown as a carousel on the Effects/Filters screen.
const STUDIO_FILTERS = [
  { id: 'natural', label: 'Natural', swatch: 'linear-gradient(135deg,#DCE3EE,#F4F6FA)' },
  { id: 'glow',    label: 'Glow',    swatch: 'linear-gradient(135deg,#FFE9C7,#FFC369)' },
  { id: 'warm',    label: 'Warm',    swatch: 'linear-gradient(135deg,#FFD3A8,#FF8A5B)' },
  { id: 'studio',  label: 'Studio',  swatch: 'linear-gradient(135deg,#C9C2FF,#8B3DFF)' },
  { id: 'beauty',  label: 'Beauty',  swatch: 'linear-gradient(135deg,#FFD1E3,#FF3D77)' },
  { id: 'mono',    label: 'Mono',    swatch: 'linear-gradient(135deg,#CFCFCF,#5B5B5B)' },
];

/* =========================================================
   Search & Discovery / Leaderboard / Profile (modules 5-7)
   — dummy data only, same shape contract as everything above.
   ========================================================= */

const RECENT_SEARCHES = ['Dance challenge', '@funny_banda', 'Singing tips', 'Weekly Vocal Showdown'];

const POPULAR_SEARCHES = ['Dance', 'Singing', 'Comedy', 'Fitness', 'Magic', 'Art', 'Challenges', 'Rewards'];

// Creator directory — powers Search, Leaderboard, and both Profile screens.
// Handles intentionally match REELS creators where possible so a card in
// one module points at a consistent identity everywhere else.
const CREATORS = [
  { id: 'u1', handle: '@dance_hero', name: 'Maya R.', category: 'Dance', avatarUrl: 'https://i.pravatar.cc/120?u=dance_hero', coverUrl: 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=800&h=360&q=80&auto=format&fit=crop', verified: true, prime: true, talentScore: 9.4, followers: '128K', following: 214, votes: 8420, challengesWon: 5, videos: 34, likes: '1.2M',
    bio: 'Contemporary + street dance. Chasing clean lines and bigger stages.', socialLinks: [{ label: 'Instagram', url: '#' }, { label: 'YouTube', url: '#' }] },
  { id: 'u2', handle: '@fit_beat', name: 'Leo M.', category: 'Fitness', avatarUrl: 'https://i.pravatar.cc/120?u=fit_beat', coverUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&h=360&q=80&auto=format&fit=crop', verified: true, prime: false, talentScore: 9.0, followers: '96K', following: 180, votes: 6210, challengesWon: 3, videos: 28, likes: '860K',
    bio: 'Mobility coach by day, challenge hunter by night.', socialLinks: [{ label: 'Instagram', url: '#' }] },
  { id: 'u3', handle: '@music_wave', name: 'Aria N.', category: 'Singing', avatarUrl: 'https://i.pravatar.cc/120?u=music_wave', coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=360&q=80&auto=format&fit=crop', verified: true, prime: true, talentScore: 8.9, followers: '112K', following: 96, votes: 7040, challengesWon: 4, videos: 22, likes: '980K',
    bio: 'Vocalist. Runs, riffs, and a little too much reverb.', socialLinks: [{ label: 'Instagram', url: '#' }, { label: 'Spotify', url: '#' }] },
  { id: 'u4', handle: '@funny_banda', name: 'Theo B.', category: 'Comedy', avatarUrl: 'https://i.pravatar.cc/120?u=funny_banda', coverUrl: 'https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=800&h=360&q=80&auto=format&fit=crop', verified: true, prime: false, talentScore: 8.7, followers: '74K', following: 302, votes: 5100, challengesWon: 2, videos: 19, likes: '610K',
    bio: 'Crowd work is my cardio.', socialLinks: [{ label: 'Instagram', url: '#' }] },
  { id: 'u5', handle: '@art_life', name: 'Nina P.', category: 'Art', avatarUrl: 'https://i.pravatar.cc/120?u=art_life', coverUrl: 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=800&h=360&q=80&auto=format&fit=crop', verified: true, prime: false, talentScore: 8.4, followers: '58K', following: 140, votes: 4300, challengesWon: 2, videos: 15, likes: '420K',
    bio: 'Oil + light. Two-hour timelapses, zero regrets.', socialLinks: [{ label: 'Instagram', url: '#' }] },
  { id: 'u6', handle: '@magician.07', name: 'Ravi K.', category: 'Magic', avatarUrl: 'https://i.pravatar.cc/120?u=magician07', coverUrl: 'https://images.unsplash.com/photo-1518709594023-6eab9bab7b23?w=800&h=360&q=80&auto=format&fit=crop', verified: true, prime: false, talentScore: 7.9, followers: '41K', following: 88, votes: 3100, challengesWon: 1, videos: 12, likes: '310K',
    bio: 'Close-up magic. You still won’t catch it.', socialLinks: [{ label: 'Instagram', url: '#' }] },
  { id: 'u7', handle: '@you_create', name: 'Arjun P.', category: 'Dance', avatarUrl: 'https://i.pravatar.cc/120?u=you_create', coverUrl: 'https://images.unsplash.com/photo-1504609773096-104ff2c73ba4?w=800&h=360&q=80&auto=format&fit=crop', verified: false, prime: true, talentScore: 7.6, followers: '12.4K', following: 61, votes: 1840, challengesWon: 1, videos: 9, likes: '86K',
    bio: 'Weekend freestyler. Still chasing that first Top 3.', socialLinks: [{ label: 'Instagram', url: '#' }], isCurrentUser: true, joinedDate: '2025-11-02' },
  { id: 'u8', handle: '@priya_moves', name: 'Priya S.', category: 'Dance', avatarUrl: 'https://i.pravatar.cc/120?u=priya_moves', coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=800&h=360&q=80&auto=format&fit=crop', verified: false, prime: false, talentScore: 7.3, followers: '9.8K', following: 220, votes: 1420, challengesWon: 0, videos: 7, likes: '54K',
    bio: 'Just here for the choreography.', socialLinks: [] },
  { id: 'u9', handle: '@kofi_streets', name: 'Kofi A.', category: 'Sports', avatarUrl: 'https://i.pravatar.cc/120?u=kofi_streets', coverUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&h=360&q=80&auto=format&fit=crop', verified: false, prime: false, talentScore: 7.0, followers: '7.1K', following: 95, votes: 990, challengesWon: 0, videos: 5, likes: '31K',
    bio: 'Freestyle football + parkour.', socialLinks: [] },
  { id: 'u10', handle: '@ivy_canvas', name: 'Ivy C.', category: 'Art', avatarUrl: 'https://i.pravatar.cc/120?u=ivy_canvas', coverUrl: 'https://images.unsplash.com/photo-1502691876148-a84978e59af8?w=800&h=360&q=80&auto=format&fit=crop', verified: false, prime: false, talentScore: 6.6, followers: '4.5K', following: 51, votes: 610, challengesWon: 0, videos: 4, likes: '18K',
    bio: 'Watercolor mostly. Coffee always.', socialLinks: [] },
];

const CURRENT_USER_ID = 'u7';

// The logged-in user's own uploads, across every studio/moderation status.
const MY_VIDEOS = [
  { id: 'mv1', challengeId: 'c1', challengeTitle: 'Monthly Mega Dance Battle', thumbnailUrl: 'https://images.unsplash.com/photo-1598963561591-3a14d9ba6a7b?w=320&h=420&q=80&auto=format&fit=crop&crop=faces,entropy', status: 'live', views: '12.4K', talentScore: 8.2, likes: '1.1K', date: '2026-07-10' },
  { id: 'mv2', challengeId: 'c2', challengeTitle: 'Weekly Vocal Showdown', thumbnailUrl: 'https://images.unsplash.com/photo-1696946909078-184cd94d3d45?w=320&h=420&q=80&auto=format&fit=crop&crop=faces,entropy', status: 'under_review', views: '—', talentScore: null, likes: '—', date: '2026-07-18' },
  { id: 'mv3', challengeId: 'c3', challengeTitle: 'Stand-Up Spotlight', thumbnailUrl: 'https://images.unsplash.com/photo-1543269664-56d93c1b41a6?w=320&h=420&q=80&auto=format&fit=crop&crop=faces,entropy', status: 'draft', views: '—', talentScore: null, likes: '—', date: '2026-07-11', draftId: 'd3' },
  { id: 'mv4', challengeId: 'c4', challengeTitle: 'Fit Fusion Challenge', thumbnailUrl: 'https://images.unsplash.com/photo-1701824429192-74ad7c2246f0?w=320&h=420&q=80&auto=format&fit=crop&crop=faces,entropy', status: 'rejected', views: '—', talentScore: null, likes: '—', date: '2026-07-05', rejectReason: 'Video did not meet the content guidelines.' },
  { id: 'mv5', challengeId: 'c6', challengeTitle: 'Canvas & Color Sprint', thumbnailUrl: 'https://images.unsplash.com/photo-1634393295821-70a0dea57209?w=320&h=420&q=80&auto=format&fit=crop&crop=faces,entropy', status: 'live', views: '6.8K', talentScore: 7.4, likes: '540', date: '2026-06-28' },
];

// Badge icon keys reuse quickActionIconSvg()'s icon set — no new SVGs needed.
const BADGES = [
  { id: 'bd1', name: 'First Upload', category: 'participation', earned: true, icon: 'upload', description: 'Uploaded your first talent video.' },
  { id: 'bd2', name: 'Challenge Starter', category: 'participation', earned: true, icon: 'flame', description: 'Joined your first challenge.' },
  { id: 'bd3', name: '5 Challenges Deep', category: 'participation', earned: false, icon: 'calendar', description: 'Enter 5 different challenges.' },
  { id: 'bd4', name: 'Weekly Champion', category: 'winner', earned: true, icon: 'trophy', description: 'Finished #1 in a weekly challenge.' },
  { id: 'bd5', name: 'Monthly Champion', category: 'winner', earned: false, icon: 'crown', description: 'Finish #1 in a monthly challenge.' },
  { id: 'bd6', name: 'Top 3 Finisher', category: 'winner', earned: true, icon: 'medal', description: 'Placed in the top 3 of any challenge.' },
  { id: 'bd7', name: 'Inviter', category: 'referral', earned: false, icon: 'invite', description: 'Invite 5 friends to Artable.' },
  { id: 'bd8', name: 'Super Inviter', category: 'referral', earned: false, icon: 'shield', description: 'Invite 20 friends to Artable.' },
  { id: 'bd9', name: 'Streak Keeper', category: 'activity', earned: true, icon: 'star', description: 'Posted 3 weeks in a row.' },
  { id: 'bd10', name: 'Fan Favorite', category: 'activity', earned: false, icon: 'gift', description: 'Reach 1,000 likes on a single video.' },
  { id: 'bd11', name: 'Rising Voice', category: 'activity', earned: true, icon: 'chart', description: 'Received 100+ ratings on one video.' },
  { id: 'bd12', name: 'Camera Ready', category: 'activity', earned: true, icon: 'video', description: 'Recorded 10 videos in the in-app studio.' },
];

const CREATOR_LEVELS = ['Beginner', 'Rising Star', 'Influencer', 'Champion'];

// 1–10 score distribution (vote counts per score) for the Talent Score screen.
const RATING_DISTRIBUTION = [2, 3, 6, 10, 18, 34, 58, 91, 64, 22];

// Recent challenge results for the logged-in user's Talent Score screen.
const RECENT_PERFORMANCE = [
  { challengeId: 'c1', title: 'Monthly Mega Dance Battle', result: 'Top 10', score: 8.2, date: '2026-07-10' },
  { challengeId: 'c4', title: 'Fit Fusion Challenge', result: 'Not Placed', score: null, date: '2026-07-05' },
  { challengeId: 'c6', title: 'Canvas & Color Sprint', result: 'Top 25', score: 7.4, date: '2026-06-28' },
];

/* =========================================================
   Rewards & Wallet (module 8) — dummy data only.
   Payment/withdrawal is Razorpay per product spec, but this prototype
   only shows UI placeholder state — no real payment calls are made.
   ========================================================= */

const REWARDS = [
  { id: 'rw1', title: 'Weekly Vocal Showdown Cash Prize', type: 'cash', value: '$700', imageUrl: 'https://loremflickr.com/700/440/cash,dollars,money?lock=901',
    status: 'claimed', featured: false, trackable: false, challengeId: 'c2', expiryDate: null,
    description: 'Cash prize awarded for your Top 3 finish in the Weekly Vocal Showdown. Credited to your Artable wallet.',
    eligibility: ['Must be the verified winner of the linked challenge.', 'Reward is credited after result verification.'] },
  { id: 'rw2', title: 'iPhone 15 — Monthly Mega Challenge', type: 'product', value: '$999', imageUrl: 'https://loremflickr.com/700/440/iphone,smartphone,apple?lock=902',
    status: 'locked', featured: true, trackable: true, challengeId: 'c1', expiryDate: '2026-07-31',
    description: 'Grand prize for the Monthly Mega Dance Battle. Unlocks automatically once winners are announced and verified.',
    eligibility: ['Must finish in the Top 3 of Monthly Mega Dance Battle.', 'Winner verification required before claim.', 'One prize per user per challenge.'] },
  { id: 'rw3', title: 'Amazon Gift Card', type: 'voucher', value: '$50', imageUrl: 'https://loremflickr.com/700/440/giftcard,voucher,shopping?lock=903',
    status: 'available', featured: false, trackable: false, challengeId: null, expiryDate: '2026-08-15',
    description: 'A $50 Amazon gift voucher, available to claim now from your rewards balance.',
    eligibility: ['Available to all users with sufficient reward points.', 'Voucher code delivered instantly after claim.'] },
  { id: 'rw4', title: 'Nike Sponsor Kit', type: 'sponsor', sponsorName: 'Nike', value: 'Sponsor Kit', imageUrl: 'https://loremflickr.com/700/440/nike,sneakers,shoes?lock=904',
    status: 'claimed', featured: false, trackable: true, challengeId: 'c8', expiryDate: null,
    description: 'Official sponsor kit awarded for your placement in the Street Sports Showdown, provided by our sponsor partner.',
    eligibility: ['Awarded to top finishers of sponsor-backed challenges.', 'Shipping handled after claim confirmation.'] },
  { id: 'rw5', title: 'Fit Fusion Challenge Cash Prize', type: 'cash', value: '$400', imageUrl: 'https://loremflickr.com/700/440/cash,banknotes,prize?lock=905',
    status: 'available', featured: false, trackable: false, challengeId: 'c4', expiryDate: '2026-07-30',
    description: 'Cash prize for your result in the Fit Fusion Challenge. Claim now to credit it to your wallet.',
    eligibility: ['Must be a verified placed finisher.', 'Claim before the expiry date shown.'] },
  { id: 'rw6', title: 'Spotify Premium (1 Year)', type: 'voucher', value: '$120', imageUrl: 'https://loremflickr.com/700/440/headphones,music,audio?lock=906',
    status: 'available', featured: false, trackable: false, challengeId: null, expiryDate: '2026-09-01',
    description: 'One year of Spotify Premium, redeemable instantly from your rewards balance.',
    eligibility: ['Available to all users with sufficient reward points.', 'Redemption code delivered instantly after claim.'] },
  { id: 'rw7', title: 'Canon Camera — Art Challenge Prize', type: 'product', value: '$650', imageUrl: 'https://loremflickr.com/700/440/camera,dslr,photography?lock=907',
    status: 'locked', featured: false, trackable: true, challengeId: 'c6', expiryDate: '2026-07-28',
    description: 'Prize camera for the Canvas & Color Sprint challenge. Unlocks once challenge winners are verified.',
    eligibility: ['Must finish in the Top 3 of Canvas & Color Sprint.', 'Winner verification required before claim.'] },
  { id: 'rw8', title: 'Dance Battle Winner Reward', type: 'cash', value: '$500', imageUrl: 'https://loremflickr.com/700/440/trophy,cash,prize?lock=908',
    status: 'available', featured: false, trackable: false, challengeId: 'c1', expiryDate: '2026-08-05',
    description: 'Cash prize for your result in the Monthly Mega Dance Battle. Claim now to credit it to your wallet.',
    eligibility: ['Must be a verified placed finisher.', 'Claim before the expiry date shown.'] },
  { id: 'rw9', title: 'Food Delivery Voucher', type: 'voucher', value: '$25', imageUrl: 'https://loremflickr.com/700/440/food,delivery,takeout?lock=909',
    status: 'available', featured: false, trackable: false, challengeId: null, expiryDate: '2026-08-20',
    description: 'A $25 food delivery voucher, available to claim now from your rewards balance.',
    eligibility: ['Available to all users with sufficient reward points.', 'Voucher code delivered instantly after claim.'] },
  { id: 'rw10', title: 'Smart Watch — Fitness Challenge Prize', type: 'product', value: '$250', imageUrl: 'https://loremflickr.com/700/440/smartwatch,wearable,tech?lock=910',
    status: 'available', featured: false, trackable: true, challengeId: 'c4', expiryDate: '2026-08-10',
    description: 'Prize smartwatch for the Fit Fusion Challenge. Ready to claim after winner verification.',
    eligibility: ['Must finish in the Top 3 of Fit Fusion Challenge.', 'Winner verification required before claim.'] },
  { id: 'rw11', title: 'Music Creator Pack', type: 'sponsor', sponsorName: 'SoundWave Audio', value: 'Sponsor Kit', imageUrl: 'https://loremflickr.com/700/440/music,studio,headphones?lock=911',
    status: 'available', featured: false, trackable: true, challengeId: 'c2', expiryDate: null,
    description: 'Sponsor creator kit awarded for your placement in the Weekly Vocal Showdown, provided by our sponsor partner.',
    eligibility: ['Awarded to top finishers of sponsor-backed challenges.', 'Shipping handled after claim confirmation.'] },
  { id: 'rw12', title: 'Fitness Brand Kit', type: 'sponsor', sponsorName: 'FlexFit Gear', value: 'Sponsor Kit', imageUrl: 'https://loremflickr.com/700/440/fitness,gym,sportswear?lock=912',
    status: 'locked', featured: false, trackable: true, challengeId: 'c4', expiryDate: null,
    description: 'Sponsor gear kit for the Fit Fusion Challenge. Unlocks once challenge winners are verified.',
    eligibility: ['Must finish in the Top 3 of Fit Fusion Challenge.', 'Winner verification required before claim.'] },
];

const WALLET_SUMMARY = {
  availableBalance: '$1,240', pendingRewards: '$400', totalWithdrawn: '$2,860', totalEarned: '$4,500',
  minWithdrawal: '$50', challengeWins: '$1,900', referralRewards: '$150', dailyBonus: '$40', sponsorRewards: '$650',
};

const TRANSACTIONS = [
  { id: 'tx1', title: 'Challenge Winner Reward', category: 'challenge_win', type: 'credit', amount: '+$700', date: '2026-07-10T14:20:00', status: 'completed', rewardId: 'rw1' },
  { id: 'tx2', title: 'Referral Bonus', category: 'referral', type: 'credit', amount: '+$50', date: '2026-07-08T09:00:00', status: 'completed' },
  { id: 'tx3', title: 'Daily Bonus', category: 'daily_bonus', type: 'credit', amount: '+$10', date: '2026-07-07T08:15:00', status: 'completed' },
  { id: 'tx4', title: 'Withdrawal Request', category: 'withdrawal', type: 'withdrawn', amount: '-$500', date: '2026-07-05T11:30:00', status: 'completed' },
  { id: 'tx5', title: 'Gift Voucher Redeemed', category: 'voucher', type: 'debit', amount: '-$50', date: '2026-07-03T16:45:00', status: 'completed' },
  { id: 'tx6', title: 'Challenge Winner Reward', category: 'challenge_win', type: 'pending', amount: '+$400', date: '2026-07-18T20:00:00', status: 'pending', rewardId: 'rw5' },
  { id: 'tx7', title: 'Referral Bonus', category: 'referral', type: 'credit', amount: '+$50', date: '2026-06-30T10:00:00', status: 'completed' },
  { id: 'tx8', title: 'Withdrawal Request', category: 'withdrawal', type: 'pending', amount: '-$300', date: '2026-07-20T09:00:00', status: 'pending' },
];

// Physical/sponsor prize shipment tracking, keyed by rewardId.
const PRIZE_TRACKING = {
  rw4: {
    prizeName: 'Nike Sponsor Kit', challengeName: 'Street Sports Showdown', winnerDate: '2026-07-02',
    status: 'shipped', estimatedDate: '2026-07-25', trackingId: 'ATB-8834-IN',
  },
};

/* =========================================================
   Module 9 — Winners
   ========================================================= */
const WINNERS = [
  { id: 'w1', userId: 'u1', challengeId: 'c1', reelId: 'r1', rank: 1, prize: '$2,500 + Champion Badge', talentScore: 9.4, avgRating: 9.4, totalVotes: 8420, winDate: '2026-07-15', period: 'monthly', featured: true },
  { id: 'w2', userId: 'u3', challengeId: 'c2', reelId: 'r4', rank: 1, prize: '$700 Cash Prize', talentScore: 8.9, avgRating: 8.9, totalVotes: 7040, winDate: '2026-07-10', period: 'weekly', featured: false },
  { id: 'w3', userId: 'u4', challengeId: 'c3', reelId: 'r2', rank: 2, prize: '$1,500 + Rising Star Badge', talentScore: 8.7, avgRating: 8.6, totalVotes: 5100, winDate: '2026-07-08', period: 'challenge', featured: false },
  { id: 'w4', userId: 'u2', challengeId: 'c4', reelId: 'r3', rank: 1, prize: '$400 Cash Prize', talentScore: 9.0, avgRating: 9.0, totalVotes: 6210, winDate: '2026-07-05', period: 'weekly', featured: false },
  { id: 'w5', userId: 'u9', challengeId: 'c8', reelId: null, rank: 3, prize: 'Nike Sponsor Kit', talentScore: 7.0, avgRating: 7.2, totalVotes: 990, winDate: '2026-07-02', period: 'challenge', featured: false },
  { id: 'w6', userId: 'u5', challengeId: 'c6', reelId: 'r6', rank: 1, prize: '$650 Camera Prize', talentScore: 8.4, avgRating: 8.4, totalVotes: 4300, winDate: '2026-06-28', period: 'monthly', featured: false },
];

/* =========================================================
   Module 10 — Invite & Referral
   ========================================================= */
const REFERRAL_SUMMARY = { code: 'ARTABLE2026', totalInvites: 18, joinedUsers: 9, rewardsEarned: '$45', pendingRewards: '$15' };
const REFERRAL_MILESTONE = { current: 9, next: 10, nextReward: '$10 Bonus' };
const REFERRAL_LIST = [
  { id: 'rf1', userId: 'u8', status: 'rewarded', date: '2026-07-12', amount: '$5' },
  { id: 'rf2', userId: 'u9', status: 'joined', date: '2026-07-14', amount: '—' },
  { id: 'rf3', userId: 'u10', status: 'invited', date: '2026-07-16', amount: '—' },
  { id: 'rf4', userId: 'u2', status: 'rewarded', date: '2026-07-01', amount: '$5' },
  { id: 'rf5', userId: 'u4', status: 'joined', date: '2026-07-05', amount: '—' },
];

/* =========================================================
   Module 11 — Music Library
   ========================================================= */
const MUSIC_LIBRARY_TRACKS = [
  { id: 'ml1', title: 'Neon Nights', artist: 'Wave Riders', coverUrl: 'https://loremflickr.com/300/300/music,neon?lock=1001', duration: '2:45', durationSec: 165, category: 'trending', saved: true },
  { id: 'ml2', title: 'Golden Hour', artist: 'Skyline Collective', coverUrl: 'https://loremflickr.com/300/300/music,sunset?lock=1002', duration: '3:12', durationSec: 192, category: 'trending', saved: false },
  { id: 'ml3', title: 'Street Pulse', artist: 'Bass Theory', coverUrl: 'https://loremflickr.com/300/300/music,urban?lock=1003', duration: '2:58', durationSec: 178, category: 'trending', saved: false },
  { id: 'ml4', title: 'Velvet Groove', artist: 'Nina Cross', coverUrl: 'https://loremflickr.com/300/300/music,studio?lock=1004', duration: '3:30', durationSec: 210, category: 'popular', saved: true },
  { id: 'ml5', title: 'Electric Bloom', artist: 'Aria Nova', coverUrl: 'https://loremflickr.com/300/300/music,concert?lock=1005', duration: '2:20', durationSec: 140, category: 'popular', saved: false },
  { id: 'ml6', title: 'Afterglow', artist: 'Lumen', coverUrl: 'https://loremflickr.com/300/300/music,vinyl?lock=1006', duration: '3:05', durationSec: 185, category: 'new', saved: false },
  { id: 'ml7', title: 'Wildfire', artist: 'Echo Park', coverUrl: 'https://loremflickr.com/300/300/music,guitar?lock=1007', duration: '2:50', durationSec: 170, category: 'new', saved: false },
  { id: 'ml8', title: 'Midnight Drive', artist: 'Solstice', coverUrl: 'https://loremflickr.com/300/300/music,headphones?lock=1008', duration: '3:18', durationSec: 198, category: 'popular', saved: true },
];

/* =========================================================
   Module 12 — Daily Bonus
   ========================================================= */
const DAILY_BONUS = {
  currentStreak: 5,
  claimedToday: false,
  todayReward: { label: 'Day 6 Reward', amount: '60 Coins' },
  nextMilestone: { day: 7, reward: '150 Coins + Badge' },
  weeklyRewards: [
    { day: 1, amount: 10 }, { day: 2, amount: 20 }, { day: 3, amount: 30 },
    { day: 4, amount: 40 }, { day: 5, amount: 50 }, { day: 6, amount: 60 }, { day: 7, amount: 150 },
  ],
  milestones: [
    { days: 3, reward: '50 Bonus Coins', achieved: true },
    { days: 7, reward: '150 Coins + Badge', achieved: false },
    { days: 15, reward: 'Reward Entry Ticket', achieved: false },
    { days: 30, reward: '7-Day Prime Trial', achieved: false },
  ],
  totalDays: 30,
};

/* =========================================================
   Module 13 — Notifications & Activity
   ========================================================= */
const NOTIFICATIONS = [
  { id: 'n1', category: 'challenges', icon: 'trophy', title: 'Challenge ending soon', description: 'Monthly Mega Dance Battle ends in 2 days — submit your entry!', time: '2h ago', read: false },
  { id: 'n2', category: 'rewards', icon: 'cash', title: 'Reward credited', description: '$700 has been added to your wallet.', time: '5h ago', read: false },
  { id: 'n3', category: 'winners', icon: 'trophy', title: 'Winners announced', description: 'Weekly Vocal Showdown winners are live now.', time: '1d ago', read: false },
  { id: 'n4', category: 'social', icon: 'heartFilled', title: 'New like on your video', description: 'Priya S. liked your entry "Freestyle finale".', time: '1d ago', read: true, avatarId: 'u8' },
  { id: 'n5', category: 'referrals', icon: 'follow', title: 'Referral joined', description: 'Kofi A. joined using your invite code.', time: '2d ago', read: true, avatarId: 'u9' },
  { id: 'n6', category: 'social', icon: 'comment', title: 'New comment', description: '"Amazing moves!" — Theo B. commented on your video.', time: '3d ago', read: true, avatarId: 'u4' },
  { id: 'n7', category: 'rewards', icon: 'gift', title: 'Daily bonus ready', description: 'Your daily bonus is ready to claim.', time: '3d ago', read: true },
];

const ACTIVITY_SUMMARY = { likes: 142, comments: 38, ratings: 96, entries: 12, rewardsEarned: '$1,650' };
const ACTIVITY_LOG = [
  { id: 'a1', type: 'likes', icon: 'heartFilled', text: 'Priya S. liked your video', related: '"Freestyle finale"', time: '2h ago', avatarId: 'u8' },
  { id: 'a2', type: 'comments', icon: 'comment', text: 'Theo B. commented on your video', related: '"Amazing moves!"', time: '5h ago', avatarId: 'u4' },
  { id: 'a3', type: 'ratings', icon: 'star', text: 'You received a new rating', related: '9.2 / 10 on "Freestyle finale"', time: '1d ago' },
  { id: 'a4', type: 'challenges', icon: 'trophy', text: 'You submitted an entry', related: 'Monthly Mega Dance Battle', time: '2d ago' },
  { id: 'a5', type: 'rewards', icon: 'cash', text: 'Reward credited to wallet', related: '+$50 Daily Bonus', time: '3d ago' },
  { id: 'a6', type: 'likes', icon: 'heartFilled', text: 'Kofi A. liked your video', related: '"Freestyle finale"', time: '4d ago', avatarId: 'u9' },
];

/* =========================================================
   Module 14 — Subscription / Membership
   ========================================================= */
const MEMBERSHIP = {
  currentPlan: 'basic',
  primePrice: '$3.99',
  primePeriod: '/month',
  basicFeatures: ['Standard profile identity', 'Ads shown between videos', 'Core challenge access', 'Standard wallet & rewards'],
  primeFeatures: ['Ad-free experience', 'Diamond profile badge', 'Premium identity across app', 'Priority customer support'],
  comparison: [
    { feature: 'Ads', basic: 'Shown', prime: 'None' },
    { feature: 'Profile Badge', basic: 'Standard', prime: 'Diamond' },
    { feature: 'Challenge Access', basic: 'Standard', prime: 'Standard' },
    { feature: 'Support', basic: 'Standard', prime: 'Priority' },
  ],
};

/* =========================================================
   Module 15 — Settings & Support
   ========================================================= */
const NOTIFICATION_SETTINGS = [
  { id: 'challenges', icon: 'trophy', title: 'Challenge Updates', desc: 'New challenges, deadlines, and results.', enabled: true },
  { id: 'rewards', icon: 'gift', title: 'New Rewards', desc: 'When new rewards become available.', enabled: true },
  { id: 'winners', icon: 'crown', title: 'Winner Announcements', desc: 'When challenge winners are announced.', enabled: true },
  { id: 'social', icon: 'heartFilled', title: 'Likes & Comments', desc: 'Activity on your videos and profile.', enabled: true },
  { id: 'referrals', icon: 'follow', title: 'Referral Rewards', desc: 'Updates on friends you’ve invited.', enabled: false },
  { id: 'dailyBonus', icon: 'flame', title: 'Daily Bonus Reminder', desc: 'A nudge to claim your daily streak bonus.', enabled: true },
  { id: 'membership', icon: 'diamond', title: 'Membership Updates', desc: 'Prime membership news and billing updates.', enabled: false },
];

const PRIVACY_SETTINGS = {
  profileVisibility: 'public',
  showTalentScore: true,
  showRewardEarnings: false,
  allowComments: true,
  allowShares: true,
  allowProfileSearch: true,
  blockedUsersCount: 2,
};

const HELP_TOPICS = [
  { id: 'challenges', icon: 'trophy', title: 'Challenge Participation' },
  { id: 'studio', icon: 'camera', title: 'Recording Studio' },
  { id: 'rewards', icon: 'wallet', title: 'Rewards & Wallet' },
  { id: 'prime', icon: 'diamond', title: 'Prime Membership' },
  { id: 'account', icon: 'lock', title: 'Account & Privacy' },
];

const HELP_FAQS = [
  { id: 'faq1', q: 'How are winners selected?', a: 'Winners are selected based on average talent ratings, total votes, and the specific criteria set for each challenge.' },
  { id: 'faq2', q: 'Why is gallery upload not allowed?', a: 'To keep challenges fair and authentic, entries must be recorded live using the in-app Studio rather than uploaded from your gallery.' },
  { id: 'faq3', q: 'How do rewards work?', a: 'Rewards are earned by winning challenges, referring friends, and daily engagement. Track them anytime from your Wallet and Rewards screens.' },
  { id: 'faq4', q: 'How can I withdraw wallet balance?', a: 'Open Wallet, tap Withdraw, and follow the steps to request a payout to your linked account.' },
  { id: 'faq5', q: 'How do I upgrade to Prime?', a: 'Go to Settings → Membership, or open the Membership screen, and tap Upgrade to Prime to unlock an ad-free experience and your diamond badge.' },
];

// Standard "not built yet" placeholder — used by inert quick-action links.
function comingSoon(e) {
  e.preventDefault();
  // TODO(api): route to the real module once it exists.
}
