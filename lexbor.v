module html2

$if !msvc {
	#flag -lm
}

#include "@VMODROOT/lexbor.h"

@[typedef]
struct C.lxb_dom_node_t {}

@[typedef]
struct C.lxb_dom_element_t {}

@[typedef]
struct C.lxb_dom_attr_t {}

@[typedef]
struct C.lxb_html_document_t {}

@[typedef]
struct C.lxb_css_syntax_tokenizer_t {}

@[typedef]
struct C.lxb_css_selector_list_t {}

@[typedef]
struct C.lxb_selectors_t {}

@[typedef]
struct C.lxb_css_parser_t {}

const lxb_status_ok = 0
const dom_node_type_element = C.LXB_DOM_NODE_TYPE_ELEMENT

fn C.lxb_html_document_create() &C.lxb_html_document_t
fn C.lxb_html_document_destroy(document &C.lxb_html_document_t) &C.lxb_html_document_t
fn C.lxb_html_document_parse(document &C.lxb_html_document_t, html &u8, size usize) int
fn C.lxb_dom_node_type_noi(node &C.lxb_dom_node_t) int
fn C.lxb_dom_node_parent_noi(node &C.lxb_dom_node_t) &C.lxb_dom_node_t
fn C.lxb_dom_node_first_child_noi(node &C.lxb_dom_node_t) &C.lxb_dom_node_t
fn C.lxb_dom_node_last_child_noi(node &C.lxb_dom_node_t) &C.lxb_dom_node_t
fn C.lxb_dom_node_next_noi(node &C.lxb_dom_node_t) &C.lxb_dom_node_t
fn C.lxb_dom_node_prev_noi(node &C.lxb_dom_node_t) &C.lxb_dom_node_t
fn C.lxb_dom_element_get_attribute(element &C.lxb_dom_element_t, qualified_name &u8, qn_len usize, value_len &usize) &u8
fn C.lxb_dom_element_has_attribute(element &C.lxb_dom_element_t, qualified_name &u8, qn_len usize) bool
fn C.lxb_dom_element_first_attribute_noi(element &C.lxb_dom_element_t) &C.lxb_dom_attr_t
fn C.lxb_dom_element_next_attribute_noi(attr &C.lxb_dom_attr_t) &C.lxb_dom_attr_t
fn C.lxb_dom_attr_local_name_noi(attr &C.lxb_dom_attr_t, len &usize) &u8
fn C.lxb_dom_attr_value_noi(attr &C.lxb_dom_attr_t, len &usize) &u8
fn C.lxb_css_parser_create() &C.lxb_css_parser_t
fn C.lxb_css_parser_init(parser &C.lxb_css_parser_t, tkz &C.lxb_css_syntax_tokenizer_t) int
fn C.lxb_css_parser_selectors_init(parser &C.lxb_css_parser_t) int
fn C.lxb_css_parser_selectors_destroy(parser &C.lxb_css_parser_t)
fn C.lxb_css_parser_destroy(parser &C.lxb_css_parser_t, self_destroy bool) &C.lxb_css_parser_t
fn C.lxb_css_selectors_parse(parser &C.lxb_css_parser_t, data &u8, length usize) &C.lxb_css_selector_list_t
fn C.lxb_css_selector_list_destroy_memory(list &C.lxb_css_selector_list_t)
fn C.lxb_selectors_create() &C.lxb_selectors_t
fn C.lxb_selectors_init(selectors &C.lxb_selectors_t) int
fn C.lxb_selectors_destroy(selectors &C.lxb_selectors_t, self_destroy bool) &C.lxb_selectors_t
fn C.lxb_selectors_find(selectors &C.lxb_selectors_t, root &C.lxb_dom_node_t, list &C.lxb_css_selector_list_t, cb voidptr, ctx voidptr) int
fn C.lxb_selectors_match_node(selectors &C.lxb_selectors_t, node &C.lxb_dom_node_t, list &C.lxb_css_selector_list_t, cb voidptr, ctx voidptr) int
fn C.lxb_html_serialize_tree_cb(node &C.lxb_dom_node_t, cb voidptr, ctx voidptr) int
fn C.lxb_html_serialize_deep_cb(node &C.lxb_dom_node_t, cb voidptr, ctx voidptr) int
