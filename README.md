# html2

A simple wrapper around Lexbor for HTML parsing and CSS selector queries.

## Quick Example

```v
import html

fn main() {
	source := '<html><head><meta property="og:title" content="x"></head><body><div id="a"><span class="x">ok</span></div></body></html>'
	mut doc := html.Document.parse(source) or {
		eprintln('parse error: ${err.msg()}')
		return
	}
	defer {
		doc.free()
	}
	mut sel := html.Selector.parse('span.x') or {
		eprintln('selector error: ${err.msg()}')
		return
	}
	defer {
		sel.free()
	}
	elements := doc.select(sel)
	for el in elements {
		println(el.outer_html() or { '' })
	}
}
```

## Matches Example

```v
import html

fn main() {
	source := '<div id="a" class="item"></div><div id="b"></div>'

	mut doc := html.Document.parse(source) or { return }
	defer { doc.free() }

	// Selector used to query all divs.
	mut all_divs := html.Selector.parse('div') or { return }
	defer { all_divs.free() }

	// Selector used for matching.
	mut item_sel := html.Selector.parse('.item') or { return }
	defer { item_sel.free() }

	// Iterate through divs and test each one with matches.
	for el in doc.select(all_divs) {
		if doc.matches(el, item_sel) {
			println('matched .item')
		}
	}
}
```

## API

### `Document`
- `Document.parse(input string) !Document`
- `Document.select(sel Selector) []Element`
- `Document.matches(el Element, sel Selector) bool`
- `(mut doc Document).free()`

### `Selector`
- `Selector.parse(selector string) !Selector`
- `(mut selector Selector).free()`

### `Element`
- `(el Element).outer_html() !string`
- `(el Element).inner_html() !string`
- `(el Element).get_attributes() map[string]string`
- `(el Element).has_attribute(name string) bool`
- `(el Element).has_attribute_value(name string, value string) bool`
- `(el Element).parent() ?Element`
- `(el Element).first_child() ?Element`
- `(el Element).last_child() ?Element`
- `(el Element).next_sibling() ?Element`
- `(el Element).previous_sibling() ?Element`
