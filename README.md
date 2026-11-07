# Typst Infoview

This project lets you display Typst code directly in the Lean Infoview.

It integrates Typst rendering into Lean's interactive environment so that expressions can be visualized as generated Typst output while working in the editor. The project also adds a `#typst` command that renders the Typst representation of an instance of the `ToTypst` class.

## Features

- Show generated Typst output in the Infoview.
- Display Typst source alongside the rendered result when enabled.
- Add a `#typst` command for printing the Typst representation of a `ToTypst` value.

## Requirements

This project requires a local Typst installation on the machine running Lean.

[Install Typst from the official project](https://github.com/typst/typst)

Make sure the `typst` executable is available in your PATH, or configure the project to point to the local installation using the configured `typst.bin` option.

## Installation with Lake

Add the dependency to your `lakefile.toml`:

```toml
[[require]]
name = "TypstInfoview"
git = "https://github.com/Danelnov/typst-lean"
rev = "master"
```

Then update your project dependencies:

```bash
lake update
```

Finally, import the package in your Lean files:

```lean
import TypstInfoview
```

## Usage

After installing Typst locally, you can use the Lean integration to render Typst output in the Infoview and invoke the `#typst` command to inspect the Typst representation produced by `ToTypst` instances.
