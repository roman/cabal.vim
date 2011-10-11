let s:save_cpo = &cpo
set cpo&vim

if exists("g:loaded_cabal_vim")
  finish
endif
let g:loaded_cabal_vim = 1

" If quickrun is available, we are going to
" set a new keybinding
if exists('g:quickrun_config')
 function! s:enable_quickrun_for_cabal()
    if exists('b:cabal_file_present')
      let l:cabal_file = glob(b:current_cabal_path . '/*.cabal')
      let l:binary_name = substitute(l:cabal_file,
            \ '.\+/\(.\+\)\.cabal',
            \ '\1',
            \ '')
      let l:executable_path = b:current_cabal_path .
            \ '/dist/build/' .
            \ l:binary_name  .
            \ '/' .
            \ l:binary_name
      let g:quickrun_config['haskell/cabal'] = {
            \ 'exec': [l:executable_path]
            \ }
      nmap <LEADER>r :QuickRun haskell/cabal -mode n -into 1<CR>
    endif
 endfunction
endif

" When on a Haskell File, we want QuickFix to run
" cabal if possible, if a cabal file is not present
" then we will run the file as the Main

function! s:find_cabal_directory()

  if !exists('b:cabal_file_present')
    let b:current_cabal_path = expand("%:h")

    " If current path is not an absolute path
    " then make it one
    if match(b:current_cabal_path, '^/') < 0
      let b:current_cabal_path = getcwd() . "/" . b:current_cabal_path
    endif

    let b:cabal_file_present = filereadable(b:current_cabal_path . "/*.cabal")
    while !b:cabal_file_present && !empty(b:current_cabal_path)
      let b:current_cabal_path =
            \ substitute(b:current_cabal_path, '\(.*\)/\(.\+\)$', '\1', '')
      let b:cabal_file_present =
            \ filereadable(glob(b:current_cabal_path . '/*.cabal'))
    endwhile
  endif

  if exists("b:current_cabal_path")
    " On this buffer only
    " Change the current directory where the cabal file is
    exec "lcd " . b:current_cabal_path
  endif

endfunction

function! s:decide_cabal_binary()
  let is_cabal_dev = !empty(glob(b:current_cabal_path . '/cabal-dev')) &&
        \ executable("cabal-dev")
  return is_cabal_dev ? 'cabal-dev' : 'cabal'
endfunction

function! s:setup_cabal_make()
  call s:find_cabal_directory()

  if exists('g:quickrun_config')
    call s:enable_quickrun_for_cabal()
  endif

  let cabal_binary = s:decide_cabal_binary()

  if b:cabal_file_present
    let &l:makeprg = cabal_binary . " build"
  else
    " We compile the current file as the Main module
    " if no cabal file present
    "let s:currentFile = expand('%')
    if !exists('l:qfOutputdir')
      let l:qfOutputdir = tempname()
      call mkdir(l:qfOutputdir)
    endif
    let &l:makeprg = 'ghc --make % -outputdir ' . l:qfOutputdir
  endif
  setl errorformat=
                   \%-Z\ %#,
                   \%W%f:%s:%c:\ Warning:\ %m,
                   \%E%f:%s:%c:\ %m,
                   \%E%f:%l:%c:,
                   \%E%>%f:%s:%c:,
                   \%+C\ \ %#%m,
                   \%W%>%f:%s:%c:,
                   \%+C\ \ %#%tarning:\ %m,
                   \cabal:\ %m,
                   \%-G%.%#

endfunction

au BufEnter *.hs,*.cabal call s:setup_cabal_make()

let &cpo = s:save_cpo

" vim:et:ts=2:sw=2:sts=2
