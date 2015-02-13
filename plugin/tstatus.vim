" File: tstatus.vim
" Author: Thomas Lovén
" Description: My status line in vim

if exists('g:tstatus_loaded')
  finish
endif

let g:tstatus_loaded = 1


let NONE = 'NONE'
let reverse = 'reverse'

" LINES {{{
let g:ActiveLineLeft = [
      \ ['num', [NONE, 16, NONE] ,[]],
      \ ['filename', [NONE, 16, 2], []],
      \ ['statusflags', [NONE, 16, NONE], [[NONE, 16, 1], '+', [NONE, 16, 1], '-']]
      \ ]
let g:ActiveLineRight = [
      \ ['filetype', [NONE, 16, NONE], []],
      \ ['percent' , [reverse, 16, 2], []],
      \ ['position', [reverse, 16, 2], []],
      \ ['git', [NONE, 16, NONE], [[NONE, 16, 2],[NONE, 16, 1]]]
      \]

let g:InactiveLineLeft = [
      \ ['num', [NONE, NONE, 3], []],
      \ ['filename', [NONE, NONE, 3], []],
      \ ['statusflags', [NONE, NONE, NONE], [[NONE, NONE, 1], '+', [NONE, NONE, 1], '+']]
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
" }}}

function! s:CreateColor(color) "{{{
  let type = a:color[0]
  let bg = a:color[1]
  let fg = a:color[2]
  let hi_name = printf('tstatus_%s%s%s', type, bg, fg)

  if ! hlexists(hi_name)

    let hi_data = printf('cterm=%s', type)
    let hi_data = hi_data . printf(' ctermbg=%s', bg)
    let hi_data = hi_data . printf(' ctermfg=%s', fg)

    let g:tstatus_colors[hi_name] = hi_data
    let command = printf('hi %s %s', hi_name, hi_data)
    execute command
  endif

  return hi_name

endfunction "}}}

function! s:RemakeColors() "{{{
  let colors = items(g:tstatus_colors)
  for i in range(0, len(colors)-1)
    let command = printf('hi %s %s', colors[i][0], colors[i][1])
    execute command
  endfor
endfunction "}}}

function! ParseGit(bufnum, segment) "{{{
  " If on a git branch
  " print [branchname]
  " with branchname colored depending on git status
  return '[git]'
  let ret = ''
  let fpath = fnamemodify(bufname(winbufnr(a:bufnum)),":p:h")

  let gitref = system("cd '". fpath. "'; git symbolic-ref HEAD 2> /dev/null")
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
  let NONE = 'NONE'
  let reverse = 'reverse'
  let ftype = getwinvar(a:bufnum, "&ft")
  let bname = bufname(winbufnr(a:bufnum))

  let ret = ''

  if ftype == "nerdtree"
    let colorActive = [NONE, 16, 2]
    let colInActive = [NONE, NONE, 2]
    let color = [colInActive, colorActive]
    let ret = '%#'. s:CreateColor(color[a:active]). '#'

    let nerdroot = getbufvar(winbufnr(a:bufnum), "NERDTreeRoot").path.str()
    let ret .= substitute(nerdroot, ".*/", "", "")
  endif

  if ftype == "tagbar"
    let colorActive = [NONE, 16, 2]
    let colInActive = [NONE, NONE, 3]
    let color = [colInActive, colorActive]
    let ret = '%#'. s:CreateColor(color[a:active]). '#'

    let ret .= '%=[TAGBAR]'
  endif

  if ftype == "qf"
    let colorActive = [NONE, 16, 2]
    let colInActive = [NONE, NONE, 3]
    let color = [colInActive, colorActive]
    let ret = '%#'. s:CreateColor(color[a:active]). '#'

    let ret .= '[Quickfix]'
  endif

  if ftype == "gundo"
    let colorActive = [NONE, 16, 2]
    let colInActive = [NONE, NONE, 3]
    let color = [colInActive, colorActive]
    let ret = '%#'. s:CreateColor(color[a:active]). '#'

    let ret .= '[Gundo]'
  endif
  if bname == "__Gundo_Preview__"
    let colorActive = [NONE, 16, 2]
    let colInActive = [NONE, NONE, 3]
    let color = [colInActive, colorActive]
    let ret = '%#'. s:CreateColor(color[a:active]). '#'

    let ret .= '[Gundo preview]'
  endif

  if ftype == "help"
    let colorActive = [NONE, 16, 2]
    let colInActive = [NONE, NONE, 3]
    let color = [colInActive, colorActive]
    let ret = '%#'. s:CreateColor(color[a:active]). '#'

    let ret .= '[HELP] %f'
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
      let modified = getbufvar(winbufnr(a:bufnum), "&modified")
      let modifiable = getbufvar(winbufnr(a:bufnum), "&modifiable")
      if or(modified, !modifiable)
        let ret .= '['
        if !modifiable
          let ret .= '%#'. s:CreateColor(segdata[2]). '#'. segdata[3]
        endif
        if modified
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
    let clr = s:CreateColor(g:tstatus_modeColors['visual'])
    let ret .= '%#'. clr. '# Visual'
    hi Visual NONE
    execute printf('hi link Visual %s', clr)
  elseif mode ==# 'V'
    let clr = s:CreateColor(g:tstatus_modeColors['visline'])
    let ret .= '%#'. clr. '# Visual'
    hi Visual NONE
    execute printf('hi link Visual %s', clr)
  elseif mode ==# ''
    let clr = s:CreateColor(g:tstatus_modeColors['visblock'])
    let ret .= '%#'. clr. '# Visual'
    hi Visual NONE
    execute printf('hi link Visual %s', clr)
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
  let g:tstatus_colors = {}
  augroup tstatus
    au!
    au  BufEnter,BufLeave * call UpdateStatusLines()
    au BufUnLoad,Filetype * call UpdateStatusLines()
    au CmdWinEnter,CmdWinLeave * call UpdateStatusLines()
    au WinEnter,WinLeave * call UpdateStatusLines()
    au colorscheme * Trepaint
  augroup END
  call UpdateStatusLines()
  command Trepaint call s:RemakeColors()
endfunction

augroup tstatus_load
  au!
  au VimEnter * call s:Startup()
augroup END


