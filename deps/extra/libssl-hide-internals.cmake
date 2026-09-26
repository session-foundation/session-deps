# Run in script mode by libssl.cmake after `make install_dev`:
#
#   cmake -DLIBDIR=<destdir>/lib -DSOURCE_DIR=<openssl source> -DAR=... -DLD=... -DNM=...
#         [-DOBJCOPY=...] -P libssl-hide-internals.cmake
#
# Rewrites libcrypto.a and libssl.a so that only OpenSSL's public API is global.  OpenSSL's
# assembly (the CRYPTOGAMS aesni_*/gcm_*/sha*_block_data_order routines) is defined under global
# names that gnutls also carries, so the two static archives cannot otherwise be linked into one
# binary.  The shared libraries avoid this with a version script; a static archive gets no such
# filtering, so it is done here: every member is merged into one relocatable object, every symbol
# not in OpenSSL's own export list (util/lib*.num, the same list its version script is generated
# from) is made local, and the archive is rebuilt from that one object.
#
# libssl also uses libcrypto internals that are not in that list (WPACKET_*, ossl_crypto_mutex_*
# and the like: in a shared build they reach it by other means), so whatever libssl leaves undefined
# stays global in libcrypto as well.
#
# Being one object, the whole library is linked into anything that uses any of it.

foreach(var LIBDIR SOURCE_DIR AR LD NM)
    if(NOT ${var})
        message(FATAL_ERROR "libssl-hide-internals: ${var} not set")
    endif()
endforeach()
if(NOT APPLE AND NOT OBJCOPY)
    message(FATAL_ERROR "libssl-hide-internals: OBJCOPY not set")
endif()

# Mach-O symbol names carry a leading underscore, which the export list has to include.
set(sym_prefix "")
if(APPLE)
    set(sym_prefix "_")
endif()

function(run)
    execute_process(COMMAND ${ARGN} RESULT_VARIABLE rc)
    if(rc)
        list(JOIN ARGN " " cmd)
        message(FATAL_ERROR "libssl-hide-internals: command failed (${rc}): ${cmd}")
    endif()
endfunction()

