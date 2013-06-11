" File: tstatus.vim
" Author: Thomas Lovén
" Description: My status line in vim
" Last Modified: Maj 23, 2013

if exists('g:tstatus_loaded')
  finish
endif

let g:tstatus_loaded = 1

" Old functions for reference
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



let NONE = 'NONE'
let reverse = 'reverse'

" LINES {{{
let g:ActiveLineLeft = [
      \ ['num', [NONE, 16, NONE] ,[]],
      \ ['filename', [NONE, 16, 2], []],
      \ ['statusflags', [NONE, 16, NONE], [[NONE, 16, 2], '+', [NONE, 16, 1], '-']]
      \ ]
let g:ActiveLineRight = [
      \ ['filetype', [NONE, 16, NONE], []],
      \ ['percent' , [reverse, 16, 2], []],
      \ ['position', [reverse, 16, 2], []],
      \ ['git', [NONE, 16, NONE], [[NONE, 16, 2],[NONE, 16, 1]]]
      \]

let g:InactiveLineLeft = [
      \ ['num', [NONE, NONE, 3], []],
      \ ['filename', [NONE, NONE, 3], []]
      \]
let g:InactiveLineRight = [
      \ ['git', [NONE, NONE, 3], [[NONE, NONE, 2],[NONE, NONE, 1]]]
      \]
" }}}
" COLORS {{{
hi StatusLine cterm=NONE ctermbg=16 ctermfg=2
hi StatusLineNC cterm=NONE ctermbg=16 ctermfg=11

let g:tstatus_modeColors = {
      \ 'normal': [NONE, 16, 2],
      \ 'insert': [reverse, 16, 2],
      \ 'replace': [reverse, 16, 1],
      \ 'visual': [reverse, 16, 6],
     \ 'visline': [reverse, 16, 4],
      \ 'visblock': [reverse, 16, 13],
      \ }
let g:tstatus_specColors = {
      \ 'nerdtree': [[NONE, NONE, 2], [NONE, NONE, 2]],
      \ 'tagbar': [[NONE, NONE, 2], [NONE, NONE, 3]],
      \ 'quickfix': [NONE, NONE, 3],
      \ 'gundolist': [NONE, NONE, 3],
      \ 'gundoprev': [NONE, NONE, 3]
      \ }
" }}}

function! s:CreateColor(color) "{{{
  let type = a:color[0]
  let bg = a:color[1]
  let fg = a:color[2]
  let hi_name = printf('tstatus_%s%s%s', type, bg, fg)

  if ! hlexists(hi_name)
    let command = printf('hi %s', hi_name)

    if len(type) > 0 
      let command = command . printf(' cterm=%s', type)
    else
      let command = command . ' cterm=NONE'
    endif

    if len(bg) > 0
      let command = command . printf(' ctermbg=%s', bg)
    endif

    if len(fg) > 0
      let command = command . printf(' ctermfg=%s', fg)
    endif

    execute command
  endif

  return hi_name

endfunction "}}}

function! ParseGit(bufnum, segment) "{{{
  " If on a git branch
  " print [branchname]
  " with branchname colored depending on git status

  let ret = ''
  let fpath = fnamemodify(bufname(winbufnr(a:bufnum)),":p:h")

  let gitref = system("cd ". fpath. "; git symbolic-ref HEAD 2> /dev/null")
  let gitref = substitute(gitref, "refs/heads/", "", "")
  let gitref = substitute(gitref, "\n", "", "")

  if strlen(gitref)
    let gitstat = system("cd ". fpath. "; git status -s --ignore-submodules=dirty 2>/dev/null")

    let colors = a:segment[2]
    if strlen(gitstat)
      let gitcolor = colors[1]
    else
      let gitcolor = colors[0]
    endif

    let ret .= '['
    let ret .= '%#'. s:CreateColor(gitcolor). '#'
    let ret .= gitref
    let ret .= '%#'. s:CreateColor(a:segment[1]). '#'
    let ret .= ']'

  endif
  return ret
endfunction "}}}

