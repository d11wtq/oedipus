/*-- encoding: utf-8 --*/

/*
 * Oedipus Sphinx 2 Search.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <ruby.h>
#include <mysql.h>

// Macros for lazy fingers
#define ODP_TO_S(v)                  rb_funcall(v, rb_intern("to_s"), 0)
#define ODP_TO_F(n)                  rb_funcall(n, rb_intern("to_f"), 0)
#define ODP_KIND_OF_P(v, type)       (rb_funcall(v, rb_intern("kind_of?"), 1, type) == Qtrue)

/*! Internal struct used to reference a mysql connection */
typedef struct {
  /*! Boolean representing the connected state */
  int     connected;
  /*! The actual pointer allocated by mysql_init() */
  MYSQL * ptr;
} OdpMysql;

/* -- Public methods -- */

/*! Allocate and initialize a new mysql client */
static VALUE odp_new(VALUE klass, VALUE host, VALUE port);

/*! Initialize a new mysql client */
static VALUE odp_initialize(VALUE self, VALUE host, VALUE port);

/*! Connect, or reconnect to mysql */
static VALUE odp_open(VALUE self);

/*! Disconnect from mysql */
static VALUE odp_close(VALUE self);

/*! Execute an SQL non-read query and return the number of rows affected */
static VALUE odp_execute(int argc, VALUE * args, VALUE self);

/*! Execute several SQL read queries and return the result sets  */
static VALUE odp_query(int argc, VALUE * args, VALUE self);

/* -- Internal methods -- */

/*! Generic method to raise a connection error */
static void odp_raise(VALUE self, const char *msg);

/*! Free memory allocated to mysql */
static void odp_free(OdpMysql * conn);

/*! Substitute all ? markers with the values in bind_values */
static VALUE odp_replace_bind_values(OdpMysql * conn, VALUE sql, VALUE * bind_values, int num_values);

/*! Cast the given field to a ruby data type */
static VALUE odp_cast_value(MYSQL_FIELD f, char * v, unsigned long len);
