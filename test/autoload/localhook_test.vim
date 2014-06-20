"******************************************************************************
" Note:
"   it require 'kannokanno/vimtest.vim'
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

execute localhook#hook(1)
let s:testcase = vimtest#new("vim-localhook testcase (localhook#XXX)")

function! s:testcase.test_sid()
  echomsg "SID:" . s:SID()
  " localhook#sid should return correct SID
  call self.assert.equals(localhook#sid(s:filename), s:SID())
  " localhook#sid should return "" if the file is not sourced
  call self.assert.equals(localhook#sid("not file"), "")
endfunction

function! s:testcase.test_function()
  let F = localhook#function(s:filename, 'SID')
  " Note: vimtest store lhs, rhs in 'expected', 'actual' thus it is not
  "       possible to compare the Funcref directory (variable name starts
  "       from a lower character)
  call self.assert.equals(F(), s:SID())
endfunction

function! s:testcase.test_call()
  let sid = localhook#call(s:filename, 'SID')
  call self.assert.equals(sid, s:SID())
endfunction

function! s:testcase.test_scope()
  execute localhook#hook(-1) | " disable
  let [safe, scope] = localhook#scope(s:filename, 1)
  call self.assert.equals(safe, -1)
  call self.assert.equals(scope, {})
  execute localhook#hook(1) | " safe hook
  let [safe, scope] = localhook#scope(s:filename, 1)
  call self.assert.equals(safe, 1)
  call self.assert.equals(scope, s:)
  call self.assert.false(scope is s:)
  execute localhook#hook(0) | " unsafe hook
  let [safe, scope] = localhook#scope(s:filename, 1)
  call self.assert.equals(safe, 0)
  call self.assert.equals(scope, s:)
  call self.assert.true(scope is s:)
endfunction

function! s:testcase.test_get()
  call self.assert.equals(localhook#get(s:filename, 'filename', 1), s:filename)
endfunction

function! s:testcase.test_set()
  let original = s:filename
  execute localhook#hook(1) | " safe hook
  call localhook#set(s:filename, 'filename', 'Hello', 1)
  call self.assert.equals(s:filename, original)
  execute localhook#hook(0) | " safe hook
  call localhook#set(s:filename, 'filename', 'Hello', 1)
  call self.assert.equals(s:filename, 'Hello')
  let s:filename = original
endfunction

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

let s:filename = expand('<sfile>')

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
