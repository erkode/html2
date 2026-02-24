module html2

const fixture_html = '<!doctype html><html><head><meta property="og:title" content="Wrapper"></head><body><section id="root" data-state="ready">text<h1 id="title">Title</h1><p id="first" class="item" data-kind="alpha"><span id="inner">A</span></p><p id="second" class="item" data-kind="beta">B</p></section></body></html>'

fn must_select_one(doc &Document, selector string) !Element {
	mut sel := Selector.parse(selector)!
	defer {
		sel.free()
	}

	elements := doc.select(sel)
	if elements.len != 1 {
		return error('expected a single element, got ${elements.len}')
	}
	return elements[0]
}

fn test_document_parse_and_select() {
	mut doc := Document.parse(fixture_html) or {
		assert false
		return
	}
	defer {
		doc.free()
	}

	mut sel := Selector.parse('.item') or {
		assert false
		return
	}
	defer {
		sel.free()
	}

	elements := doc.select(sel)
	assert elements.len == 2
}

fn test_document_matches_with_compiled_selector() {
	mut doc := Document.parse(fixture_html) or {
		assert false
		return
	}
	defer {
		doc.free()
	}

	mut item_sel := Selector.parse('.item') or {
		assert false
		return
	}
	defer {
		item_sel.free()
	}

	items := doc.select(item_sel)
	assert items.len == 2
	for el in items {
		assert doc.matches(el, item_sel)
	}

	root := must_select_one(&doc, '#root') or {
		assert false
		return
	}
	assert !doc.matches(root, item_sel)

	mut ready_sel := Selector.parse('[data-state="ready"]') or {
		assert false
		return
	}
	defer {
		ready_sel.free()
	}
	assert doc.matches(root, ready_sel)
}

fn test_element_attribute_helpers() {
	mut doc := Document.parse(fixture_html) or {
		assert false
		return
	}
	defer {
		doc.free()
	}

	root := must_select_one(&doc, '#root') or {
		assert false
		return
	}
	attrs := root.get_attributes()
	assert attrs['id'] == 'root'
	assert attrs['data-state'] == 'ready'

	assert root.has_attribute('id')
	assert root.has_attribute('data-state')
	assert !root.has_attribute('missing')

	assert root.has_attribute_value('data-state', 'ready')
	assert !root.has_attribute_value('data-state', 'READY')
	assert !root.has_attribute_value('missing', 'x')
}

fn test_element_navigation_helpers() {
	mut doc := Document.parse(fixture_html) or {
		assert false
		return
	}
	defer {
		doc.free()
	}

	root := must_select_one(&doc, '#root') or {
		assert false
		return
	}

	first := root.first_child() or {
		assert false
		return
	}
	assert first.has_attribute_value('id', 'title')

	last := root.last_child() or {
		assert false
		return
	}
	assert last.has_attribute_value('id', 'second')

	next := first.next_sibling() or {
		assert false
		return
	}
	assert next.has_attribute_value('id', 'first')

	prev := last.previous_sibling() or {
		assert false
		return
	}
	assert prev.has_attribute_value('id', 'first')

	parent := next.parent() or {
		assert false
		return
	}
	assert parent.has_attribute_value('id', 'root')
}

fn test_element_html_getters() {
	mut doc := Document.parse(fixture_html) or {
		assert false
		return
	}
	defer {
		doc.free()
	}

	first := must_select_one(&doc, '#first') or {
		assert false
		return
	}
	inner := first.inner_html() or {
		assert false
		return
	}
	outer := first.outer_html() or {
		assert false
		return
	}

	assert inner.contains('<span id="inner">A</span>')
	assert outer.starts_with('<p')
	assert outer.contains(inner)
	assert outer.contains('data-kind="alpha"')
}
