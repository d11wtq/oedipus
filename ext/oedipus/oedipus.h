/*-- encoding: utf-8 --*/

/*
 * Oedipus Sphinx 2 Search.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <ruby.h>
#include <mysql.h>

/*! Internal struct used to reference a mysql connection */
typedef struct {
  /*! Boolean representing the connected state */
  int   connected;
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
static VALUE odp_execute(VALUE self, VALUE sql);

/*! Execute several SQL read queries and return the result sets  */
static VALUE odp_query(VALUE self, VALUE sql);

/*! Cast the given field to a ruby data type */
static VALUE odp_cast_value(MYSQL_FIELD f, char * v, unsigned long len);

/* -- Internal methods -- */

/*! Generic method to raise a connection error */
static void odp_raise(VALUE self, const char *msg);

/*! Free memory allocated to mysql */
static void odp_free(OdpMysql *conn);
