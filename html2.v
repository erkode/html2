module html2

pub struct Document {
mut:
	doc       &C.lxb_html_document_t = unsafe { nil }
	selectors &C.lxb_selectors_t     = unsafe { nil }
}

pub struct Selector {
mut:
	list   &C.lxb_css_selector_list_t = unsafe { nil }
	parser &C.lxb_css_parser_t        = unsafe { nil }
}

pub struct Element {
	node &C.lxb_dom_node_t
}

struct QueryContext {
mut:
	elements []Element
}

struct MatchContext {
mut:
	matched bool
}

struct SerializeContext {
mut:
	data []u8
}

fn clone_c_bytes(data voidptr, len usize) string {
	if data == unsafe { nil } || len == 0 {
		return ''
	}

	return unsafe { tos(&u8(data), int(len)).clone() }
}

fn node_as_element(node &C.lxb_dom_node_t) &C.lxb_dom_element_t {
	return unsafe { &C.lxb_dom_element_t(node) }
}

fn wrap_element(node &C.lxb_dom_node_t) ?Element {
	if isnil(node) || C.lxb_dom_node_type_noi(node) != dom_node_type_element {
		return none
	}

	return unsafe {
		Element{
			node: node
		}
	}
}

@[callconv: cdecl]
fn selector_collect_cb(node &C.lxb_dom_node_t, _spec int, ctx voidptr) int {
	mut query_ctx := unsafe { &QueryContext(ctx) }
	if C.lxb_dom_node_type_noi(node) == dom_node_type_element {
		query_ctx.elements << unsafe {
			Element{
				node: node
			}
		}
	}
	return lxb_status_ok
}

@[callconv: cdecl]
fn selector_match_cb(_node &C.lxb_dom_node_t, _spec int, ctx voidptr) int {
	mut match_ctx := unsafe { &MatchContext(ctx) }
	match_ctx.matched = true
	return lxb_status_ok
}

@[callconv: cdecl]
fn serialize_collect_cb(data &u8, len usize, ctx voidptr) int {
	mut serialize_ctx := unsafe { &SerializeContext(ctx) }
	if isnil(data) || len == 0 {
		return lxb_status_ok
	}

	chunk := clone_c_bytes(data, len)
	serialize_ctx.data << chunk.bytes()
	return lxb_status_ok
}

fn serialize_node(node &C.lxb_dom_node_t, include_self bool) !string {
	mut ctx := SerializeContext{}
	status := if include_self {
		C.lxb_html_serialize_tree_cb(node, voidptr(serialize_collect_cb), &ctx)
	} else {
		C.lxb_html_serialize_deep_cb(node, voidptr(serialize_collect_cb), &ctx)
	}

	if status != lxb_status_ok {
		return error('serialize error')
	}

	return ctx.data.bytestr()
}

// parse parses an HTML document and initializes selector search state.
pub fn Document.parse(input string) !Document {
	doc := C.lxb_html_document_create()
	if isnil(doc) {
		return error('document error')
	}

	status := C.lxb_html_document_parse(doc, input.str, usize(input.len))
	if status != lxb_status_ok {
		C.lxb_html_document_destroy(doc)
		return error('parser error')
	}

	selectors := C.lxb_selectors_create()
	if isnil(selectors) {
		C.lxb_html_document_destroy(doc)
		return error('selector error')
	}

	if C.lxb_selectors_init(selectors) != lxb_status_ok {
		C.lxb_selectors_destroy(selectors, true)
		C.lxb_html_document_destroy(doc)
		return error('selector error')
	}

	return Document{
		doc:       doc
		selectors: selectors
	}
}

// select returns all elements in the document that match a compiled selector.
pub fn (doc &Document) select(sel Selector) []Element {
	if isnil(doc.doc) || isnil(doc.selectors) || isnil(sel.list) {
		return []Element{}
	}

	root := unsafe { &C.lxb_dom_node_t(doc.doc) }
	if isnil(root) {
		return []Element{}
	}

	mut query_ctx := QueryContext{}
	status := C.lxb_selectors_find(doc.selectors, root, sel.list, voidptr(selector_collect_cb),
		&query_ctx)
	if status != lxb_status_ok {
		return []Element{}
	}

	return query_ctx.elements
}

// matches reports whether an element matches a compiled CSS selector.
pub fn (doc &Document) matches(el Element, sel Selector) bool {
	if isnil(doc.selectors) || isnil(el.node) || isnil(sel.list)
		|| C.lxb_dom_node_type_noi(el.node) != dom_node_type_element {
		return false
	}

	mut match_ctx := MatchContext{}
	status := C.lxb_selectors_match_node(doc.selectors, el.node, sel.list, voidptr(selector_match_cb),
		&match_ctx)
	if status != lxb_status_ok {
		return false
	}

	return match_ctx.matched
}

// free releases native resources owned by the document.
pub fn (mut doc Document) free() {
	if !isnil(doc.selectors) {
		C.lxb_selectors_destroy(doc.selectors, true)
		doc.selectors = unsafe { nil }
	}

	if !isnil(doc.doc) {
		C.lxb_html_document_destroy(doc.doc)
		doc.doc = unsafe { nil }
	}
}

