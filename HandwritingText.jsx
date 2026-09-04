const { useEffect, useRef, useState } = React;

const OPENTYPE_CDN = "https://cdn.jsdelivr.net/npm/opentype.js@1.3.4/dist/opentype.min.js";
const DEFAULT_FONT_URL =
  "https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/caveat/Caveat%5Bwght%5D.ttf";

let libPromise = null;

function loadOpentype() {
  if (typeof window === "undefined") return Promise.reject(new Error("no window"));
  if (window.opentype) return Promise.resolve(window.opentype);
  if (!libPromise) {
    libPromise = new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = OPENTYPE_CDN;
      script.async = true;
      script.onload = () => {
        if (window.opentype) resolve(window.opentype);
        else reject(new Error("opentype.js loaded but exposed nothing"));
      };
      script.onerror = () => reject(new Error("opentype.js failed to load"));
      document.head.appendChild(script);
    });
  }
  return libPromise;
}

const fontCache = new Map();

function loadFont(url) {
  let pending = fontCache.get(url);
  if (!pending) {
    pending = Promise.all([
      loadOpentype(),
      fetch(url).then((res) => {
        if (!res.ok) throw new Error("Font request failed: " + res.status);
        return res.arrayBuffer();
      }),
    ]).then(([lib, buffer]) => lib.parse(buffer));
    fontCache.set(url, pending);
  }
  return pending;
}

const EM = 100;
const num = (v, d) => (v === undefined || v === null || v === "" ? d : Number(v));

// pathLength="1" normalises every contour so one keyframe fits all of them. The
// keyframes are rendered INSIDE the svg: the design's content can live in its own
// style scope, where a document.head injection would never reach.
const KEYFRAMES =
  "@keyframes hwInk{from{stroke-dashoffset:1}to{stroke-dashoffset:0}}" +
  "@keyframes hwFill{from{opacity:0}to{opacity:1}}";

function HandwritingText(props) {
  const {
    text,
    words,
    fontUrl = DEFAULT_FONT_URL,
    fill = true,
    height = "1.15em",
    className,
    style,
  } = props;
  const interval = num(props.interval, 3200);
  const duration = num(props.duration, 1.5);
  const delay = num(props.delay, 0.05);
  const strokeWidth = num(props.strokeWidth, 1.6);

  const list = Array.isArray(words) ? words : null;
  const cycle = Boolean(list && list.length > 0);
  const [index, setIndex] = useState(0);
  const current = cycle ? list[index % list.length] : text ?? "";

  const [font, setFont] = useState(null);
  const [geom, setGeom] = useState(null);

  useEffect(() => {
    if (!cycle) return undefined;
    const id = setInterval(() => setIndex((i) => i + 1), interval);
    return () => clearInterval(id);
  }, [cycle, interval]);

  useEffect(() => {
    let cancelled = false;
    loadFont(fontUrl)
      .then((f) => { if (!cancelled) setFont(f); })
      .catch(() => {});
    return () => { cancelled = true; };
  }, [fontUrl]);

  useEffect(() => {
    if (!font || !current) return;
    const path = font.getPath(current, 0, EM, EM);
    const box = path.getBoundingBox();
    const pad = EM * 0.12;
    const full = path.toPathData(2);
    setGeom({
      full,
      contours: full.split(/(?=M)/).filter((d) => d.trim().length > 1),
      x: box.x1 - pad,
      y: box.y1 - pad,
      w: box.x2 - box.x1 + pad * 2,
      h: box.y2 - box.y1 + pad * 2,
    });
  }, [font, current]);

  if (!geom) {
    return <span className={className} style={style}>{current}</span>;
  }

  const count = Math.max(1, geom.contours.length);

  return (
    <svg
      key={current}
      viewBox={geom.x + " " + geom.y + " " + geom.w + " " + geom.h}
      role="img"
      aria-label={current}
      className={className}
      style={Object.assign({
        display: "inline-block",
        height,
        width: "calc(" + height + " * " + (geom.w / geom.h).toFixed(4) + ")",
        overflow: "visible",
      }, style)}
    >
      <style>{KEYFRAMES}</style>
      {fill && (
        <path
          d={geom.full}
          fill="currentColor"
          stroke="none"
          style={{
            opacity: 1,
            animation: "hwFill 0.45s ease-out " + (delay + duration * 0.72).toFixed(3) + "s both",
          }}
        />
      )}
      {geom.contours.map((d, i) => {
        const each = (duration / count) * 2.4;
        const start = delay + (i / count) * duration;
        return (
          <path
            key={i}
            d={d}
            pathLength="1"
            fill="none"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{
              strokeDasharray: 1,
              strokeDashoffset: 0,
              animation: "hwInk " + each.toFixed(3) + "s ease-out " + start.toFixed(3) + "s both",
            }}
          />
        );
      })}
    </svg>
  );
}

module.exports = { HandwritingText };
