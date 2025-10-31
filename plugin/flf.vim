" ======================================================================
" Helper Functions (Exit Handlers and SaveBuffersAsJsonList are unchanged)
" ======================================================================

" Neovim exit handler: Closes floating window and calls callback.
function! s:FlfTerminalExitHandlerNvim(win_id, callback_name, json_path)
  call nvim_win_close(a:win_id, v:true)

  if !empty(a:callback_name) && exists('*' . a:callback_name)
    call call(a:callback_name, [a:json_path])
  endif
endfunction

let s:state = {'bufn':v:null, 'line':v:null}

" Vim exit handler: Closes popup and calls callback.
function! s:FlfTerminalExitHandlerVim(win_id, callback_name, json_path)
  call popup_close(a:win_id)

  if !empty(a:callback_name) && exists('*' . a:callback_name)
    call call(a:callback_name,[a:json_path])
  endif
endfunction


" Callback function to delete the temporary JSON file.
function! JumpLineAndDeleteFile(file_path)
  execute 'buffer' '+' . s:state["line"] s:state["bufn"]
  if filereadable(a:file_path)
    call delete(a:file_path)
  endif
endfunction


" Saves all listed buffers' content to a JSON file.
function! SaveBuffersAsJsonList(json_path)
  let l:json_data = []
  let l:unique_contents = {}

  for l:buf in getbufinfo({'buflisted': 1})
    let l:filename = bufname(l:buf.bufnr)
    if empty(l:filename)
      continue
    endif

    let l:content_list = getbufline(l:buf.bufnr, 1, '$')
    let l:content = join(l:content_list, "\n")

    if has_key(l:unique_contents, l:content)
      continue
    endif

    let l:entry = {'buffername': l:filename, 'content': l:content}
    call add(l:json_data, l:entry)
    let l:unique_contents[l:content] = 1
  endfor

  let l:json_string = json_encode(l:json_data)
  call writefile([l:json_string], a:json_path, 'b')
endfunction


" ファイルパスを引数に取り、バッファが存在すれば移動、なければ新しいtabを開くコマンド
function! FlfJumpToBufWithLine(file,line)
    " ファイルパスからバッファ番号を取得
    let bufn = bufnr(a:file)

    " バッファ番号が有効（存在）な場合
    if bufn > 0
        " 既存のバッファに移動
        "execute 'buffer' '+' . bufn
        let s:state["bufn"] = bufn
        let s:state["line"] = a:line

    else
        " maybe unreach!!!
        " 新しいバッファを開く
        execute 'tabnew' '+' . a:line a:file
    endif
endfunction

" ======================================================================
" Main Floating Terminal Function (FlfInFloatingTerminal)
" ======================================================================

" Runs flf command in a floating/popup terminal window.
" a:cmd_suffix: The entire terminal command string following the editor name (e.g., ' --server $VIM_SERVER ...')
function! FlfInFloatingTerminal(cmd_suffix, on_exit_callback, callback_arg_json_path)
  if has('vim') && !has('clientserver')
    echoerr "Error: '+clientserver' feature required for Vim."
    return
  endif
  let $VIM_SERVER = v:servername

  if !executable('flf')
    echoerr "Error: 'flf' command not found."
    return
  endif

  if !executable('node')
    echoerr "Error: 'node' command not found (required by flf)."
    return
  endif

  let w = float2nr(&columns * 0.8)
  let h = float2nr(&lines * 0.8)
  let r = float2nr((&lines - h) / 2)
  let c = float2nr((&columns - w) / 2)

  " Determine the editor command name
  if has('nvim')
    let l:editor_cmd = 'nvim'
  elseif has('gui-macvim')
    let l:editor_cmd = 'mvim'
  else
    let l:editor_cmd = 'vim'
  endif

  " Construct the full terminal command: EDITOR_CMD + a:cmd_suffix
  let cmd = l:editor_cmd . a:cmd_suffix

if has('nvim')
  let buf = nvim_create_buf(v:false, v:true)
  let opts = {
        \ 'relative': 'editor', 'width': w, 'height': h,
        \ 'row': r, 'col': c, 'style': 'minimal', 'border': 'rounded'
        \ }
  let win = nvim_open_win(buf, v:true, opts)

  call termopen(cmd, {
        \ 'on_exit': {job_id, code, event ->
        \   s:FlfTerminalExitHandlerNvim(win, a:on_exit_callback, a:callback_arg_json_path)
        \ }
        \ })
  startinsert

elseif has('popupwin')
  let buf = term_start(cmd, {'curwin': 0, 'hidden': 1})
  let opts = {
        \ 'minwidth': w, 'minheight': h, 'maxwidth': w, 'maxheight': h,
        \ 'line': r + 1, 'col': c + 1, 'zindex': 100,
        \ 'border': ['+', '-', '+', '|', '+', '-', '+', '|'],
        \ 'padding': [0, 1, 0, 1], 'wrap': 0
        \ }

  let win = popup_create(buf, opts)
  let job_id = term_getjob(buf)

  call job_setoptions(job_id, {
        \ 'exit_cb': {job, status ->
        \   s:FlfTerminalExitHandlerVim(win, a:on_exit_callback, a:callback_arg_json_path)
        \ }
        \ })

  call win_gotoid(win)
  startinsert

  else
    echoerr "Error: Unsupported Vim/Neovim version."
    return
  endif
endfunction

" ======================================================================
" Command Wrappers
" ======================================================================

" Wrapper to save buffers, open flf, and ensure cleanup on exit.
function! SaveBuffersAndOpenFlf()
  " 1. Generate temp filename
  let l:rand_string = printf('%x', reltime()[1])
  let l:json_path = printf('/tmp/flf-vim-%s.json', l:rand_string)

  " 2. Save buffers
  call SaveBuffersAsJsonList(l:json_path)

  " 3. Flf terminal command suffix
  " Example: --server $VIM_SERVER --headless --remote-send "$(flf buf -e vim -p /tmp/file.json)"
  let l:flf_cmd_body = printf(' --server $VIM_SERVER --headless --remote-send "$(flf buf -e vim -p %s)"', l:json_path)

  " 4. Run flf with cleanup callback and the JSON path as its argument
  "call FlfInFloatingTerminal(l:flf_cmd_body, 's:DeleteTempFileCallback', l:json_path)
  call FlfInFloatingTerminal(l:flf_cmd_body, 'JumpLineAndDeleteFile', l:json_path)
endfunction


" Command Definitions
" FlfDir: Run flf for directories.
let s:flf_dir_cmd_body = ' --server $VIM_SERVER --headless --remote-send "$(flf dir -e vim)"'
command! FlfDir call FlfInFloatingTerminal(s:flf_dir_cmd_body, '', '')

" FlfBuf: Save buffers, run flf, and clean up the temp file.
command! FlfBuf call SaveBuffersAndOpenFlf()