foreach(lib crypto ssl)
    set(archive ${LIBDIR}/lib${lib}.a)
    set(exports ${SOURCE_DIR}/util/lib${lib}.num)
    foreach(f archive exports)
        if(NOT EXISTS ${${f}})
            message(FATAL_ERROR "libssl-hide-internals: ${${f}} does not exist")
        endif()
    endforeach()

    # Each line is `name ordinal version EXIST::FUNCTION:...` (or VARIABLE); removed symbols are
    # kept in the file as NOEXIST.
    file(STRINGS ${exports} export_lines)
    set(keep)
    foreach(line IN LISTS export_lines)
        if(line MATCHES "^([A-Za-z0-9_]+)[ \t]+[0-9]+[ \t]+[0-9_]+[ \t]+EXIST:")
            list(APPEND keep ${sym_prefix}${CMAKE_MATCH_1})
        endif()
    endforeach()
    list(LENGTH keep nkeep)
    if(nkeep LESS 100)
        message(FATAL_ERROR "libssl-hide-internals: only ${nkeep} exported symbols parsed from ${exports}")
    endif()

    if(lib STREQUAL crypto)
        # libssl.a is still the original here (crypto is processed first), and its undefined
        # symbols are what it needs from libcrypto beyond the export list.
        execute_process(COMMAND ${NM} -u ${LIBDIR}/libssl.a OUTPUT_VARIABLE ssl_undefined RESULT_VARIABLE rc)
        if(rc)
            message(FATAL_ERROR "libssl-hide-internals: ${NM} -u ${LIBDIR}/libssl.a failed")
        endif()
        string(REPLACE "\n" ";" ssl_undefined "${ssl_undefined}")
        set(nextra 0)
        # GNU and llvm nm print `U name` (with an empty value column); Apple's nm prints the bare
        # name.  Member headers end in a colon.
        foreach(line IN LISTS ssl_undefined)
            string(REGEX MATCHALL "[^ \t\r]+" tokens "${line}")
            list(LENGTH tokens ntokens)
            set(name)
            if(ntokens EQUAL 1)
                list(GET tokens 0 name)
                if(name MATCHES ":$")
                    set(name)
                endif()
            elseif(ntokens GREATER_EQUAL 2)
                math(EXPR type_idx "${ntokens} - 2")
                list(GET tokens ${type_idx} type)
                if(type STREQUAL "U")
                    list(GET tokens -1 name)
                endif()
            endif()
            if(name)
                list(APPEND keep ${name})
                math(EXPR nextra "${nextra} + 1")
            endif()
        endforeach()
        if(nextra LESS 10)
            list(SUBLIST ssl_undefined 0 8 sample)
            list(JOIN sample "\n  " sample)
            message(FATAL_ERROR "libssl-hide-internals: only ${nextra} undefined symbols parsed from "
                "libssl.a; ${NM} -u printed:\n  ${sample}")
        endif()
        list(REMOVE_DUPLICATES keep)
        list(LENGTH keep nkeep)
    endif()

    set(work ${LIBDIR}/hide-${lib})
    file(REMOVE_RECURSE ${work})
    file(MAKE_DIRECTORY ${work})
    list(JOIN keep "\n" keep_text)
    file(WRITE ${work}/exports.txt "${keep_text}\n")

    # `ar x` writes members by basename, so two members with one name would leave only the last.
    execute_process(COMMAND ${AR} t ${archive} OUTPUT_VARIABLE members RESULT_VARIABLE rc)
    if(rc)
        message(FATAL_ERROR "libssl-hide-internals: ${AR} t ${archive} failed")
    endif()
    string(REGEX REPLACE "\n$" "" members "${members}")
    string(REPLACE "\n" ";" members "${members}")
    # Apple's ar lists the archive's own symbol table as a member.
    list(FILTER members EXCLUDE REGEX "^__\\.SYMDEF")
    list(LENGTH members nmembers)
    list(REMOVE_DUPLICATES members)
    list(LENGTH members nunique)
    if(NOT nmembers EQUAL nunique)
        message(FATAL_ERROR "libssl-hide-internals: ${archive} has members with duplicate names")
    endif()

    # Into a subdirectory so that a member can never share a name with the merged output.
    file(MAKE_DIRECTORY ${work}/members)
    execute_process(COMMAND ${AR} x ${archive} WORKING_DIRECTORY ${work}/members RESULT_VARIABLE rc)
    if(rc)
        message(FATAL_ERROR "libssl-hide-internals: extracting ${archive} failed")
    endif()
    file(GLOB objects ${work}/members/*.o ${work}/members/*.obj)
    list(LENGTH objects nobjects)
    if(NOT nobjects EQUAL nmembers)
        message(FATAL_ERROR "libssl-hide-internals: ${archive} has ${nmembers} members but ${nobjects} were extracted")
    endif()

    run(${LD} -r -o ${work}/merged.o ${objects})
    if(APPLE)
        # ld64 has no objcopy, but its -r mode applies an export list itself, turning everything
        # not listed into a private extern.  Unlike objcopy it also insists that every listed
        # symbol exist, and the list has libc and libssl names in it (from libssl's undefined
        # symbols), so it is first cut down to what the object defines.
        execute_process(COMMAND ${NM} -g --defined-only ${work}/merged.o OUTPUT_VARIABLE defined RESULT_VARIABLE rc)
        if(rc)
            message(FATAL_ERROR "libssl-hide-internals: ${NM} -g --defined-only ${work}/merged.o failed")
        endif()
        string(REPLACE "\n" ";" defined "${defined}")
        foreach(line IN LISTS defined)
            string(REGEX MATCHALL "[^ \t\r]+" tokens "${line}")
            list(LENGTH tokens ntokens)
            if(ntokens GREATER_EQUAL 2)
                list(GET tokens -1 name)
                set(defined_${name} 1)
            endif()
        endforeach()
        set(exports)
        foreach(name IN LISTS keep)
            if(DEFINED defined_${name})
                list(APPEND exports ${name})
            endif()
        endforeach()
        list(LENGTH exports nkeep)
        list(JOIN exports "\n" keep_text)
        file(WRITE ${work}/exports.txt "${keep_text}\n")
        run(${LD} -r -exported_symbols_list ${work}/exports.txt -o ${work}/hidden.o ${work}/merged.o)
        file(RENAME ${work}/hidden.o ${work}/merged.o)
    else()
        run(${OBJCOPY} --keep-global-symbols=${work}/exports.txt ${work}/merged.o)
    endif()

    file(REMOVE ${archive})
    run(${AR} rcs ${archive} ${work}/merged.o)
    file(REMOVE_RECURSE ${work})
    message(STATUS "libssl-hide-internals: rebuilt ${archive} with ${nkeep} exported symbols")
endforeach()
