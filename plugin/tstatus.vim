" File: tstatus.vim
" Author: Thomas Lovén
" Description: My status line in vim
" Last Modified: Maj 23, 2013

if exists('g:tstatus_loaded')
  finish
endif

let g:tstatus_loaded = 1


" STATUS LINE {{{

" COLORS {{{
hi StatusLine cterm=NONE ctermbg=16 ctermfg=2
hi StatusLineNC cterm=NONE ctermbg=16 ctermfg=11
hi StatLineText cterm=NONE ctermbg=16 ctermfg=NONE
hi StatLineFN cterm=NONE ctermbg=16 ctermfg=2
hi StatLinePos cterm=reverse ctermbg=16 ctermfg=2
hi StatLinePaste cterm=NONE ctermbg=16 ctermfg=1
hi StatLineGitClean cterm=NONE ctermbg=16 ctermfg=2
hi StatLineGitDirty cterm=NONE ctermbg=16 ctermfg=1
hi StatLineHLInsert cterm=reverse ctermfg=2
hi StatLineHLReplace cterm=reverse ctermfg=1
hi StatLineHLV cterm=reverse ctermfg=6
hi StatLineHLVline cterm=reverse ctermfg=4
hi StatLineHLVblock cterm=reverse ctermfg=13
" }}}

function! s:CreateColor(name, type, bg, fg)
  let command = printf('hi tstatus_%s', a:name)

  if len(a:type) > 0 
    let command = command . printf(' cterm=%s', a:type)
  else
    let command = command . ' cterm=NONE'
  endif

  if len(a:bg) > 0
    let command = command . printf(' ctermbg=%s', a:bg)
  endif

  if len(a:fg) > 0
    let command = command . printf(' ctermfg=%s', a:fg)
  endif

  echom command
endfunction

function! MakeInactiveStatusLine(num) "{{{
  let filet = getwinvar(a:num, "&ft")
  let buname = bufname(winbufnr(a:num))
  if filet == "nerdtree"
    let statLine = getbufvar(winbufnr(a:num), "NERDTreeRoot").path.str()
    return statLine
  elseif filet == "tagbar"
    return '[TagBar]'
  elseif filet == "qf"
    return '[Quickfix list]'
  elseif filet == "gundo"
    return '[Gundo]'
  endif
  if buname == "__Gundo_Preview__"
    return '[Gundo preview]'
  endif
  let statLine = '%n: %<%f%m%r%=%y %p%% (%l:%c)'
  return statLine
endfunction "}}}

function! MakeActiveStatusLine() "{{{
  let filet = &ft
  let buname = bufname(winbufnr(winnr()))
  if filet == "nerdtree"
    return b:NERDTreeRoot.path.str()
  elseif filet == "tagbar"
    return '[TagBar]'
  elseif filet == "qf"
    return '[Quickfix list]'
  elseif filet == "gundo"
    return '[Gundo]'
  endif
  if buname == "__Gundo_Preview__"
    return '[Gundo preview]'
  endif
  let statLine = ''
  let statLine = statLine . '%#StatLineText#%n:'
  let statLine = statLine . '%#StatLinePaste#%{&paste?"[PASTE]":""}%#StatLineText#'
  
  if strlen(fugitive#head())
    let statLine = statLine . '%#StatLineText#['
    if strlen(system("git status -s --ignore-submodules=dirty 2>/dev/null"))
      let statLine = statLine . '%#StatLineGitDirty#'
    else
      let statLine = statLine . '%#StatLineGitClean#'
    endif
    let statLine = statLine . '%{fugitive#head()}%#StatLineText#]'
  endif

  let statLine = statLine . '%#StatLineFN#%< %f'
  let statLine = statLine . '%m%r '

  " Add mode coloring here!
  let mode = mode()
  if mode ==? 'i'
    let statLine = statLine . '%#StatLineHLInsert# Insert'
  elseif mode ==# 'v'
    let statLine = statLine .'%#StatLineHLV# Visual'
  elseif mode ==# 'V'
    let statLine = statLine .'%#StatLineHLVLine# Visual line'
  elseif mode ==# ''
    let statLine = statLine .'%#StatLineHLVBlock# Visual block'
  elseif mode ==# 'R'
    let statLine = statLine .'%#StatLineHLReplace# Replace'
  endif

  let statLine = statLine . '%='
  if strlen(&filetype)
    let statLine = statLine . '%#StatLineText# %y'
  endif
  let statLine = statLine . ' %#StatLinePos#%p%% (%l:%c)'
  return statLine
endfunction "}}}

function! UpdateStatusLines() "{{{
  for i in range(1, winnr('$'))
    if(i == winnr())
     call setwinvar(i, "&statusline", "%!MakeActiveStatusLine()")
    else
      call setwinvar(i, "&statusline", "%!MakeInactiveStatusLine(".i.")")
    endif
  endfor
endfunction "}}}

function! s:Startup()
  augroup tstatus
    au!
    au WinEnter,WinLeave * call UpdateStatusLines()
  augroup END
  call UpdateStatusLines()
endfunction

augroup tstatus_load
  au!
  au VimEnter * call s:Startup()
augroup END

" }}}

