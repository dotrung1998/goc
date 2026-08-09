import { useGoc } from '../state/GocContext.jsx';
import { bg } from '../data/events.js';
import { paper, ink, FACE, display, fieldGlass, cardGlass } from '../theme.js';

export default function Reserve() {
  const {
    state, T, trStatus, curEvent: ev, backToEvent,
    qtyMinus, qtyPlus, pickPayNow, pickHold, formNameType, formEmailType, submitReserve, emailValid,
  } = useGoc();
  const s = state;

  const formOk = !!(s.formName.trim() && emailValid(s.formEmail));
  const priceNum = parseInt((ev.price.match(/[\d.]+/) || ['0'])[0].replace(/\./g, ''), 10) || 0;
  const isFree = /Miễn phí/.test(ev.price);
  const totalStr = isFree ? 'Miễn phí' : (priceNum * s.qty).toLocaleString('vi-VN') + '₫';
  const qtyTotalLabel = s.qty > 1 ? (T('Tổng ', 'Total ') + trStatus(totalStr)) : trStatus(ev.price);

  const reserveBtnLabel = s.payMode === 'now' ? (T('Trả ngay ▪︎ ', 'Pay now ▪︎ ') + trStatus(totalStr)) : T('Giữ chỗ ▪︎ tối đa 24h', 'Hold ▪︎ up to 24h');
  const reserveBtnStyle = {
    margin: '18px 22px 0', fontSize: 15, fontWeight: 600, textAlign: 'center', padding: 16, borderRadius: 999,
    background: formOk ? ink : 'rgba(27,25,22,0.16)',
    color: formOk ? paper : ink,
    cursor: formOk ? 'pointer' : 'default', transition: 'background .15s',
  };

  const dotStyle = (on) => ({ width: 15, height: 15, borderRadius: '50%', border: on ? `4px solid ${ink}` : `1.5px solid ${ink}` });
  const cardStyle = (on) => ({ ...cardGlass({ padding: '13px 15px', display: 'flex', flexDirection: 'column', gap: 5, cursor: 'pointer' }), border: on ? `1.5px solid ${ink}` : '1px solid rgba(27,25,22,0.16)' });

  return (
    <div style={{ animation: 'gocIn 0.32s cubic-bezier(.22,.61,.36,1) both', minHeight: '100%', background: paper }} data-screen-label="Reserve">
      <div onClick={backToEvent} style={{ padding: '70px 22px 0', fontSize: 12, color: ink, cursor: 'pointer' }}>‹ {T('Quay lại', 'Back')}</div>
      <div style={{ padding: '16px 22px 0' }}>
        <h2 style={{ ...display(24, { margin: 0 }) }}>{T('Gần xong rồi.', 'Almost there.')}</h2>
      </div>
      <div style={{ ...fieldGlass({ display: 'flex', gap: 14, alignItems: 'center', margin: '18px 22px 0', padding: 13 }) }}>
        <div style={bg(ev.img, { flex: 'none', width: 52, height: 52 })} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2, minWidth: 0 }}>
          <span style={{ ...display(15) }}>{ev.name}</span>
          <span style={{ fontSize: 11.5, color: ink }}>{ev.when} ▪︎ {s.qty} chỗ ▪︎ {trStatus(totalStr)}</span>
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, margin: '20px 22px 0' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
          <label style={{ fontSize: 11.5, color: ink }}>{T('Tên', 'Name')}</label>
          <input value={s.formName} onChange={formNameType} placeholder="Tên của bạn" style={inputStyle} />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
          <label style={{ fontSize: 11.5, color: ink }}>Email</label>
          <input value={s.formEmail} onChange={formEmailType} placeholder="ban@email.com" style={inputStyle} />
        </div>
      </div>
      <div style={{ margin: '22px 22px 0' }}>
        <span style={{ fontSize: 11.5, fontWeight: 600, color: ink }}>{T('Số vé', 'Tickets')}</span>
        <div style={{ ...fieldGlass({ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 12, padding: '12px 14px' }) }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <span style={{ fontSize: 14, fontWeight: 600, color: ink }}>{s.qty} {T('vé', 'tickets')}</span>
            <span style={{ fontSize: 11.5, color: ink }}>{qtyTotalLabel}</span>
          </div>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <span onClick={qtyMinus} style={{ width: 32, height: 32, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, cursor: s.qty > 1 ? 'pointer' : 'default', color: s.qty > 1 ? ink : 'rgba(27,25,22,0.16)', border: '1px solid rgba(27,25,22,0.16)', userSelect: 'none' }}>−</span>
            <span style={{ ...display(18, { minWidth: 20, textAlign: 'center' }) }}>{s.qty}</span>
            <span onClick={qtyPlus} style={{ width: 32, height: 32, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, cursor: s.qty < 6 ? 'pointer' : 'default', color: s.qty < 6 ? ink : 'rgba(27,25,22,0.16)', border: '1px solid rgba(27,25,22,0.16)', userSelect: 'none' }}>+</span>
          </div>
        </div>
      </div>
      <div style={{ margin: '22px 22px 0' }}>
        <span style={{ fontSize: 11.5, fontWeight: 600, color: ink }}>{T('Cách giữ chỗ', 'How to reserve')}</span>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 12 }}>
          <div onClick={pickPayNow} style={cardStyle(s.payMode === 'now')}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 14, fontWeight: 600, color: ink }}>{T('Trả ngay', 'Pay now')}</span>
              <span style={dotStyle(s.payMode === 'now')} />
            </div>
            <span style={{ fontSize: 12, lineHeight: 1.5, color: ink }}>
              {T('Chỗ xác nhận ngay. Trả ' + trStatus(ev.price) + ' qua MoMo, VNPay, ZaloPay, HaloPay, Apple Pay hoặc thẻ.', 'Seat confirmed instantly. Pay ' + trStatus(ev.price) + ' via MoMo, VNPay, ZaloPay, HaloPay, Apple Pay or card.')}
            </span>
          </div>
          <div onClick={pickHold} style={cardStyle(s.payMode === 'hold')}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 14, fontWeight: 600, color: ink }}>{T('Giữ tạm', 'Hold')}</span>
              <span style={dotStyle(s.payMode === 'hold')} />
            </div>
            <span style={{ fontSize: 12, lineHeight: 1.5, color: ink }}>
              {T('Giữ chỗ tối đa 24h. Link thanh toán gửi qua email, không trả là chỗ tự nhả.', 'Held for up to 24h. Payment link by email; unpaid holds release.')}
            </span>
          </div>
        </div>
      </div>
      <div onClick={() => submitReserve(formOk)} style={reserveBtnStyle}>{reserveBtnLabel}</div>
      {s.payMode === 'now' && (
        <div style={{ margin: '18px 22px 0' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ flex: 1, height: 1, background: 'rgba(27,25,22,0.16)' }} />
            <span style={{ fontSize: 11.5, color: ink }}>{T('Trả ngay qua', 'Pay via')}</span>
            <span style={{ flex: 1, height: 1, background: 'rgba(27,25,22,0.16)' }} />
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 12 }}>
            <span style={{ ...payChip, color: '#A50064' }}>MoMo</span>
            <span style={{ ...payChip, color: '#005BAA' }}>VNPay</span>
            <span style={{ ...payChip, color: '#0068FF' }}>ZaloPay</span>
            <span style={{ ...payChip, color: '#E8792A' }}>HaloPay</span>
            <span style={{ ...payChip, color: ink }}>Apple Pay</span>
            <span style={{ ...payChip, color: ink }}>{T('Thẻ', 'Card')}</span>
          </div>
        </div>
      )}
      <div style={{ height: 40 }} />
    </div>
  );
}

const inputStyle = { ...fieldGlass({ padding: '13px 14px', border: 'none' }), fontSize: 14, fontFamily: FACE, color: ink, outline: 'none' };
const payChip = { ...fieldGlass({ padding: '10px 0', border: 'none' }), flex: 1, minWidth: 88, textAlign: 'center', fontSize: 12, fontWeight: 600 };
