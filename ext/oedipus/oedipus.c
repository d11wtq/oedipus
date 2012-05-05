/*-- encoding: utf-8 --*/

/*
 * Oedipus Sphinx 2 Search.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "oedipus.h"

/* -- Public methods -- */

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

  if (!conn->connected) {
    return Qfalse;
  }

  mysql_close(conn->ptr);
  conn->connected = 0;

  return Qtrue;
}

static VALUE odp_execute(int argc, VALUE * args, VALUE self) {
  VALUE       sql;
  OdpMysql  * conn;

  if (0 == argc) {
    rb_raise(rb_eArgError, "Wrong number of arguments (0 for 1..*)");
  }

  Check_Type(args[0], T_STRING);

  Data_Get_Struct(self, OdpMysql, conn);

  if (!conn->connected) {
    odp_raise(self, "Cannot execute query on a closed connection");
  }

  sql = odp_replace_bind_values(conn, args[0], &args[1], argc - 1);

  if (mysql_query(conn->ptr, RSTRING_PTR(sql))) {
    odp_raise(self, "Failed to execute statement(s)");
  }

  return INT2NUM(mysql_affected_rows(conn->ptr));
}

static VALUE odp_query(int argc, VALUE * args, VALUE self) {
  VALUE           sql;
  OdpMysql      * conn;
  MYSQL_RES     * rs;
  int             status;
  int             num_fields;
  MYSQL_ROW       row;
  MYSQL_FIELD   * fields;
  unsigned long * lengths;
  int             i;
  VALUE           rows;
  VALUE           hash;
  VALUE           results;

  if (0 == argc) {
    rb_raise(rb_eArgError, "Wrong number of arguments (0 for 1..*)");
  }

  Check_Type(args[0], T_STRING);

  Data_Get_Struct(self, OdpMysql, conn);

  if (!conn->connected) {
    odp_raise(self, "Cannot execute query on a closed connection");
  }

  sql = odp_replace_bind_values(conn, args[0], &args[1], argc - 1);

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
        lengths = mysql_fetch_lengths(rs);
        rb_ary_push(rows, (hash = rb_hash_new()));
        for (i = 0; i < num_fields; ++i) {
          rb_hash_aset(hash,
                       rb_str_new2(fields[i].name),
                       odp_cast_value(fields[i], row[i], lengths[i]));
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

static void odp_raise(VALUE self, const char * msg) {
  OdpMysql * conn;

  Data_Get_Struct(self, OdpMysql, conn);
  rb_raise(rb_path2class("Oedipus::ConnectionError"),
           "%s. Error %u: %s", msg, mysql_errno(conn->ptr), mysql_error(conn->ptr));
}

static void odp_free(OdpMysql * conn) {
  if (conn->connected) {
    mysql_close(conn->ptr);
  }
  free(conn);
}

static VALUE odp_replace_bind_values(OdpMysql * conn, VALUE sql, VALUE * bind_values, int num_values) {
  int           i;
  VALUE         v;
  VALUE         q;
  VALUE         idx;

  q   = rb_str_new("?", 1);
  sql = rb_funcall(sql, rb_intern("dup"), 0);

  // FIXME: Do a real lexical scan of the string, to avoid replacing '?' inside comments/strings

  for (i = 0; i < num_values; ++i) {
    if ((idx = rb_funcall(sql, rb_intern("index"), 1, q)) == Qnil) {
      break;
    }

    v = bind_values[i];

    if (ODP_KIND_OF_P(v, rb_cInteger)) {
      ODP_STR_SUB(sql, idx, ODP_TO_S(v));
    } else if (ODP_KIND_OF_P(v, rb_cNumeric)) {
      ODP_STR_SUB(sql, idx, ODP_TO_S(ODP_TO_F(v)));
    } else {
      if (T_STRING != TYPE(v)) {
        v = ODP_TO_S(v);
      }

      {
        char          * v_ptr = RSTRING_PTR(v);
        unsigned long   v_len = strlen(v_ptr);

        char escaped_str [v_len * 2 + 1];
        char quoted_str  [v_len * 2 + 3];

        mysql_real_escape_string(conn->ptr, escaped_str, v_ptr, v_len);
        sprintf(quoted_str, "'%s'", escaped_str);
        ODP_STR_SUB(sql, idx, rb_str_new2(quoted_str));
      }
    }
  }

  return sql;
}

static VALUE odp_cast_value(MYSQL_FIELD f, char * v, unsigned long len) {
  short  s;
  int    i;
  long   l;
  double d;

  // FIXME: Add the DATETIME, TIMESTAMP, TIME, DATE and YEAR conversions
  switch (f.type) {
    case MYSQL_TYPE_NULL:
      return Qnil;

    case MYSQL_TYPE_TINY:
    case MYSQL_TYPE_SHORT:
      sscanf(v, "%hd", &s);
      return INT2NUM(s);

    case MYSQL_TYPE_LONG:
      sscanf(v, "%d", &i);
      return INT2NUM(i);

    case MYSQL_TYPE_INT24:
    case MYSQL_TYPE_LONGLONG:
      sscanf(v, "%ld", &l);
      return INT2NUM(l);

    case MYSQL_TYPE_DECIMAL:
    case MYSQL_TYPE_NEWDECIMAL:
      return rb_funcall(rb_path2class("BigDecimal"),
                        rb_intern("new"),
                        1,
                        rb_str_new(v, len));

    case MYSQL_TYPE_DOUBLE:
    case MYSQL_TYPE_FLOAT:
      sscanf(v, "%lf", &d);
      return DBL2NUM(d);

    case MYSQL_TYPE_STRING:
    case MYSQL_TYPE_VAR_STRING:
    case MYSQL_TYPE_BLOB:
    case MYSQL_TYPE_SET:
    case MYSQL_TYPE_ENUM:
    default:
      return rb_str_new(v, len);
  }
}

/* -- Extension initialization -- */

void Init_oedipus(void) {
  VALUE mOedipus;
  VALUE cMysql;

  rb_require("bigdecimal");

  mOedipus = rb_define_module("Oedipus");
  cMysql   = rb_define_class_under(mOedipus, "Mysql", rb_cObject);

  rb_define_method(cMysql, "initialize", odp_initialize, 2);
  rb_define_method(cMysql, "open",       odp_open,       0);
  rb_define_method(cMysql, "close",      odp_close,      0);
  rb_define_method(cMysql, "execute",    odp_execute,   -1);
  rb_define_method(cMysql, "query",      odp_query,     -1);

  rb_define_singleton_method(cMysql, "new",  odp_new, 2);
}