function! SpecialLine(bufnum, active) "{{{
  let ftype = getwinvar(a:bufnum, "&ft")
  let bname = bufname(winbufnr(a:bufnum))

  let ret = ''

  if ftype == "nerdtree"
    let nerdroot = getbufvar(winbufnr(a:bufnum), "NERDTreeRoot").path.str()
    let ret = '%#'. s:CreateColor(g:tstatus_specColors['nerdtree'][a:active]). '#'
    let ret .= substitute(nerdroot, ".*/", "", "")
  endif

  return ret
endfunction "}}}

function! ParseLine(bufnum, line) "{{{

  let ret = ''

  for j in range(0, len(a:line)-1)
    let segment = a:line[j]
    let name = segment[0]
    let color = segment[1]
    let segdata = segment[2]

    let ret .= '%#'. s:CreateColor(color). '#'

    if name == 'num'
      " Buffer number
      let ret .= '%n:'

    elseif name == 'git'
      let ret .= ParseGit(a:bufnum, a:line[j])

    elseif name == 'filename'
      " Filename
      let ret .= '%< %f'
    
    elseif name == 'modified'
      " Modified flag
        let ret .= '%m'

    elseif name == 'readonly'
      " Readonly flag
      let ret .= '%r'

    elseif name == 'statusflags'
      " Modified and readonly flags
      if or(&modified, !&modifiable)
        let ret .= '['
        if !&modifiable
          let ret .= '%#'. s:CreateColor(segdata[2]). '#'. segdata[3]
        endif
        if &modified
          let ret .= '%#'. s:CreateColor(segdata[0]). '#'. segdata[1]
        endif
        let ret .= '%#'. s:CreateColor(color).'#'
        let ret .= ']'
      endif

    elseif name == 'filetype'
      " Filetype indicator
      let ret .= '%y'

    elseif name == 'percent'
      " Position percent
      let ret .= '%p%%'

    elseif name == 'position'
      " Line and collumn
      let ret .= '(%l:%c)'

    endif

  endfor
  return ret
endfunction "}}}

function! StatuslineMiddle() "{{{
  let ret = ' '
  let mode = mode()
  if mode ==? 'i'
    let ret .= '%#'. s:CreateColor(g:tstatus_modeColors['insert']). '# Insert'
  elseif mode ==# 'v'
    let ret .= '%#'. s:CreateColor(g:tstatus_modeColors['visual']). '# Visual'
  elseif mode ==# 'V'
    let ret .= '%#'. s:CreateColor(g:tstatus_modeColors['visline']). '# Visual line'
  elseif mode ==# ''
    let ret .= '%#'. s:CreateColor(g:tstatus_modeColors['visblock']). '# Visual block'
  elseif mode ==# 'R'
    let ret .= '%#'. s:CreateColor(g:tstatus_modeColors['replace']). '# Replace'
  else
    let ret .= '%#'. s:CreateColor(g:tstatus_modeColors['normal']). '#'
  endif

  let ret .= '%= '

  return ret
endfunction "}}}

function! BuildStatusLine(num, active) "{{{
  let ret = ''
  let special = SpecialLine(a:num, a:active)
  if strlen(special)
    return special
  endif
  if a:active
    let ret .= ParseLine(a:num, g:ActiveLineLeft)
    let ret .= StatuslineMiddle()
    let ret .= ParseLine(a:num, g:ActiveLineRight)
  else
    let ret .= ParseLine(a:num, g:InactiveLineLeft)
    let ret .= '%='
    let ret .= ParseLine(a:num, g:InactiveLineRight)
  endif
  return ret
endfunction "}}}

function! UpdateStatusLines() " {{{

  for i in range(1, winnr('$'))
    if(i == winnr())
     call setwinvar(i, "&statusline", "%!BuildStatusLine(".i.", 1)")
    else
      call setwinvar(i, "&statusline", "%!BuildStatusLine(".i.", 0)")
    endif
  endfor
endfunction "}}}

function! s:Startup()
  augroup tstatus
    au!
    au  BufEnter,BufLeave,BufUnLoad,CmdWinEnter,CmdWinLeave,WinEnter,WinLeave * call UpdateStatusLines()
  augroup END
  call UpdateStatusLines()
endfunction

augroup tstatus_load
  au!
  au VimEnter * call s:Startup()
augroup END


