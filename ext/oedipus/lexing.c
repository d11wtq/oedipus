/*-- encoding: utf-8 --*/

/*
 * Oedipus Sphinx 2 Search.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "lexing.h"

/* WARNING: Complex pointer (but fast) arithmetic in here... avert your eyes */

int odp_scan_until_char(char stop, char ** sql_ptr, char ** dest_ptr, unsigned long len) {
  char * end = *sql_ptr + len;

  for (; *sql_ptr < end; ++(*sql_ptr)) {
    *((*dest_ptr)++) = **sql_ptr;

    if (**sql_ptr == '\\') {
      if (*sql_ptr < end) {
        *((*dest_ptr)++) = *(++(*sql_ptr)); // consume char following escape
      }
    } else if (**sql_ptr == stop) {
      return 1;
    }
  }

  return 0;
}

int odp_scan_multi_line_comment(char ** sql_ptr, char ** dest_ptr, unsigned long len) {
  char * end = *sql_ptr + len;

  for (; *sql_ptr < end; ++(*sql_ptr)) {
    *((*dest_ptr)++) = **sql_ptr;

    if (**sql_ptr == '*') {
      if ((*sql_ptr < end) && (*((*dest_ptr)++) = *(++(*sql_ptr))) == '/') {
        return 1;
      }
    }
  }

  return 0;
}

int odp_scan_until_marker(char ** sql_ptr, char ** dest_ptr, long len) {
  char * end = *sql_ptr + len;
  char   c;

  for (; *sql_ptr < end; ++(*sql_ptr)) {
    c = **sql_ptr;
    *((*dest_ptr)++) = c;

    switch (c) {
    case '\\':
      if (*sql_ptr < end) {
        *((*dest_ptr)++) = *(++(*sql_ptr));
      }
      break;
    case '\'':
      ++(*sql_ptr);
      odp_scan_until_char('\'', sql_ptr, dest_ptr, end - *sql_ptr);
      break;
    case '"':
      ++(*sql_ptr);
      odp_scan_until_char('"', sql_ptr, dest_ptr, end - *sql_ptr);
      break;
    case '/':
      if ((*sql_ptr < end) && *(*sql_ptr + 1) == '*') {
        *((*dest_ptr)++) = *(++(*sql_ptr)); // consume '*' following '/'
        ++(*sql_ptr);
        odp_scan_multi_line_comment(sql_ptr, dest_ptr, end - *sql_ptr);
      }
      break;
    case '#':
      ++(*sql_ptr);
      odp_scan_until_char('\n', sql_ptr, dest_ptr, end - *sql_ptr);
      break;
    case '-':
      // FIXME: This shouldn't really work for things like ------ comment
      if (((*sql_ptr + 1) < end) && *(*sql_ptr + 1) == '-' && *(*sql_ptr + 2) == ' ') {
        ++(*sql_ptr);
        odp_scan_until_char('\n', sql_ptr, dest_ptr, end - *sql_ptr);
      }
      break;
    case '?':
      ++(*sql_ptr);  // discard
      --(*dest_ptr); // unconsume
      return 1;
    }
  }

  return 0;
}
