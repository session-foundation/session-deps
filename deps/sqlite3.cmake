# There is no static build of stock sqlite3 here: the fallback is SQLite3 Multiple Ciphers, which
# is sqlite3 with encryption bolted on.  A project that only wants a plain sqlite3 is satisfied by
# it (just ignore the encryption), and it is the build the other Session projects already use, so
# this keeps everyone on one sqlite rather than two.
#
# This exists as a separate script from sqlite3mc.cmake because session_dep() uses one name for both
# the pkg-config module it looks for and the build script it falls back to.  The system package is
# called sqlite3 and our static build is called sqlite3mc, so `session_dep(sqlite3mc ...)` would
# never match a system library (no distro ships a sqlite3mc.pc) and would always build static.  Use
# `session_dep(sqlite3 <minver>)` to get the usual find-system-or-else-build behaviour, and
# `session_dep(sqlite3mc <minver>)` when the encryption support specifically is required.
session_dep(sqlite3mc 2)

sessiondep_bundle(sqlite3 sessiondep::sqlite3mc)
