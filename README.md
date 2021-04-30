# Merlot

**Merlot** is a Markdown engine and writer app written in pure [Ink](https://dotink.co).

# Syntax

Merlot's Markdown implementation attempts to be broadly compatible with GitHub and CommonMark specifications, and is designed for longform writing use cases, because that's what I needed it for (a blogging engine).

The Markdown parser and compiler interoperate, but are modular against a well-tested specification for a Markdown AST representation based on HTML. The parser can be used independently of the compiler to render HTML through another renderer (for example, a reactive virtual DOM implementation like [Torus](https://github.com/thesephist/torus)), as well as fed into the compiler to generate HTML text.

Merlot's Markdown parser adds a few exceptions to the common Markdown syntax that adds features I personally find useful:

1. Explicit inline HTML declaration with `!html` — every line following and including the `!html` line is parsed as inline HTML, until an empty line.
2. Class syntax for inline images — this is a **TODO**.

