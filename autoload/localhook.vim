"******************************************************************************
" Hook module which hook script local variables and functions
"
" Reference:
"   - http://mattn.kaoriya.net/software/vim/20090826003359.htm
"   - http://d.hatena.ne.jp/kuhukuhun/20090712/1247345663
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim


function! s:get_local_sid(filename) abort " {{{
  " redirect scriptnames into snlist
  let snlist = ''
  redir => snlist
  silent! scriptnames
  redir END
  " create scriptnames and scriptid dictionary
  let smap = {}
  let pattern = '^\s*\(\d\+\):\s*\(.*\)$'
  for line in split(snlist, "\n")
    let scriptid = substitute(line, pattern, '\1', '')
    let scriptfile = substitute(line, pattern, '\2', '')
    let scriptfile = fnamemodify(expand(scriptfile), ':p')
    let smap[scriptfile] = scriptid
  endfor
  let filename = fnamemodify(expand(a:filename), ':p')
  return get(smap, filename, "")
endfunction " }}}
function! s:get_local_fname(filename, name) abort " {{{
  let sid = s:get_local_sid(a:filename)
  return "<SNR>" . sid . "_" . a:name
endfunction " }}}

function! s:get_hook_function(safe) abort " {{{
  if a:safe == -1
    " remove hook, it is only for testing use
    let code = "return [-1, {}]"
  elseif a:safe == 0
    " return raw s:
    let code = "return [0, s:]"
  else
    " return copied s:
    let code = "return [1, copy(s:)]"
  endif
  return "function! s:" . s:HOOK_FUNCTION_NAME . "()\n" . code . "\nendfunction"
endfunction " }}}
function! s:get_local_scope(filename, ...) abort " {{{
  let force = get(a:000, 0, 0)
  if !exists("s:local_scope_map")
    let s:local_scope_map = {}
  endif
  if !has_key(s:local_scope_map, a:filename) || force
    let fname = s:get_local_fname(a:filename, s:HOOK_FUNCTION_NAME)
    if !exists("*" . fname)
      redraw
      echohl WarningMsg
      echomsg 'Hook function is missing:'
      echohl None
      echo  'localhook#hook() need to be executed in the target script to enable '
      echon 'localhook#scope(), localhook#get(), localhook#set(). '
      echon 'See :help localhook#hook()'
      return [-1, {}]
    endif
    " get local scope of the specified scriptfile and store
    let [safe, scope] = call(fname, [])
    if safe == -1
      redraw
      echohl WarningMsg
      echomsg 'Hook function is disabled:'
      echohl None
      echo  'localhook#hook(-1) was executed in the target script. '
      echon 'See :help localhook#hook()'
      return [-1, {}]
    endif
    let s:local_scope_map[a:filename] = [safe, scope]
  endif
  return s:local_scope_map[a:filename]
endfunction " }}}


function! localhook#sid(filename) abort " {{{
  return s:get_local_sid(a:filename)
endfunction " }}}
function! localhook#function(filename, name) abort " {{{
  let F = function(s:get_local_fname(a:filename, a:name))
  return F
endfunction " }}}
function! localhook#call(filename, name, ...) abort " {{{
  let fname = s:get_local_fname(a:filename, a:name)
  return call(function(fname), a:000)
endfunction " }}}
function! localhook#hook(...) abort " {{{
  return s:get_hook_function(get(a:000, 0, 1))
endif
endfunction " }}}
function! localhook#scope(filename, ...) abort " {{{
  return call("s:get_local_scope", [a:filename] + a:000)
endfunction " }}}
function! localhook#get(filename, name, ...) abort " {{{
  let [safe, scope] = call("s:get_local_scope", [a:filename] + a:000)
  return get(scope, a:name, 0)
endfunction " }}}
function! localhook#set(filename, name, value, ...) abort " {{{
  let [safe, scope] = call("s:get_local_scope", [a:filename] + a:000)
  if safe != 0
    redraw
    echohl WarningMsg
    echomsg 'Hook function is defined as Safe hook:'
    echohl None
    echo  'localhook#hook(0) required to be executed in the target script. '
    echon 'See :help localhook#hook()'
    return {}
  else
    let scope[a:name] = a:value
  endif
endfunction " }}}


let s:HOOK_FUNCTION_NAME = '__localhook_get_scope'
let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
