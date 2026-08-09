import { useGoc } from '../state/GocContext.jsx';
import { paper, ink } from '../theme.js';

export default function Splash() {
  const { dismissSplash } = useGoc();

  return (
    <div
      onClick={dismissSplash}
      style={{
        position: 'absolute', inset: 0, zIndex: 40, background: paper, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', cursor: 'pointer', animation: 'gocFade 0.4s ease both',
      }}
      data-screen-label="Splash"
    >
      <img src="/goc-logo-t.png" alt="Góc" crossOrigin="anonymous" style={{ width: 190, height: 'auto', display: 'block', animation: 'gocIn 0.7s cubic-bezier(.22,.61,.36,1) both' }} />
      <span style={{ fontFamily: "'Caveat',cursive", fontSize: 31, fontWeight: 600, color: ink, marginTop: 8, transform: 'rotate(-2.5deg)', animation: 'gocFade 0.9s ease 0.5s both' }}>a say có society</span>
      <svg viewBox="0 0 36 36" style={{ width: 28, height: 28, marginTop: 34, animation: 'gocOrbit 1.7s linear infinite, gocFade 0.6s ease 1s both' }}>
        <path d="M18 3 a15 15 0 0 1 15 15" fill="none" stroke={ink} strokeWidth="2" strokeLinecap="round" />
        <path d="M18 33 a15 15 0 0 1 -15 -15" fill="none" stroke={ink} strokeWidth="2" strokeLinecap="round" />
      </svg>
    </div>
  );
}
