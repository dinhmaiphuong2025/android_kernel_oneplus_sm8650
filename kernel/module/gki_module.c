// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright 2022 Google LLC
 * Author: ramjiyani@google.com (Ramji Jiyani)
 */

#include <linux/bsearch.h>
#include <linux/errno.h>
#include <linux/kernel.h>
#include <linux/printk.h>
#include <linux/string.h>

/*
 * Build time generated header files
 *
 * gki_module_protected_exports.h -- Symbols protected from _export_ by unsigned modules
 * gki_module_unprotected.h -- Symbols allowed to _access_ by unsigned modules
 */
#include <generated/gki_module_protected_exports.h>
#include <generated/gki_module_unprotected.h>

/**
 * gki_is_module_protected_export - Is a symbol exported from a protected GKI module?
 *
 * @name:	Symbol being checked against exported symbols from protected GKI modules
 */
bool gki_is_module_protected_export(const char *name)
{
	return false;
}

/**
 * gki_is_module_unprotected_symbol - Is a symbol unprotected for unsigned module?
 *
 * @name:	Symbol being checked in list of unprotected symbols
 */
bool gki_is_module_unprotected_symbol(const char *name)
{
	return true;
}
