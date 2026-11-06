import Lean

/-!
# The Infoview widget

A *User Widget* is a JavaScript module (ES module) that the Infoview loads and
executes; it receives as `props` the JSON passed to it by the command. There is
no compilation step here: we write plain JS using `React.createElement` (without
JSX), so the module fits in a Lean string.

Props: `{ svg?, error?, source, theme, showSource }`.
-/

open Lean Widget

@[widget_module]
def typstView : Widget.Module where
  javascript := r##"
import * as React from 'react';
const { useState, useEffect, createElement: h } = React;

// ---------- Detect the editor theme ----------
// The VS Code Infoview is a webview; VS Code marks <body> with
// `data-vscode-theme-kind` and the vscode-light / vscode-dark /
// vscode-high-contrast[-light] classes. If these are unavailable (in other
// editors), use the browser's prefers-color-scheme setting.
function editorIsDark() {
  const b = document.body;
  if (b) {
    const kind = b.getAttribute('data-vscode-theme-kind');
    if (kind) return kind === 'vscode-dark' || kind === 'vscode-high-contrast';
    const c = b.classList;
    if (c.contains('vscode-dark')) return true;
    if (c.contains('vscode-light')) return false;
    if (c.contains('vscode-high-contrast')) return !c.contains('vscode-high-contrast-light');
  }
  return !!(window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);
}

function useEditorIsDark() {
  const [dark, setDark] = useState(editorIsDark);
  useEffect(() => {
    const update = () => setDark(editorIsDark());
    const mo = new MutationObserver(update);
    mo.observe(document.body, { attributes: true, attributeFilter: ['class', 'data-vscode-theme-kind'] });
    const mq = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;
    if (mq && mq.addEventListener) mq.addEventListener('change', update);
    return () => {
      mo.disconnect();
      if (mq && mq.removeEventListener) mq.removeEventListener('change', update);
    };
  }, []);
  return dark;
}

// ---------- Minimal SVG sanitization before injection ----------
function sanitizeSvg(text) {
  try {
    const doc = new DOMParser().parseFromString(text, 'image/svg+xml');
    if (doc.querySelector('parsererror')) return null;
    doc.querySelectorAll('script, foreignObject').forEach(n => n.remove());
    doc.querySelectorAll('*').forEach(n => {
      for (const a of Array.from(n.attributes)) {
        if (/^on/i.test(a.name)) n.removeAttribute(a.name);
      }
    });
    return new XMLSerializer().serializeToString(doc.documentElement);
  } catch (e) {
    return null;
  }
}

// Typst renders in #000000 by default. We convert it to `currentColor` and
// control `color` from outside, so changing the theme requires no recompilation
// and the user's explicit colors (e.g. #text(fill: red)) are preserved.
const CSS = `
.typst-svg svg { max-width: 100%; height: auto; }
.typst-svg [fill="#000000"] { fill: currentColor; }
.typst-svg [stroke="#000000"] { stroke: currentColor; }
`;

const NEXT = { auto: 'light', light: 'dark', dark: 'auto' };

export default function TypstView(props) {
  const { svg, error, source, theme, showSource } = props;
  const editorDark = useEditorIsDark();
  // Manual button selection; if null, the `typst.theme` option takes precedence.
  const [override, setOverride] = useState(null);
  const requested = override ?? (theme || 'auto');
  const dark = requested === 'dark' || (requested !== 'light' && editorDark);
  const color = dark ? '#ffffff' : '#000000';

  const clean = svg ? sanitizeSvg(svg) : null;

  const toggle = h('button', {
    onClick: () => setOverride(NEXT[requested] || 'auto'),
    title: 'Alternar tema: auto → claro → oscuro',
    style: { float: 'right', cursor: 'pointer', fontSize: '0.8em', opacity: 0.7,
             background: 'transparent', color: 'inherit',
             border: '1px solid currentColor', borderRadius: '4px' }
  }, requested === 'auto' ? `auto (${dark ? 'oscuro' : 'claro'})` : (requested === 'dark' ? 'oscuro' : 'claro'));

  const body = error
    ? h('pre', { style: { whiteSpace: 'pre-wrap', color: 'var(--vscode-errorForeground, #f14c4c)' } }, error)
    : clean
      ? h('div', { className: 'typst-svg', style: { color, overflowX: 'auto' },
                   dangerouslySetInnerHTML: { __html: clean } })
      : h('pre', null, 'No se pudo interpretar el SVG generado por Typst.');

  const src = showSource && source
    ? h('details', { style: { marginTop: '0.5em', fontSize: '0.85em', opacity: 0.8 } },
        h('summary', null, 'Código Typst'),
        h('pre', { style: { whiteSpace: 'pre-wrap' } }, source))
    : null;

  return h('div', null, h('style', null, CSS), toggle, body, src);
}
"##
