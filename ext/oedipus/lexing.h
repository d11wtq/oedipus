/*-- encoding: utf-8 --*/

/*
 * Oedipus Sphinx 2 Search.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

/*! Consume input from the string pointed to by sql_ptr, into the string pointed to by dest_ptr, until stop is reached (inclusive) */
int odp_scan_until_char(char stop, char ** sql_ptr, char ** dest_ptr, unsigned long len);

/*! Consume input from the string pointed to by sql_ptr, into the string pointed to by dest_ptr, until the end of a multi-line comment is reached (inclusive)  */
int odp_scan_multi_line_comment(char ** sql_ptr, char ** dest_ptr, unsigned long len);

/*! Consume input from the string pointed to by sql_ptr, into the string pointed to by dest_ptr, until '?' is found */
int odp_scan_until_marker(char ** sql_ptr, char ** dest_ptr, long len);
