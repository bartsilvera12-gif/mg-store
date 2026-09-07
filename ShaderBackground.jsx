// ShaderBackground — Mesh gradient (CSS radial-gradient blobs).
// Renders a slow-drifting multicolor mesh in MG Store's palette. Pure CSS +
// tiny JS driver: no WebGL, no dependencies, plays nice with reduced motion.
const { useEffect, useRef } = React;

// MG palette (must match the site tokens).
const COLORS = {
  navyDeep: "#071433",
  navy:     "#0B1F5F",
  blue:     "#1B49D6",
  cyanHi:   "#6CBDED",
  green:    "#1EB531",
  white:    "#FFFFFF",
};

// Each blob: fractional viewport position (x, y in %), radius %, RGBA color,
// and a per-axis phase offset that drives the drift animation.
const BLOBS = [
  { color: COLORS.blue,    x: 20, y: 30, r: 55, alpha: 0.85, ax: 1.0, ay: 0.7 },
  { color: COLORS.cyanHi,  x: 78, y: 18, r: 48, alpha: 0.55, ax: 1.3, ay: 1.1 },
  { color: COLORS.green,   x: 68, y: 74, r: 46, alpha: 0.55, ax: 0.8, ay: 1.4 },
  { color: COLORS.blue,    x: 12, y: 82, r: 42, alpha: 0.60, ax: 1.6, ay: 0.9 },
  { color: COLORS.white,   x: 40, y: 55, r: 28, alpha: 0.16, ax: 0.5, ay: 1.7 },
  { color: COLORS.navy,    x: 90, y: 92, r: 40, alpha: 0.75, ax: 1.2, ay: 0.6 },
];

// Turn "#RRGGBB" + alpha into an rgba() string.
function rgba(hex, a) {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
}

function buildBackground(blobs) {
  // radial-gradient at each blob, tinting outward to transparent; the last
  // layer is the base navy so the frame never punches through to page bg.
  const layers = blobs.map(
    (b) =>
      `radial-gradient(${b.r}% ${b.r}% at ${b.x.toFixed(2)}% ${b.y.toFixed(2)}%, ` +
      `${rgba(b.color, b.alpha)} 0%, ${rgba(b.color, 0)} 70%)`
  );
  layers.push(`linear-gradient(180deg, ${COLORS.navyDeep} 0%, ${COLORS.navy} 100%)`);
  return layers.join(", ");
}

function ShaderBackground({ className, style }) {
  const rootRef = useRef(null);

  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    const reduce =
      typeof window !== "undefined" &&
      window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      root.style.background = buildBackground(BLOBS);
      return;
    }
    let raf = 0;
    let visible = document.visibilityState === "visible";
    const start = performance.now();

    // Drift each blob on its own Lissajous track. Amplitudes are % of viewport,
    // periods are ~18-32s so the motion reads slow and organic.
    const step = (now) => {
      raf = 0;
      if (!visible) return;
      const t = (now - start) / 1000;
      const drifted = BLOBS.map((b) => ({
        ...b,
        x: b.x + Math.sin(t * 0.13 * b.ax + b.ax * 2.1) * 6.5,
        y: b.y + Math.cos(t * 0.11 * b.ay + b.ay * 1.3) * 5.5,
      }));
      root.style.background = buildBackground(drifted);
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);

    const onVis = () => {
      visible = document.visibilityState === "visible";
      if (visible && raf === 0) raf = requestAnimationFrame(step);
      else if (!visible && raf !== 0) { cancelAnimationFrame(raf); raf = 0; }
    };
    document.addEventListener("visibilitychange", onVis);
    return () => {
      cancelAnimationFrame(raf);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, []);

  return (
    <div
      ref={rootRef}
      className={className}
      style={Object.assign(
        {
          display: "block",
          width: "100%",
          height: "100%",
          background: buildBackground(BLOBS),
          transition: "background 0.05s linear",
        },
        style
      )}
    />
  );
}

module.exports = { ShaderBackground };
