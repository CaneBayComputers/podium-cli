# Docs

`guide/` holds the user guide as markdown. It is the source of truth for
<https://zeltro.build/guide/>.

## How it gets published

The guide is **not** a static site build. These files are rendered by the
zeltro.build web app at request time (`App\Support\Guide`), inside the same
layout as the rest of the site. Publishing is a file copy:

    docs/guide/*.md  ->  <site>/resources/guide/  ->  rendered per request

`deploy.sh guide` in the site project does the copy. There is no toolchain to
install and no build step to run.

## Editing

Write plain GitHub-flavoured markdown. Two conventions carry over from the
guide's Jekyll days and are still honoured:

- **Front matter** sets the page title and its position in the sidebar:

      ---
      title: Installation
      nav_order: 2
      ---

- **Callouts** are a kramdown attribute line placed directly *before* the
  paragraph or blockquote it applies to:

      {: .warning }
      Zeltro starts your agent in a high-trust mode.

  `note`, `warning`, `important` and `highlight` are styled. The marker must
  come before the block, not after it.

Link between pages with a sibling-relative path and a trailing slash --
`[Cheap models](../cheap-models/)` -- so the link works both in the rendered
site and when reading the markdown on GitHub.

Adding a `.md` file here is all that is needed to add a page: the sidebar and
`sitemap.xml` are both generated from this directory.

## What used to be here

Until August 2026 this directory was a Jekyll site (just-the-docs) published by
GitHub Pages at podiumcli.com, and it also held the marketing pages. The site
now lives on its own server and podiumcli.com redirects to zeltro.build, so the
Jekyll config, Gemfile, theme CSS and the old `index.html` / `donate.html` were
removed. Only the guide markdown survives, because only it is still used.
