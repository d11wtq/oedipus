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
  int   connected;
  MYSQL * ptr;
} OdpMysql;

/*! Generic method to raise a connection error */
static void odp_raise(VALUE self, const char *msg);

/*! Free memory allocated to mysql */
static void odp_free(OdpMysql *conn);

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

static VALUE odp_new(VALUE klass, VALUE host, VALUE port) {
  OdpMysql * conn;
  VALUE      self;
  VALUE      args[2];

  conn = malloc(sizeof(OdpMysql));
  conn->connected = 0;

  self = Data_Wrap_Struct(klass, 0, odp_free, conn);

  args[0] = host;
  args[1] = port;

  rb_obj_call_init(self, 2, args);

  return self;
}

static VALUE odp_initialize(VALUE self, VALUE host, VALUE port) {
  Check_Type(host, T_STRING);
  Check_Type(port, T_FIXNUM);

  rb_iv_set(self, "@host", host);
  rb_iv_set(self, "@port", port);

  odp_open(self);

  return self;
}

static VALUE odp_open(VALUE self) {
  OdpMysql * conn;

  Data_Get_Struct(self, OdpMysql, conn);

  if (conn->connected) {
    return Qfalse;
  }

  if ((conn->ptr = mysql_init(NULL)) == NULL) {
    odp_raise(self, "Unable to initialize mysql");
  }

  if (mysql_real_connect(conn->ptr,
                         RSTRING_PTR(rb_iv_get(self, "@host")),
                         "",
                         "",
                         NULL,
                         NUM2UINT(rb_iv_get(self, "@port")),
                         NULL,
                         CLIENT_MULTI_STATEMENTS) == NULL) {
    odp_raise(self, "Unable to connect to mysql");
  }

  conn->connected = 1;

  return Qtrue;
}

static VALUE odp_close(VALUE self) {
  OdpMysql * conn;

  Data_Get_Struct(self, OdpMysql, conn);

  if (!(conn->connected)) {
    return Qfalse;
  }

  mysql_close(conn->ptr);
  conn->connected = 0;

  return Qtrue;
}

static VALUE odp_execute(VALUE self, VALUE sql) {
  OdpMysql  * conn;

  Check_Type(sql, T_STRING);

  Data_Get_Struct(self, OdpMysql, conn);

  if (mysql_query(conn->ptr, RSTRING_PTR(sql))) {
    odp_raise(self, "Failed to execute statement(s)");
  }

  return INT2NUM(mysql_affected_rows(conn->ptr));
}

static VALUE odp_query(VALUE self, VALUE sql) {
  OdpMysql    * conn;
  MYSQL_RES   * rs;
  int           status;
  int           num_fields;
  MYSQL_ROW     row;
  MYSQL_FIELD * fields;
  int           i;
  VALUE         rows;
  VALUE         hash;
  VALUE         results;

  Check_Type(sql, T_STRING);

  Data_Get_Struct(self, OdpMysql, conn);

  if (mysql_query(conn->ptr, RSTRING_PTR(sql))) {
    odp_raise(self, "Failed to execute statement(s)");
  }

  results = rb_ary_new();

  do {
    if ((rs = mysql_store_result(conn->ptr)) != NULL) {
      rb_ary_push(results, (rows = rb_ary_new()));

      num_fields = mysql_num_fields(rs);

      fields = mysql_fetch_fields(rs);

      while ((row = mysql_fetch_row(rs))) {
        rb_ary_push(rows, (hash = rb_hash_new()));
        for (i = 0; i < num_fields; ++i) {
          rb_hash_aset(hash, rb_str_new2(fields[i].name), rb_str_new2(row[i]));
        }
      }

      mysql_free_result(rs);
    }

    if ((status = mysql_next_result(conn->ptr)) > 0) {
      odp_raise(self, "Query execution failed");
    }
  } while (status == 0);

  return results;
}

/* -- Internal functions -- */

static void odp_raise(VALUE self, const char *msg) {
  OdpMysql * conn;

  Data_Get_Struct(self, OdpMysql, conn);
  rb_raise(rb_eRuntimeError,
           "%s. Error %u: %s", msg, mysql_errno(conn->ptr), mysql_error(conn->ptr));
}

static void odp_free(OdpMysql *conn) {
  if (conn->connected) {
    mysql_close(conn->ptr);
  }
  free(conn);
}

/* -- Extension initialization -- */

void Init_oedipus(void) {
  VALUE mOedipus = rb_define_module("Oedipus");
  VALUE cMysql   = rb_define_class_under(mOedipus, "Mysql", rb_cObject);

  rb_define_method(cMysql, "initialize", odp_initialize, 2);
  rb_define_method(cMysql, "open",       odp_open,       0);
  rb_define_method(cMysql, "close",      odp_close,      0);
  rb_define_method(cMysql, "execute",    odp_execute,    1);
  rb_define_method(cMysql, "query",      odp_query,      1);

  rb_define_singleton_method(cMysql, "new",      odp_new,      2);
}
