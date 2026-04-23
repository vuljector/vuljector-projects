#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

/* Minimal stubs to satisfy linker for symbols referenced by http_server.c.o */
void evhttp_clear_headers(void *h) { (void)h; }
char *evhttp_decode_uri(const char *s) { (void)s; return NULL; }
const char *evhttp_find_header(void *h, const char *key) { (void)h; (void)key; return NULL; }
int evhttp_parse_query_str(const char *query, void *kv) { (void)query; (void)kv; return 0; }
void *evhttp_uri_parse(const char *request) { (void)request; return NULL; }
const char *evhttp_uri_get_query(void *u) { (void)u; return NULL; }
const char *evhttp_uri_get_path(void *u) { (void)u; return NULL; }
void evhttp_uri_free(void *u) { (void)u; }

int get_ioa_socket_app_type(void *s) { (void)s; return 0; }
int ioa_socket_tobeclosed(void *s) { (void)s; return 0; }
void *ioa_network_buffer_allocate(void *e) { (void)e; return malloc(1024); }
char *ioa_network_buffer_data(void *nbh) { return (char*)nbh; }
size_t ioa_network_buffer_get_capacity(void *nbh) { (void)nbh; return 1024; }
void ioa_network_buffer_set_size(void *nbh, size_t sz) { (void)nbh; (void)sz; }
void send_data_from_ioa_socket_nbh(void *s, void *a, void *nbh, int t1, int t2, void *cb) { (void)s; (void)a; (void)nbh; (void)t1; (void)t2; (void)cb; }

void turn_log_func_default(const char *fmt, ...) { (void)fmt; }

