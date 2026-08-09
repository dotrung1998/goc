import { useGoc } from '../state/GocContext.jsx';
import { paper, ink, rule, display, cardGlass, inkButton } from '../theme.js';

export default function Confirmed() {
  const { state, T, trStatus, curEvent: ev, goHome, payHoldNow, addToCalendar, giveTicket } = useGoc();
  const s = state;

  const priceNum = parseInt((ev.price.match(/[\d.]+/) || ['0'])[0].replace(/\./g, ''), 10) || 0;
  const isFree = /Miễn phí/.test(ev.price);
  const totalStr = isFree ? 'Miễn phí' : (priceNum * s.qty).toLocaleString('vi-VN') + '₫';

  const holdActive = s.payMode === 'hold' && s.holdDeadline && s.holdDeadline > s.now;
  const ms = Math.max(0, (s.holdDeadline || 0) - s.now);
  const m = Math.floor(ms / 60000), sec = Math.floor((ms % 60000) / 1000);
  const countdown = String(m).padStart(2, '0') + ':' + String(sec).padStart(2, '0');

  const name = s.formName.trim() || T('Bạn', 'You');
  const confirmEyebrow = s.payMode === 'now' ? T('Xong rồi!', 'All set!') : T('Đang giữ chỗ cho bạn', 'Holding your spot');
  const confirmHeading = s.payMode === 'now'
    ? (name + T(', ' + (s.qty > 1 ? s.qty + ' chỗ của bạn đã sẵn sàng rồi.' : 'chỗ của bạn đã sẵn sàng rồi.'), ', your ' + (s.qty > 1 ? s.qty + ' seats are' : 'seat is') + ' ready to go.'))
    : (name + T(', ' + (s.qty > 1 ? s.qty + ' chỗ của bạn được giữ trong 1 giờ tới.' : 'chỗ của bạn được giữ trong 1 giờ tới.'), ', your ' + (s.qty > 1 ? s.qty + ' seats are' : 'seat is') + ' held for the next hour.'));
  const confirmNote = s.payMode === 'now'
    ? T('Biên nhận và địa chỉ chính xác đã gửi tới ' + (s.formEmail.trim() || 'email của bạn') + '.', 'Receipt and the exact address were sent to ' + (s.formEmail.trim() || 'your email') + '.')
    : T('Link thanh toán ' + totalStr + ' đã gửi tới ' + (s.formEmail.trim() || 'email của bạn') + '. Không trả trong 1 giờ thì chỗ tự nhả.', 'A payment link for ' + trStatus(totalStr) + ' was sent to ' + (s.formEmail.trim() || 'your email') + '. Unpaid holds release after 1 hour.');

  const showQr = s.payMode === 'now';
  const giveLabel = s.gaveTicket ? T('Đã gửi vé ▪︎ link qua Zalo', 'Ticket sent ▪︎ link via Zalo') : T('Tặng vé cho bạn bè', 'Give a ticket to a friend');
  const calendarLabel = s.calAdded ? T('Đã thêm vào lịch', 'Added to calendar') : T('Thêm vào lịch', 'Add to calendar');

  return (
    <div style={{ animation: 'gocIn 0.32s cubic-bezier(.22,.61,.36,1) both', minHeight: '100%', background: paper, display: 'flex', flexDirection: 'column' }} data-screen-label="Confirmed">
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '60px 30px 0' }}>
        <span style={{ fontSize: 11.5, color: ink }}>{confirmEyebrow}</span>
        <h2 style={{ ...display(27, { lineHeight: 1.35, margin: '12px 0 0' }) }}>{confirmHeading}</h2>
        <p style={{ fontSize: 13.5, lineHeight: 1.55, color: ink, margin: '18px 0 0' }}>{confirmNote}</p>
        {holdActive && (
          <>
            <div style={{ ...cardGlass({ marginTop: 22, padding: '16px 18px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }) }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                <span style={{ fontSize: 11.5, fontWeight: 600, color: ink }}>{T('Giữ chỗ còn', 'Hold expires in')}</span>
                <span style={{ fontSize: 11.5, color: ink }}>{T('Trả trước khi hết giờ để xác nhận', 'Pay before it runs out to confirm')}</span>
              </div>
              <span style={{ ...display(30, { fontVariantNumeric: 'tabular-nums' }) }}>{countdown}</span>
            </div>
            <div onClick={payHoldNow} style={{ ...inkButton({ marginTop: 10, borderRadius: 18, padding: 14, fontSize: 14 }) }}>{T('Trả ngay', 'Pay now')} {trStatus(totalStr)}</div>
          </>
        )}
        <div style={{ marginTop: 28, borderTop: `1px solid ${rule}`, paddingTop: 14, display: 'flex', justifyContent: 'space-between', gap: 14, alignItems: 'center' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, minWidth: 0 }}>
            <span style={{ ...display(17) }}>{ev.name}</span>
            <span style={{ fontSize: 12, color: ink }}>{ev.where}</span>
            {showQr && <span style={{ fontSize: 10.5, color: ink }}>{T('Đưa mã này ở cửa', 'Show this code at the door')}</span>}
          </div>
          {showQr && <QrCode eventKey={ev.key} />}
        </div>
      </div>
      {showQr && (
        <div onClick={() => giveTicket(ev)} style={{ borderTop: `1px solid ${rule}`, color: ink, fontSize: 13.5, textAlign: 'center', padding: '17px 0', cursor: 'pointer' }}>{giveLabel}</div>
      )}
      <div onClick={addToCalendar} style={{ borderTop: `1px solid ${rule}`, color: ink, fontSize: 13.5, textAlign: 'center', padding: '17px 0', cursor: 'pointer' }}>{calendarLabel}</div>
      <div onClick={goHome} style={{ borderTop: `1px solid ${rule}`, color: ink, fontSize: 13.5, textAlign: 'center', padding: '17px 0 34px', cursor: 'pointer' }}>{T('Về trang chính', 'Back to home')}</div>
    </div>
  );
}

function QrCode({ eventKey }) {
  let seed = 0;
  for (const ch of eventKey) seed = (seed * 31 + ch.charCodeAt(0)) % 9973;
  let cells = '';
  for (let y = 0; y < 15; y++) {
    for (let x = 0; x < 15; x++) {
      seed = (seed * 137 + 11) % 9973;
      const corner = (x < 4 && y < 4) || (x > 10 && y < 4) || (x < 4 && y > 10);
      const on = corner ? ((x === 0 || y === 0 || x === 3 || y === 3 || (x > 0 && x < 3 && y > 0 && y < 3)) && !(x > 10 && y > 10)) : seed % 2;
      if (on) cells += '<rect x="' + x + '" y="' + y + '" width="1" height="1"/>';
    }
  }
  const src = 'data:image/svg+xml,' + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 15 15" fill="' + paper + '">' + cells + '</svg>');
  return (
    <div style={{ flex: 'none', width: 76, height: 76, background: ink, padding: 6, backgroundImage: 'url(' + src + ')', backgroundSize: '76px 76px', backgroundRepeat: 'no-repeat', backgroundPosition: 'center', backgroundOrigin: 'content-box', backgroundClip: 'content-box' }} />
  );
}