// parse compiles a CSS selector and returns a selector handle.
pub fn Selector.parse(selector string) !Selector {
	parser := C.lxb_css_parser_create()
	if isnil(parser) {
		return error('css parser error')
	}

	if C.lxb_css_parser_init(parser, unsafe { nil }) != lxb_status_ok {
		C.lxb_css_parser_destroy(parser, true)
		return error('css parser init error')
	}

	if C.lxb_css_parser_selectors_init(parser) != lxb_status_ok {
		C.lxb_css_parser_destroy(parser, true)
		return error('css selectors init error')
	}

	list := C.lxb_css_selectors_parse(parser, selector.str, usize(selector.len))
	if isnil(list) {
		C.lxb_css_parser_selectors_destroy(parser)
		C.lxb_css_parser_destroy(parser, true)
		return error('selector parse error')
	}

	return Selector{
		list:   list
		parser: parser
	}
}

// free releases native resources owned by the selector.
pub fn (mut selector Selector) free() {
	if !isnil(selector.list) {
		C.lxb_css_selector_list_destroy_memory(selector.list)
		selector.list = unsafe { nil }
	}

	if !isnil(selector.parser) {
		C.lxb_css_parser_selectors_destroy(selector.parser)
		C.lxb_css_parser_destroy(selector.parser, true)
		selector.parser = unsafe { nil }
	}
}

// outer_html serializes the element including its own tag.
pub fn (el Element) outer_html() !string {
	if isnil(el.node) {
		return error('nil element')
	}

	return serialize_node(el.node, true)
}

// inner_html serializes only the element children.
pub fn (el Element) inner_html() !string {
	if isnil(el.node) {
		return error('nil element')
	}

	return serialize_node(el.node, false)
}

// get_attributes returns all element attributes as a name-value map.
pub fn (el Element) get_attributes() map[string]string {
	if isnil(el.node) || C.lxb_dom_node_type_noi(el.node) != dom_node_type_element {
		return map[string]string{}
	}

	mut attrs := map[string]string{}
	mut attr := C.lxb_dom_element_first_attribute_noi(node_as_element(el.node))
	for !isnil(attr) {
		mut name_len := usize(0)
		name_ptr := C.lxb_dom_attr_local_name_noi(attr, &name_len)
		name := clone_c_bytes(name_ptr, name_len)
		if name.len > 0 {
			mut value_len := usize(0)
			value_ptr := C.lxb_dom_attr_value_noi(attr, &value_len)
			attrs[name] = clone_c_bytes(value_ptr, value_len)
		}

		attr = C.lxb_dom_element_next_attribute_noi(attr)
	}

	return attrs
}

// has_attribute reports whether the element has an attribute with the given name.
pub fn (el Element) has_attribute(name string) bool {
	if name.len == 0 || isnil(el.node) || C.lxb_dom_node_type_noi(el.node) != dom_node_type_element {
		return false
	}

	return C.lxb_dom_element_has_attribute(node_as_element(el.node), name.str, usize(name.len))
}

// has_attribute_value reports whether an attribute exists with exactly the given value.
pub fn (el Element) has_attribute_value(name string, value string) bool {
	if name.len == 0 || isnil(el.node) || C.lxb_dom_node_type_noi(el.node) != dom_node_type_element {
		return false
	}

	mut value_len := usize(0)
	value_ptr := C.lxb_dom_element_get_attribute(node_as_element(el.node), name.str, usize(name.len),
		&value_len)
	if isnil(value_ptr) {
		return false
	}

	return clone_c_bytes(value_ptr, value_len) == value
}

// parent returns the nearest parent element when present.
pub fn (el Element) parent() ?Element {
	return wrap_element(C.lxb_dom_node_parent_noi(el.node))
}

// first_child returns the first child element when present.
pub fn (el Element) first_child() ?Element {
	mut node := C.lxb_dom_node_first_child_noi(el.node)
	for !isnil(node) {
		if C.lxb_dom_node_type_noi(node) == dom_node_type_element {
			return wrap_element(node)
		}
		node = C.lxb_dom_node_next_noi(node)
	}

	return none
}

// last_child returns the last child element when present.
pub fn (el Element) last_child() ?Element {
	mut node := C.lxb_dom_node_last_child_noi(el.node)
	for !isnil(node) {
		if C.lxb_dom_node_type_noi(node) == dom_node_type_element {
			return wrap_element(node)
		}
		node = C.lxb_dom_node_prev_noi(node)
	}

	return none
}

// next_sibling returns the next sibling element when present.
pub fn (el Element) next_sibling() ?Element {
	mut node := C.lxb_dom_node_next_noi(el.node)
	for !isnil(node) {
		if C.lxb_dom_node_type_noi(node) == dom_node_type_element {
			return wrap_element(node)
		}
		node = C.lxb_dom_node_next_noi(node)
	}

	return none
}

// previous_sibling returns the previous sibling element when present.
pub fn (el Element) previous_sibling() ?Element {
	mut node := C.lxb_dom_node_prev_noi(el.node)
	for !isnil(node) {
		if C.lxb_dom_node_type_noi(node) == dom_node_type_element {
			return wrap_element(node)
		}
		node = C.lxb_dom_node_prev_noi(node)
	}

	return none
}
