const { useEffect, useRef, useState } = React;

/**
 * Vertical/horizontal infinite marquee. Children are rendered twice and the track
 * is translated by rAF so the speed can change mid-flight (on hover) with no jump.
 */
function MarqueeEffect(props) {
  const {
    children,
    gap = 16,
    direction = "horizontal",
    reverse = false,
    className,
    style,
  } = props;
  const speed = Number(props.speed ?? 100);
  const speedOnHover = props.speedOnHover === undefined ? null : Number(props.speedOnHover);

  const trackRef = useRef(null);
  const offset = useRef(0);
  const hovering = useRef(false);
  const [, force] = useState(0);

  useEffect(() => {
    let raf;
    let last = performance.now();
    const step = (now) => {
      const dt = (now - last) / 1000;
      last = now;
      const el = trackRef.current;
      if (el) {
        const total = direction === "vertical" ? el.scrollHeight : el.scrollWidth;
        const half = total / 2;
        if (half > 0) {
          const v = hovering.current && speedOnHover !== null ? speedOnHover : speed;
          offset.current += v * dt * (reverse ? -1 : 1);
          if (offset.current > half) offset.current -= half;
          if (offset.current < 0) offset.current += half;
          const d = -offset.current;
          el.style.transform =
            direction === "vertical" ? "translateY(" + d + "px)" : "translateX(" + d + "px)";
        }
      }
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [speed, speedOnHover, direction, reverse]);

  const vertical = direction === "vertical";

  return (
    <div
      className={className}
      style={Object.assign({ overflow: "hidden" }, style)}
      onMouseEnter={() => { hovering.current = true; force((n) => n + 1); }}
      onMouseLeave={() => { hovering.current = false; force((n) => n + 1); }}
    >
      <div
        ref={trackRef}
        style={{
          display: "flex",
          flexDirection: vertical ? "column" : "row",
          gap: gap + "px",
          width: vertical ? "100%" : "max-content",
          willChange: "transform",
        }}
      >
        {children}
        {children}
      </div>
    </div>
  );
}

module.exports = { MarqueeEffect };
