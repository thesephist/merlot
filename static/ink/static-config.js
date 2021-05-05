Authed__ink_qm__ = false;
__ink_match(bind(localStorage, __Ink_String(`getItem`))(__Ink_String(`files`)), [[() => (null), () => ((() => { bind(localStorage, __Ink_String(`setItem`))(__Ink_String(`files`), __Ink_String(`Welcome to Merlot!`)); return bind(localStorage, __Ink_String(`setItem`))(__Ink_String(`/doc/Welcome to Merlot!`), __Ink_String(`# Welcome to Merlot 🍷

!html <img src="https://travis-ci.com/thesephist/ink.svg?branch=master&status=passed">

**Merlot** is a web-based writing app that supports Markdown. It replaces iA Writer for me as my primary blog-writing app, while filling in some other use cases I had in mind like sharing drafts.

Merlot is written in pure [Ink](https://dotink.co/) and depends on [Torus](https://github.com/thesephist/torus) for rendering. The [September compiler](https://github.com/thesephist/september) is used to compile UI code written in Ink to a JavaScript bundle for the browser. It uses a Markdown library for Ink that I wrote specifically for this app, which you can find in \`lib/\` in the [GitHub repository](https://github.com/thesephist/merlot).

Some inspirations for Merlot are:

- **Notea**: Notea is a self-hosted notes app that saves to Amazon S3. I took much design inspiration from Notea for Merlot, because I thought it looked clean and modern without seeming barren. Notea however has an extremely rich text editing feature set that I left in favor of simple Markdown.
- **Notion**: I borrowed some UI design ideas from Notion, because it looks and feels great. One thing I made sure not to borrow was _performance_. Merlot works pretty well on slow and spotty connections, and loads instantly in decent network conditions.
- **iA Writer**: My previous Markdown writing app, primarily for the Mac and iOS platforms.

I always try to build a personal workflow first, before building a tool for myself around it. That means I can [design a tool around my workflows](https://thesephist.com/posts/tools/) rather than the other way around, making sure that the tool works with the grain of my mental models. Before I wrote Merlot, I was a heavy user of iA Writer, a Mac app for writing in Markdown. It was clean and fast and did what it did very well, but missing some features -- the features that Merlot adds.

Features like:

- Extensive keyboard shortcuts
- Sharing drafts right from the editor
- Quality user experience on non-Apple platforms
- More flexible embedding of images and HTML snippets from the web
- Syncing to my own data storage system for secure backups

I'm hoping to use Merlot as my main, full-time writing app for the thousands of words I write each week, and continue improving the app as I put it through its paces!

\\- Linus`)) })())]])

