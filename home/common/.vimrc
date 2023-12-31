"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General configuration
"
execute pathogen#infect()

" Enable file type detection.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on
filetype plugin on


" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible
syntax on
set hlsearch
set incsearch
" Press Space to turn off highlighting and clear any message already displayed.
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
colo desert
set number
set tabstop=4
set shiftwidth=4
set expandtab
set ruler
inoremap jj <Esc>
inoremap jf <Esc>
inoremap <S-Tab> <C-V><Tab>

" Make backspace back up a tabstop. Especailly handy for editing Python
set smarttab

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set noshowcmd		" display incomplete commands
set incsearch		" do incremental searching
"set ignorecase          " case insensitive searching
set hidden		" allow hidden buffers
"in normal mode wrap lines and break at work boundries
set wrap
set linebreak

set showmatch           "show matching brackets
"
"Make <Tab> complete work like bash command line completion
set wildmode=longest,list

" Don't have the scratch buffer show up when there are multiple matches.
set completeopt=

" Turn on a fancy status line
set statusline=%m\ [File:\ %f]\ [Type:\ %Y]\ [ASCII:\ %03.3b]\ [Col:\ %03v]\ [Line:\ %04l\ of\ %L]
set laststatus=2 " always show the status line

"map killws to a command to remove trailing whitespace
command! Killws :% s/\s\+$//g

""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Templates: My personal templating system
"
" It works like this:
"
" Given a new file like /p1/p2/p3/p4/file.h we look in ~/.vim/templates for
" matching templates. We 1st start by walking backward up the list of dirs so
" we look for a ~/.vim/templates/p4 directory. If there is one and it contains
" a template.h file that is used. If not (either not such dir or there is a
" dir but it doesn't contain a .h template) we go up and look for p3, then p2,
" etc. Suppose we find a ~/.vim/templates/p2. We then go forwards again
" looking for a ~/.vim/templates/p2/p3/template.h, then a
" ~/.vim/templates/p2/p3/p4/template.h, etc. The longest matching path is
" used. If we can't find any matching subdirs we just look for a template.h
" file in ~/.vim/templates and use that.
"
" Template matching rules: template files are of the form template_<suffix> so
" template_.h matches files that end in '.h' while template_SConstruct matches
" files that end with 'SConstruct'.
"
" Once a template is found it is loaded and all the <+KEYWORD+> items are
" replaced as per ExpandPlaceholders() below. This is a very flexible
" mechanism that allows you to easily add new keywords and functions for
" their replacement. Keywords also can accept arguments.
"
" Finally, if the string ~~CURSOR~~ is found the cursor is moved to that
" position and the user is left in insert mode.

" Given directory dir returns the name of a template that matches fname or the
" empty string if not such template could be found.
function! FindTemplateMatch(dir, fname)
   let l:dir = a:dir
   if match(a:dir, '.*/$') == -1
      let l:dir = a:dir . '/'
   endif
   let l:templates = split(glob(l:dir . 'template_*'))
   for l:template_fname in l:templates
      let l:suf_idx = strridx(l:template_fname, 'template_')
      let l:suffix = strpart(l:template_fname, l:suf_idx + 9)
      let l:suf_idx = strridx(a:fname, l:suffix)
      if l:suf_idx >= 0
         if strpart(a:fname, l:suf_idx) == l:suffix
            return l:template_fname
         endif
      endif
   endfor
   return ''
endfunction

" Given a file whose full path is fname see if there is an appropriate
" template for it. If so return the name of that template.
function! FindTemplate(fname)
   let l:templates_dir = fnamemodify('~/.vim/templates', ':p')
   " First see if there's a template that matches any of the directories in
   " the path. If so we use this. If not we just check file extension.

   " Expand to a full path and strip off the file name so we have just the
   " directory name
   let l:fname_abs_dir = fnamemodify(a:fname, ':p:h')
   " Cur path starts out as the full path. Then we remove the ending dir one
   " dir at a time to see if we can find a matching template. For example, if
   " it starts with '/home/odain/this/long/path' we first look for a directory
   " named 'path' in the templates directory. If there isn't one we then
   " update l:cur_path to be '/home/odain/this/long' and look for a dir named
   " 'long', etc.
   let l:cur_path = l:fname_abs_dir
   let l:cur_match_template = ''
   while strlen(l:cur_path) > 1
      let l:cdir = fnamemodify(l:cur_path, ':t')
      let l:match_dir = finddir(l:cdir, l:templates_dir)
      " We found a matching dir but we're not done. We also need to see if
      " there's a matching template. There also might be a more specific
      " matching template (e.g. in a subdirectory) that we should use instead.
      if !empty(l:match_dir)
         let l:cur_match_dir = l:templates_dir . l:cdir
         let l:potential_template = FindTemplateMatch(l:cur_match_dir, a:fname)
         if !empty(l:potential_template) && filereadable(l:potential_template)
            let l:cur_match_template = l:potential_template
         endif
         " Now see if there's a more specific match. To do that we go through
         " the path from the matching dir forward looking for subdirs that
         " also match.
         let l:dir_suffix = strpart(l:fname_abs_dir, strlen(l:cur_path))
         let l:subdirs = split(l:dir_suffix, '/')
         let l:cur_subdir = l:cur_match_dir
         for l:subdir in l:subdirs
            if !empty(finddir(l:subdir, l:cur_subdir))
               let l:cur_subdir = l:cur_subdir . '/' . l:subdir
               let l:potential_template = FindTemplateMatch(l:cur_subdir, a:fname)
               if !empty(l:potential_template) && filereadable(l:potential_template)
                  let l:cur_match_template = l:potential_template
               endif
            else
               break
            endif
         endfor
         " If we've got a template now we're done
         if !empty(l:cur_match_template)
            return l:cur_match_template
         endif
      endif  
      let l:cur_path = fnamemodify(l:cur_path, ':h')
   endwhile
 
   " If we got here we didn't find a template in any of the subdirs so we just
   " look by file extension for a match.
   let l:cur_match_template = FindTemplateMatch(l:templates_dir, a:fname)
   if !empty(l:cur_match_template) && filereadable(l:cur_match_template)
      return l:cur_match_template
   else
      return ''
   endif
