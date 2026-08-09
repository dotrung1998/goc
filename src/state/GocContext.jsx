import { createContext, useContext, useEffect, useMemo, useState, useCallback, useRef } from 'react';
import { EVENTS as STATIC_EVENTS, findEvent as findStaticEvent } from '../data/events.js';
import { supabase } from '../lib/supabase.js';

const GocCtx = createContext(null);

const initialState = {
  screen: 'splash',
  mode: 'goer',
  hasHosted: false,
  eventKey: 'bepnho',
  loading: false,
  filter: 'all',
  formName: '',
  formEmail: '',
  chatDraft: '',
  chatBack: 'organizer',
  chats: {
    bepnho: [
      { who: 'host', text: 'Chào bạn, mình là Minh. Cứ hỏi thoải mái nhé.' },
      { who: 'me', text: 'Tối thứ bảy còn chỗ cho 2 người không anh?' },
      { who: 'host', text: 'Còn đúng 2 chỗ, mình giữ cho bạn nhé.' },
    ],
    orbit: [
      { who: 'host', text: 'Rue Miche đây. Có gì cần hỏi về buổi diễn không?' },
      { who: 'me', text: 'Dress code có gì đặc biệt không?' },
    ],
  },
  shared: false,
  attending: ['bepnho', 'orbit'],
  tickets: { bepnho: 2, orbit: 1 },
  located: null,
  askingLocation: false,
  user: null,
  loginEmail: '',
  payMode: 'now',
  qty: 1,
  lang: 'vi',
  area: 'all',
  createName: '',
  createCats: [],
  createPalette: 'concrete',
  createSent: false,
  createDesc: '',
  createLoc: '',
  createDate: '',
  createPrice: '',
  createSeats: '',
  createPhotos: 0,
  orgRegName: '',
  orgRegIg: '',
  orgRegDesc: '',
  following: [],
  refunds: {},
  gaveTicket: false,
  areaAsking: false,
  holdDeadline: null,
  now: Date.now(),
  favorites: ['bepnho', 'bandai', 'motlop'],
  invited: ['banrieng'],
  orgVerifyRequested: false,
  attendanceEventKey: null,
  checkins: {},
  calAdded: false,
};

export const AREAS = [
  { key: 'all', label: 'Toàn Sài Gòn', match: () => true },
  { key: 'q1', label: 'Quận 1', match: e => e.meta.includes('Quận 1') },
  { key: 'thaodien', label: 'Thảo Điền', match: e => e.meta.includes('Thảo Điền') },
  { key: 'binhthanh', label: 'Bình Thạnh', match: e => e.meta.includes('Bình Thạnh') },
  { key: 'other', label: 'Quận khác', match: e => !e.meta.includes('Quận 1') && !e.meta.includes('Thảo Điền') && !e.meta.includes('Bình Thạnh') },
  { key: 'danang', label: 'Đà Nẵng', match: () => false },
];

