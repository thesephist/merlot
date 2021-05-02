# Merlot 🍷

[![Build Status](https://travis-ci.com/thesephist/merlot.svg?branch=main)](https://travis-ci.com/thesephist/merlot)

**Merlot** is a web-based writing app that supports Markdown. It replaces iA Writer for me as my primary blogging and writing app, while filling in some other use cases I had in mind like sharing drafts. In fact, this very README was written in Merlot!

![Screenshot of Merlot on desktop and mobile](static/img/merlot-devices.png)

Merlot is written in pure [Ink](https://dotink.co/) and depends on [Torus](https://github.com/thesephist/torus) for rendering. The [September compiler](https://github.com/thesephist/september) is used to compile UI code written in Ink to a JavaScript bundle for the browser. It uses a Markdown library for Ink that I wrote specifically for this app, which you can find in `lib/`. I also [shared my process of building Merlot](https://twitter.com/thesephist/status/1387936119300530183) on Twitter.

Some design and workflow inspirations for Merlot include [Notea](https://github.com/QingWei-Li/notea), Notion, and iA Writer.

## Features

I always try to discover a personal workflow first, before building a tool for myself around it. That means I can [design a tool around my workflows](https://thesephist.com/posts/tools/) rather than the other way around, making sure that the tool works with the grain of my mental models. Before I wrote Merlot, I was a heavy user of iA Writer, a Mac app for writing in Markdown. It was clean and fast and did what it did very well, but missing some features -- the features that Merlot adds.

Features like:

- **Extensive keyboard shortcuts.** I designed Merlot so I could perform 99% of day-to-day operations in the editor without my hands leaving the keyboard.
- **Sharing drafts right from the editor.** I often want to write short documents or notes to share with a few people quickly, and Google Docs and Notion feel too heavy. iA Writer itself has no sharing functionality, so I integrated the ability to share a preview of a file right into Merlot through the "Share" button, which opens a public preview.
- **UX on non-Apple platforms.** iA Writer has apps available on Android and Windows, but the experiences there are subpar. I wanted a good quality writing experience everywhere, which meant building for the web.
- **Explicit HTML syntax.** One of my main qualms with writing Markdown content for my blogs is that my current engine (Hugo) doesn't give me a way to explicitly designate certain sections as safe HTML content -- the engine tries to infer this, which is often unsafe. Merlot's flavor of Markdown provides a `!html` syntax to explicitly denote HTML snippets to embed into my Markdown files.
- **Storage that I can own.** As with all of my other tools, Merlot saves its data in an open, compatible format (simple Markdown files) in a storage location I control on my own servers.

Beyond these key features, Merlot also supports live preview as you're writing, as well as a nice dark mode.

## Markdown syntax

Merlot's Markdown implementation attempts to be broadly compatible with GitHub and CommonMark specifications, and is designed for longform writing use cases, because that's what I needed it for (a writing app and a blogging engine).

The Markdown parser and compiler interoperate, but are modular against a well-tested specification for a Markdown AST representation based on HTML. The parser can be used independently of the compiler to render HTML through another renderer (for example, a reactive virtual DOM implementation like [Torus](https://github.com/thesephist/torus)), as well as fed into the compiler to generate HTML text.

Merlot's Markdown parser adds a few exceptions to the common Markdown syntax that adds features I personally find useful:

- Explicit inline HTML declaration with `!html`. Every line following and including the `!html` line is parsed as inline HTML, until an empty line.
- Class syntax for inline images. This is an upcoming feature.

## Architecture

The Merlot project has three components: the Markdown engine, the editor, and the server.

Merlot's Markdown engine is custom to this project. It tries to be reasonably compatible with GitHub flavored Markdown and CommonMark, but takes liberties where I thought I preferred a deviation from the norm (like inline HTML).

The Markdown engine is written in pure Ink, and reused across both the native backend and the web editor. In the server, it's used to render a public preview (the "Share" link) on the server side. In the client, it's used to generate previews for the document being edited without a round-trip to the server.

The editor is built on top of a simple text area, and the rest of the app is written in Ink on top of the Torus UI library. The server is kept simple, with a minimal REST API to save and retrieve documents as well as generate public previews.

### Deployment modes

Merlot can be built in two different modes: a "dynamic" mode, where data is saved to a database on the server, and a "static" mode, where the app becomes a static site and saves everything to the browser's local storage. Both share much of the codebase, and which one is built depends on build-time imported configuration variables.

I personally use the dynamically deployed version for personal use, which also gives me the "Share" preview feature that isn't available on the static builds, and lets me carry data across devices. There is also a public static version deployed on Vercel.

## Development

Merlot uses a Makefile for development tasks. To develop Merlot, you'll need to install [Ink](https://dotink.co/) and the [September](https://github.com/thesephist/september) compiler. [inkfmt](https://github.com/thesephist/inkfmt) is optional, and used for code formatting.

- `make run` starts the web server in the same way as the production environment. This is not necessary for the static deployment mode.
- `make build` builds the frontend JavaScript bundles for all modes.
- `make watch` runs `make build` every time a relevant Ink source file changes.
- `make check` or `make t` runs Merlot's Markdown library test suite, which lives in `test/`.
- `make fmt` runs the [inkfmt](https://github.com/thesephist/inkfmt) code formatter over all Ink source code in the project.

### Deploy Merlot

To deploy Merlot, the steps required depend on the kind of build you want to use (see "Deployment modes" above).

You can find the **static build** of Merlot available at [merlot.vercel.app](https://merlot.vercel.app). To deploy this version, simply deploy the `static/` directory as a static site.

There is not a public deployment of the **dynamic build**. To deploy this version, you'll need [Ink](https://github.com/thesephist/ink/releases) installed. After that, run `ink src/main.ink` from the root directory of the project to run the dynamic deployment. The app will be available on port 7650 by default.

## Roadmap

There are a few features that I'd like to include in Merlot and the Markdown library that aren't there yet.

- Support for bulleted lists starting with `*` instead of `-`
- Support for numbered lists
- Support for multiple paragraphs and rich blocks inside list items
- Syntax highlighting on code blocks with language tags
- Class syntax for inline images
