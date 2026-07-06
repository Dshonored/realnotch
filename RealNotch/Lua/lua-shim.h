#ifndef LUA_SHIM_H
#define LUA_SHIM_H
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
/* luaL_newstate and LUA_REGISTRYINDEX are macros — wrap them so Swift can use them. */
static inline lua_State *ln_newstate(void) { return luaL_newstate(); }
static inline int ln_registryindex(void) { return LUA_REGISTRYINDEX; }
#endif