endfunction

" Function used to expand <+FOO+> place holders in the current buffer. Some
" place holders have a ,ARG suffix like <+FOO,ARG+> in which case ARG is used
" to help us expand FOO. Generally this is called after a macro file is read
" in.
function! ExpandPlaceholders()
   " Map from placeholders to functions that expand them
   let l:placeholders = {'VIM_FILE': function('ExpandVimFile'),
            \            'INCLUDE_GUARD': function('ExpandIncludeGuard'),
            \            'DATE': function('ExpandDate'),
            \            'PATH_TO_PACKAGE': function('PathToPackage')}
   let l:place_pattern = '<+\([^+,]\+\),\?\([^+]*\)+>'
   let l:line = search(l:place_pattern)
   while l:line > 0
      let l:line_text = getline(l:line)
      let l:place_holder = matchlist(l:line_text, l:place_pattern)
      if !has_key(l:placeholders, l:place_holder[1])
         echoerr "Unknown placeholder '" l:place_holder[1] "'"
         return
      endif
      " Find the replacement function in the dictionary
      let l:Fun = l:placeholders[l:place_holder[1]]
      " Call the function passing anyting after the "," as additional
      " arguments
      if (len(l:place_holder) > 2 && !empty(l:place_holder[2])) 
         let l:replacement = l:Fun(l:place_holder[2])
      else
         let l:replacement = l:Fun()
      endif
      " Unset l:Fun or we get errors when we call :let again. Not sure why as
      " you can usually overwrite a variable but function pointers seem to be
      " special.
      unlet l:Fun
      let l:m_start = match(l:line_text, l:place_holder[0])
      let l:m_end = matchend(l:line_text, l:place_holder[0])
      let l:line_text = strpart(l:line_text, 0, l:m_start) . l:replacement .  strpart(l:line_text, l:m_end)
      :call setline(l:line, l:line_text) 
      let l:line = search(l:place_pattern)
   endwhile
endfunction

" Given the current file path, convert this to a java package. The argument is
" the 'beginning of the package'. For example, if this is called with
" 'com.threeci' from a file at
" /home/oliver/code/com/threeci/commons/logger/file.java, this will walk up
" the path until it find conecutive directories com/threeci. It would then
" construct the package name from all the directories; in this example it
" would be com.threeci.commons.logger.
function! PathToPackage(fargs)
   let l:fname = expand('%:p:h')
   let l:dotted = substitute(l:fname, '/', '.', 'g')
   let l:package_start = match(l:dotted, a:fargs)
   return strpart(l:dotted, l:package_start)
endfunction

" Do fnamemodify on the current file name with the supplied arguments. For
" example, passing ':p' results in the full path, etc.
function! ExpandVimFile(fargs)
   return fnamemodify(expand('%'), a:fargs)
endfunction

" To be used like #ifndef <+INCLUDE_GUARD,spar+> via ExpandPlaceholders. This
" expands the INCLUDE_GUARD to be PATH_TO_FILE_H_ where the path is relative
" to the argument (in the example above it's relative to the directory spar).
function! ExpandIncludeGuard(eargs)
   let l:fname = fnamemodify(expand('%'), ':p')
   let l:end_path_pos = matchend(l:fname, '/' . a:eargs . '/')
   let l:end_path = strpart(l:fname, l:end_path_pos)
   let l:end_path = substitute(l:end_path, '/', '_', 'g')
   let l:end_path = substitute(l:end_path, '-', '_', 'g')
   let l:end_path = substitute(l:end_path, ' ', '_', 'g')
   let l:end_path = substitute(l:end_path, '\.', '_', 'g')
   return toupper(l:end_path) . '_'
endfunction

" Returns a string representing today's date. The argument is a string
" specifying how the date should be formatted in standard strftime notation.
function! ExpandDate(dargs)
  return strftime(a:dargs, localtime()) 
endfunction

function! MoveToCursor()
   " The \V makes the pattern "very non-magic" so its pretty much a literal
   " string match.
   let l:line = search('\V~~CURSOR~~')
   if l:line != 0
      " The string '~~CURSOR~~' is 10 characters long and search leaves us at the
      " beginning of the match so delete the next 10 characters and put us in
      " insert mode.
      normal 10dl
      startinsert
   endif
endfunction

function! OnNewFile()
   let l:template = FindTemplate(expand('%'))
   if !empty(l:template)
      " move the cursor to be beginning of the file
      normal gg
      " Read in the template
      execute ':r ' . l:template
      " The read command puts the file contents on the line *after*
      " the cursor position so we have a blank line at the top of the
      " file. Delete that.
      normal ggdd
      :call ExpandPlaceholders()
      " If there's a ~~CURSOR~~ marker in the file move to it and start insert
      " mode
      :call MoveToCursor()
   endif
endfunction

au! BufNewFile * :call OnNewFile()

"""""""""""""""""""""""""""" end templates



""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Language specific configs
" Note some of this is also done via ~/.vim/indent, ~/.vim/ftplugin, etc.
"
""""
" C++
" Add ability to switch from .h to .cc quickly
command! Toh :e %:r.h
command! Toc :e %:r.cc
autocmd FileType c,cpp setlocal et ts=4 sw=4 tw=120 
