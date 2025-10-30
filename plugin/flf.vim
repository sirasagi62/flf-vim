" Use floating window for Neovim (has('nvim') is true)
" Use popup window for Vim (has('nvim') is false, Vim 8.2+)

function! FlfInFloatingTerminal()
  " Check for clientserver in Vim
  if has('vim') && !has('clientserver')
    echoerr "Error: The 'clientserver' feature is required for this functionality in Vim. Please recompile with +clientserver."
    return
  endif

  let $VIM_SERVER = v:servername

  " Check if 'flf' command is executable
  if !executable('flf')
    echoerr "Error: The required command 'flf' is not found in your system's PATH. Please install it."
    return
  endif

  " Check if 'node' command is executable (required by 'flf')
  if !executable('node')
    echoerr "Error: Executing the 'flf' command requires Node.js to be installed. The 'node' command could not be accessed."
    return
  endif

  " Calculate window size and position (approx. 80% screen size, centered)
  let w = float2nr(&columns * 0.8)
  let h = float2nr(&lines * 0.8)
  let r = float2nr((&lines - h) / 2)
  let c = float2nr((&columns - w) / 2)

  if has('nvim')
    let cmd='nvim --server $VIM_SERVER --headless --remote-send "$(FORCE_COLOR=1 flf -e nvim)"'

    " Neovim (Floating Window)
    let buf = nvim_create_buf(v:false, v:true)
    let opts = {
          \ 'relative': 'editor',
          \ 'width': w,
          \ 'height': h,
          \ 'row': r,
          \ 'col': c,
          \ 'style': 'minimal',
          \ 'border': 'rounded'
          \ }
    let win = nvim_open_win(buf, v:true, opts)
    " Execute command with termopen, close window on exit
    call termopen(a:cmd, {'on_exit': {win_id, exit_code, event -> nvim_win_close(win, v:true)}})

    " Start in terminal mode
    startinsert

  elseif has('popupwin')
    let cmd = 'vim --server $VIM_SERVER --headless --remote-send "$(FORCE_COLOR=1 flf -e vim)"'
    if has('gui-macvim')
      cmd = 'mvim --server $VIM_SERVER --headless --remote-send "$(FORCE_COLOR=1 flf -e vim)"'
    endif
    " Vim (Popup Window - Vim 8.2+)
    " Create buffer and start terminal
    let buf = term_start(a:cmd, {
          \ 'term_finish': 'close',
          \ 'curwin': 0,
          \ 'hidden': 1
          \ })

    " Open popup window
    let opts = {
          \ 'minwidth': w,
          \ 'minheight': h,
          \ 'maxwidth': w,
          \ 'maxheight': h,
          \ 'line': r + 1, " 1-based in Vimscript
          \ 'col': c + 1, " 1-based in Vimscript
          \ 'zindex': 100,
          \ 'border': ['+', '-', '+', '|', '+', '-', '+', '|'],
          \ 'padding': [0, 1, 0, 1],
          \ 'wrap': 0
          \ }
    " Create popup window and get its ID
    let win = popup_create(buf, opts)

    " Move to popup window and start in terminal mode
    call win_gotoid(win)
    startinsert

  else
    " Unsupported version
    echoerr "Error: This Vim/Neovim version does not support required terminal features (e.g., Vim < 8.2 or missing +popupwin)."
    return
  endif
endfunction

command! -nargs=1 Flf call FlfInFloatingTerminal()