export function GocProvider({ children }) {
  const [state, setStateRaw] = useState(initialState);

  const set = useCallback((partial) => {
    setStateRaw(prev => ({ ...prev, ...(typeof partial === 'function' ? partial(prev) : partial) }));
  }, []);

  useEffect(() => {
    const id = setInterval(() => {
      setStateRaw(prev => (prev.holdDeadline ? { ...prev, now: Date.now() } : prev));
    }, 1000);
    return () => clearInterval(id);
  }, []);

  const splashTimer = useRef(null);
  useEffect(() => {
    splashTimer.current = setTimeout(() => {
      setStateRaw(prev => (prev.screen === 'splash' ? { ...prev, screen: 'home' } : prev));
    }, 2600);
    return () => clearTimeout(splashTimer.current);
  }, []);
  const dismissSplash = useCallback(() => {
    clearTimeout(splashTimer.current);
    set(prev => (prev.screen === 'splash' ? { screen: 'home' } : {}));
  }, [set]);

  const s = state;
  const EN = s.lang === 'en';
  const T = useCallback((vi, en) => (EN ? en : vi), [EN]);

  const trStatus = useCallback((str) => {
    if (!EN) return str;
    return String(str)
      .replace(/Còn (\d+) chỗ/g, '$1 seats left')
      .replace(/Còn (\d+) ngày/g, 'In $1 days')
      .replace(/Hôm nay/g, 'Today').replace(/Ngày mai/g, 'Tomorrow')
      .replace(/(\d+) giờ trước/g, '$1h ago').replace(/(\d+) ngày trước/g, '$1d ago')
      .replace(/1 giờ trước/g, '1h ago').replace(/1 ngày trước/g, '1d ago')
      .replace(/Hết chỗ/g, 'Sold out').replace(/Đã hủy/g, 'Cancelled')
      .replace(/Đã hoàn tiền/g, 'Refunded').replace(/Đã diễn ra/g, 'Ended')
      .replace(/Đang giữ/g, 'On hold').replace(/Đã thanh toán/g, 'Paid')
      .replace(/Đã lưu/g, 'Saved').replace(/Đang tham gia/g, 'Going')
      .replace(/Trả để xác nhận/g, 'Pay to confirm')
      .replace(/(\d+) vé/g, '$1 tix')
      .replace(/Miễn phí/g, 'Free')
      .replace(/ km từ bạn/g, ' km away')
      .replace(/từ bạn/g, 'away')
      .replace(/Thời trang/g, 'Fashion')
      .replace(/Phòng tranh/g, 'Gallery')
      .replace(/^Nhạc$/g, 'Music').replace(/ ▪︎ Nhạc/g, ' ▪︎ Music');
  }, [EN]);

  const located = s.located === true;
  const stripKm = useCallback((str) => (located ? str : str.replace(/ ▪︎ \d+[.,]\d+ km(?: từ bạn| away)?/g, '')), [located]);

  const curEvent = useMemo(() => findEvent(s.eventKey), [s.eventKey]);
  const palette = curEvent.palette;

  const isSaved = useCallback((k) => s.favorites.includes(k), [s.favorites]);
  const isGoing = useCallback((k) => s.attending.includes(k), [s.attending]);
  const toggleFav = useCallback((k) => set(prev => ({ favorites: prev.favorites.includes(k) ? prev.favorites.filter(x => x !== k) : [...prev.favorites, k] })), [set]);
  const toggleFollow = useCallback((k) => set(prev => ({ following: prev.following.includes(k) ? prev.following.filter(x => x !== k) : [...prev.following, k] })), [set]);

  const curArea = AREAS.find(a => a.key === s.area) || AREAS[0];

  // ---- navigation ----
  const goHome = useCallback(() => set({ screen: 'home' }), [set]);
  const goProfile = useCallback(() => set({ screen: 'profile' }), [set]);
  const goInbox = useCallback(() => set({ screen: 'inbox' }), [set]);
  const goEvent = useCallback((key) => set({ screen: 'event', eventKey: key }), [set]);
  const goOrganizer = useCallback(() => set({ screen: 'organizer' }), [set]);
  const goReserve = useCallback(() => set({ screen: 'reserve' }), [set]);
  const backToEvent = useCallback(() => set({ screen: 'event' }), [set]);
  const backToOrganizer = useCallback(() => set({ screen: 'organizer' }), [set]);
  const goChat = useCallback(() => set({ screen: s.user ? 'chat' : 'login', chatBack: 'organizer' }), [set, s.user]);
  const goLogin = useCallback(() => set({ screen: 'login' }), [set]);
  const goDashboard = useCallback(() => set({ screen: 'dashboard' }), [set]);
  const goCreate = useCallback(() => set({ screen: 'create' }), [set]);
  const openAttendance = useCallback((key) => set({ screen: 'attendance', attendanceEventKey: key }), [set]);
  const openHeld = useCallback(() => set({ screen: 'confirmed' }), [set]);
  const goHostIntro = useCallback(() => set({ screen: 'hostIntro' }), [set]);
  const createBack = useCallback(() => set(prev => ({ screen: prev.hasHosted ? 'dashboard' : 'hostIntro' })), [set]);

  // ---- roles ----
  const switchToHost = useCallback(() => set({ mode: 'host', screen: 'dashboard' }), [set]);
  const switchToGoer = useCallback(() => set({ mode: 'goer', screen: 'home' }), [set]);
  const becomeHost = useCallback(() => set({ screen: 'hostIntro' }), [set]);
  const logout = useCallback(() => set({ user: null, mode: 'goer', screen: 'home' }), [set]);

  // ---- lang / area / location ----
  const toggleLang = useCallback(() => set({ lang: EN ? 'vi' : 'en' }), [set, EN]);
  const openArea = useCallback(() => set({ areaAsking: true }), [set]);
  const pickArea = useCallback((key) => set({ area: key, areaAsking: false }), [set]);
  const allowLocation = useCallback(() => {
    set({ askingLocation: false, areaAsking: false, located: true });
    if (navigator.geolocation) navigator.geolocation.getCurrentPosition(() => {}, () => {});
  }, [set]);
  const denyLocation = useCallback(() => set({ askingLocation: false, located: false }), [set]);

  // ---- filter ----
  const pickFilter = useCallback((key) => set({ filter: key }), [set]);
  const clearFilters = useCallback(() => set({ filter: 'all', area: 'all' }), [set]);

  // ---- share ----
  const shareEvent = useCallback((ev) => {
    const url = 'https://gocsociety.com/' + ev.key;
    const done = () => {
      set({ shared: true });
      setTimeout(() => set({ shared: false }), 1800);
    };
    if (navigator.share) {
      navigator.share({ title: 'Góc ▪︎ ' + ev.name, text: ev.name + ' ▪︎ ' + ev.where, url }).catch(done);
    } else if (navigator.clipboard) {
      navigator.clipboard.writeText(url).then(done, done);
    } else { done(); }
  }, [set]);

  // ---- reserve ----
  const qtyMinus = useCallback(() => set(prev => ({ qty: Math.max(1, prev.qty - 1) })), [set]);
  const qtyPlus = useCallback(() => set(prev => ({ qty: Math.min(6, prev.qty + 1) })), [set]);
  const pickPayNow = useCallback(() => set({ payMode: 'now' }), [set]);
  const pickHold = useCallback(() => set({ payMode: 'hold' }), [set]);
  const formNameType = useCallback((e) => set({ formName: e.target.value }), [set]);
  const formEmailType = useCallback((e) => set({ formEmail: e.target.value }), [set]);
  const submitReserve = useCallback(async (formOk) => {
    if (!formOk) return;
    set({ loading: true });

    const payModeMapped = s.payMode === 'hold' ? 'hold_24h' : 'now';
    const formName = s.formName.trim() || 'Goer';
    const formEmail = s.formEmail.trim() || 'goer@gocsociety.com';

    try {
      // Call atomic stored procedure reserve_event_tickets on Supabase
      const { data, error } = await supabase.rpc('reserve_event_tickets', {
        p_event_id: s.eventKey,
        p_user_name: formName,
        p_user_email: formEmail,
        p_user_phone: '',
        p_qty: s.qty,
        p_pay_mode: payModeMapped,
      });

      if (error) {
        console.warn('Supabase RPC reserve_event_tickets fallback:', error.message);
      } else if (data?.success) {
        console.log('Atomic reservation successful:', data);
      }
    } catch (err) {
      console.warn('Supabase reservation error, proceeding with local optimistic state:', err);
    } finally {
      set(prev => ({
        loading: false,
        screen: 'confirmed',
        holdDeadline: prev.payMode === 'hold' ? Date.now() + 24 * 60 * 60 * 1000 : null,
        now: Date.now(),
        tickets: { ...prev.tickets, [prev.eventKey]: prev.qty },
        attending: prev.attending.includes(prev.eventKey) ? prev.attending : [...prev.attending, prev.eventKey],
        user: { name: formName, email: formEmail, via: 'email' },
      }));
    }
  }, [set, s.payMode, s.formName, s.formEmail, s.eventKey, s.qty]);

  const payHoldNow = useCallback(() => set({ holdDeadline: null, payMode: 'now' }), [set]);
  const addToCalendar = useCallback(() => set({ calAdded: true }), [set]);
  const giveTicket = useCallback((ev) => {
    const url = 'https://gocsociety.com/ve/' + ev.key + '-x7f2';
    if (navigator.share) navigator.share({ title: 'Góc ▪︎ ' + ev.name, text: T('Mình có vé cho bạn', 'I have a ticket for you'), url }).catch(() => {});
    else if (navigator.clipboard) navigator.clipboard.writeText(url).catch(() => {});
    set({ gaveTicket: true });
    setTimeout(() => set({ gaveTicket: false }), 2200);
  }, [set, T]);

  // ---- login ----
  const loginEmailType = useCallback((e) => set({ loginEmail: e.target.value }), [set]);
  const emailValid = (v) => /\S+@\S+\.\S+/.test(v);
  const loginEmailSubmit = useCallback(async () => {
    if (emailValid(s.loginEmail)) {
      const email = s.loginEmail.trim();
      try {
        await supabase.auth.signInWithOtp({ email });
      } catch (e) {
        console.log('Magic link login trigger:', e);
      }
      set({ user: { email, via: 'email' }, screen: 'chat' });
    }
  }, [set, s.loginEmail]);
  const loginEmailKey = useCallback((e) => { if (e.key === 'Enter') loginEmailSubmit(); }, [loginEmailSubmit]);
  const loginZalo = useCallback(() => set({ user: { name: 'Zalo', via: 'zalo' }, screen: 'chat' }), [set]);
  const loginPhone = useCallback(() => set({ user: { name: 'Phone', via: 'phone' }, screen: 'chat' }), [set]);
  const loginFacebook = useCallback(() => set({ user: { name: 'Facebook', via: 'facebook' }, screen: 'chat' }), [set]);
  const loginInstagram = useCallback(() => set({ user: { name: 'Instagram', via: 'instagram' }, screen: 'chat' }), [set]);

  // ---- chat ----
  const chatOnType = useCallback((e) => set({ chatDraft: e.target.value }), [set]);
  const chatSend = useCallback(() => {
    set(prev => {
      const t = prev.chatDraft.trim();
      if (!t) return prev;
      const chatKey = prev.eventKey;
      const ev = findEvent(chatKey);
      const thread = prev.chats[chatKey] || [{ who: 'host', text: ev.greeting }];
      return { chatDraft: '', chats: { ...prev.chats, [chatKey]: [...thread, { who: 'me', text: t }] } };
    });
  }, [set]);
  const chatOnKey = useCallback((e) => { if (e.key === 'Enter') chatSend(); }, [chatSend]);
  const chatBackFn = useCallback(() => set(prev => ({ screen: prev.chatBack === 'inbox' ? 'inbox' : 'organizer' })), [set]);
  const openChatFor = useCallback((key, back) => set({ screen: 'chat', eventKey: key, chatBack: back || 'organizer' }), [set]);

  // ---- create / org profile ----
  const orgRegNameType = useCallback((e) => set({ orgRegName: e.target.value }), [set]);
  const orgRegIgType = useCallback((e) => set({ orgRegIg: e.target.value }), [set]);
  const orgRegDescType = useCallback((e) => set({ orgRegDesc: e.target.value }), [set]);
  const createNameType = useCallback((e) => set({ createName: e.target.value }), [set]);
  const createDescType = useCallback((e) => set({ createDesc: e.target.value }), [set]);
  const createLocType = useCallback((e) => set({ createLoc: e.target.value }), [set]);
  const createDateType = useCallback((e) => set({ createDate: e.target.value }), [set]);
  const createPriceType = useCallback((e) => set({ createPrice: e.target.value }), [set]);
  const createSeatsType = useCallback((e) => set({ createSeats: e.target.value }), [set]);
  const pickCreateCat = useCallback((key) => set(prev => {
    let cats = prev.createCats.includes(key) ? prev.createCats.filter(x => x !== key) : [...prev.createCats, key];
    if (cats.length > 2) cats = [cats[0], key];
    return { createCats: cats };
  }), [set]);
  const pickCreatePalette = useCallback((key) => set({ createPalette: key }), [set]);
  const tapPhotoSlot = useCallback((index) => set(prev => ({ createPhotos: index < prev.createPhotos ? prev.createPhotos : Math.min(8, prev.createPhotos + 1) })), [set]);
  const createSubmit = useCallback(() => { if (s.createName.trim()) set({ createSent: true, hasHosted: true, mode: 'host' }); }, [set, s.createName]);
  const requestVerify = useCallback(() => set({ orgVerifyRequested: true }), [set]);

  // ---- attendance ----
  const toggleCheckin = useCallback(async (eventKey, guestId, checked) => {
    set(prev => ({ checkins: { ...prev.checkins, [eventKey]: { ...(prev.checkins[eventKey] || {}), [guestId]: !checked } } }));
    try {
      if (!checked) {
        // If guestId is a valid UUID or reservation id, execute atomic check-in
        await supabase.rpc('check_in_guest', { p_reservation_id: guestId }).catch(() => {});
      }
    } catch (e) {
      console.log('Check-in RPC sync:', e);
    }
  }, [set]);

  const value = useMemo(() => ({
    state: s, set, EN, T, trStatus, located, stripKm, curEvent, palette, curArea,
    isSaved, isGoing, toggleFav, toggleFollow,
    goHome, goProfile, goInbox, goEvent, goOrganizer, goReserve, backToEvent, backToOrganizer,
    goChat, goLogin, goDashboard, goCreate, openAttendance, openHeld, goHostIntro, createBack,
    switchToHost, switchToGoer, becomeHost, logout, dismissSplash,
    toggleLang, openArea, pickArea, allowLocation, denyLocation,
    pickFilter, clearFilters, shareEvent,
    qtyMinus, qtyPlus, pickPayNow, pickHold, formNameType, formEmailType, submitReserve, payHoldNow,
    addToCalendar, giveTicket,
    loginEmailType, loginEmailSubmit, loginEmailKey, loginZalo, loginPhone, loginFacebook, loginInstagram, emailValid,
    chatOnType, chatSend, chatOnKey, chatBackFn, openChatFor,
    orgRegNameType, orgRegIgType, orgRegDescType,
    createNameType, createDescType, createLocType, createDateType, createPriceType, createSeatsType,
    pickCreateCat, pickCreatePalette, tapPhotoSlot, createSubmit, requestVerify,
    toggleCheckin,
  }), [
    s, set, EN, T, trStatus, located, stripKm, curEvent, palette, curArea,
    isSaved, isGoing, toggleFav, toggleFollow,
    goHome, goProfile, goInbox, goEvent, goOrganizer, goReserve, backToEvent, backToOrganizer,
    goChat, goLogin, goDashboard, goCreate, openAttendance, openHeld, goHostIntro, createBack,
    switchToHost, switchToGoer, becomeHost, logout, dismissSplash,
    toggleLang, openArea, pickArea, allowLocation, denyLocation,
    pickFilter, clearFilters, shareEvent,
    qtyMinus, qtyPlus, pickPayNow, pickHold, formNameType, formEmailType, submitReserve, payHoldNow,
    addToCalendar, giveTicket,
    loginEmailType, loginEmailSubmit, loginEmailKey, loginZalo, loginPhone, loginFacebook, loginInstagram,
    chatOnType, chatSend, chatOnKey, chatBackFn, openChatFor,
    orgRegNameType, orgRegIgType, orgRegDescType,
    createNameType, createDescType, createLocType, createDateType, createPriceType, createSeatsType,
    pickCreateCat, pickCreatePalette, tapPhotoSlot, createSubmit, requestVerify,
    toggleCheckin,
  ]);

  return <GocCtx.Provider value={value}>{children}</GocCtx.Provider>;
}

export function useGoc() {
  const ctx = useContext(GocCtx);
  if (!ctx) throw new Error('useGoc must be used within GocProvider');
  return ctx;
}

export { EVENTS };
