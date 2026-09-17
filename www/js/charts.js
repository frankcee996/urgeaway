/* ==========================================================================
   Charts — small, dependency-free SVG components for the "premium" visual
   language (glowing rings, radar/spider chart). Pure rendering helpers;
   they take already-computed numbers and never touch Data/Storage
   themselves, so any screen can reuse them with its own real stats.
   ========================================================================== */

// A single glowing progress ring with centered label/sublabel text.
// opts: { percent (0-100), size (px), strokeWidth (px), colorVar (CSS var
// name, e.g. '--cyan'), label (big text), sublabel (small text below) }
function ringSvg(opts) {
  const size = opts.size || 120;
  const stroke = opts.strokeWidth || 10;
  const r = (size - stroke) / 2;
  const c = size / 2;
  const circumference = 2 * Math.PI * r;
  const pct = Math.max(0, Math.min(100, opts.percent || 0));
  const dash = (pct / 100) * circumference;
  const colorVar = opts.colorVar || '--cyan';

  const wrap = fmt(`
    <div class="glow-ring" style="--glow-color:var(${colorVar});width:${size}px;height:${size}px;">
      <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
        <circle cx="${c}" cy="${c}" r="${r}" fill="none" stroke="var(--bg-3)" stroke-width="${stroke}"/>
        <circle cx="${c}" cy="${c}" r="${r}" fill="none" stroke="var(${colorVar})" stroke-width="${stroke}"
          stroke-linecap="round" stroke-dasharray="${dash} ${circumference}"
          transform="rotate(-90 ${c} ${c})"/>
      </svg>
      <div class="glow-ring-center">
        ${opts.label != null ? `<div style="font-family:var(--font-display);font-weight:800;font-size:${Math.round(size * 0.19)}px;color:var(--text-0);line-height:1;">${opts.label}</div>` : ''}
        ${opts.sublabel ? `<div style="color:var(--text-2);font-size:${Math.max(9, Math.round(size * 0.075))}px;font-weight:600;margin-top:4px;">${opts.sublabel}</div>` : ''}
      </div>
    </div>
  `);
  return wrap;
}

// Radar/spider chart. axes: [{ label, value }] where value is 0-100.
// Renders a glowing filled polygon over N spokes, with axis labels placed
// around the outside — same visual language as the reference screenshot's
// "Relationship / Intellect / Discipline" chart, but generalized to any
// number of axes >= 3.
function renderRadarChart(axes, opts) {
  opts = opts || {};
  const size = opts.size || 240;
  const c = size / 2;
  const maxR = c - (opts.labelPad || 36);
  const rings = opts.rings || 4;
  const colorVar = opts.colorVar || '--cyan';
  const n = axes.length;

  function pointFor(i, valueFrac) {
    const angle = -Math.PI / 2 + (i / n) * 2 * Math.PI;
    return {
      x: c + Math.cos(angle) * maxR * valueFrac,
      y: c + Math.sin(angle) * maxR * valueFrac,
    };
  }

  // Grid rings (concentric N-gons) — faint, purely decorative structure.
  let gridSvg = '';
  for (let ring = 1; ring <= rings; ring++) {
    const frac = ring / rings;
    const pts = axes.map((_, i) => { const p = pointFor(i, frac); return `${p.x},${p.y}`; }).join(' ');
    gridSvg += `<polygon points="${pts}" fill="none" stroke="var(--line)" stroke-width="1"/>`;
  }
  // Spokes
  axes.forEach((_, i) => {
    const p = pointFor(i, 1);
    gridSvg += `<line x1="${c}" y1="${c}" x2="${p.x}" y2="${p.y}" stroke="var(--line)" stroke-width="1"/>`;
  });

  // Data polygon
  const dataPts = axes.map((a, i) => { const p = pointFor(i, Math.max(0, Math.min(100, a.value)) / 100); return `${p.x},${p.y}`; }).join(' ');

  const wrap = fmt(`
    <div class="radar-chart-wrap" style="width:${size}px;height:${size}px;">
      <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" style="filter:drop-shadow(0 0 14px color-mix(in srgb, var(${colorVar}) 45%, transparent));">
        ${gridSvg}
        <polygon points="${dataPts}" fill="color-mix(in srgb, var(${colorVar}) 22%, transparent)" stroke="var(${colorVar})" stroke-width="2" stroke-linejoin="round"/>
      </svg>
    </div>
  `);

  axes.forEach((a, i) => {
    const p = pointFor(i, 1.18); // push labels just past the outer ring
    const label = fmt(`<div class="radar-axis-label" style="left:${p.x}px;top:${p.y}px;">${escapeHtml(a.label)}</div>`);
    wrap.appendChild(label);
  });

  return wrap;
}
