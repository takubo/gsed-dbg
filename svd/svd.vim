"colorscheme slate2
"?colorscheme slate
"?set guifont=MeiryoKe_Console:h9.5:cSHIFTJIS
set nocursorline
"hi CursorLine guibg=bg gui=NONE ctermbg=bg cterm=NONE
au WinEnter * set nocursorline

"残件
"AvdComで、1行の長さが1024を超えるとフリーズする?
"Dumpがフリーズする
"BPのcanいらない
"SynErrの行でF5押すと、左端の〇が出たり消えたり
"
"Breakまわり
"		重複したとき
"		設定できなかったときの、HiLight切り替え
"
"		Runに引数与える
"	Input実装
"
"	CurrentのBPをDelしたとき
"	SynErrにブレークを置こうとしたとき
"
"		out.tmp
"
"	mappingをバッファローカルにする
"	out.tmpないからでも実行可能にする
"	out.tmpのステータスライン
"	autcomd、バッファの再読み込み
"
"	最初のfinishを復活させる
"
"	up, down でout.tmp がノンアクティブのときの処理
"	スタック関数移動したときの正規表現でスペースが入っていたらマッチしない問題
"		AvdCmd#StackSub(cmd, count)
"		Svd#WaitSub(cmd, count)も？
"	スタック：ファイル名に)が使われていた時の対応ｗ	
"
"
"	Recvのタイムアウトを引数化ｗ
"	ハイライト
"

if exists("b:svd") || &filetype != 'sed'
    "finish
endif
let b:svd = 1


let g:true = 1
let g:false = 0

let g:DUM_ID = 1
let g:CUR_ID = 2

let g:ESC_KEY_CODE = 27

let g:MSGLEN = 64

"initialize
if ! exists('g:run_time')
    let g:run_time = 0
endif
"""" if ! exists('g:auto_print')
""""     let g:auto_print = 0
"""" endif
"""" 
"""" 
"""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""" 
"""" function! Svd#AutoPrint()
""""     let g:auto_print = !g:auto_print
""""     if g:auto_print
"""" 	call Svd#AutoPrintOn()
"""" 	echo 'Auto-Print: ON'
""""     else
"""" 	call Svd#AutoPrintOff()
"""" 	echo 'Auto-Print: OFF'
"""" 	"echo 'Turn off Auto-Print.'
""""     endif
"""" endfunc
"""" function! Svd#AutoPrintOn()
""""     if g:auto_print && g:run_time
"""" 	silent set updatetime=1
"""" 	silent setlocal isk+=\$
"""" 	silent autocmd CursorHold <buffer> :call Svd#AutoPrintExe(expand("<cword>"))
""""     endif
"""" endfunc
"""" function! Svd#AutoPrintOff()
""""     silent autocmd! CursorHold
""""     silent setlocal isk-=\$
"""" endfunc
"""" function! Svd#AutoPrintExe(arg)
""""     "if a:arg =~ '\(\a\w*\)\|\(\$\d\+\)'
""""     "ToDo 例外でOffにする
""""     if a:arg =~# '^\h\|^\$\d\+'
"""" 	call AvdCmd#Send('print ' . a:arg)
"""" 	if Recv(1) > 0 && g:Msg =~ '\w\+ = '
"""" 	    echo g:Msg
"""" 	endif
""""     endif
"""" endfunc
"""" 
"""" 
"""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! Svd#Continue()
    "Continue
    if g:run_time != 3
	return
    endif
    let g:run_time = 2
    call AvdCmd#CmdContinue("")
    let s:mode_n = g:false
    call Svd#RunWait()
endfunc

function! Svd#Next()
    "Next
    if g:run_time != 3
	return
    endif
    let g:run_time = 2
    call AvdCmd#CmdNext("")
    let s:mode_n = g:true
    call Svd#RunWait()
endfunc

function! Svd#Step()
    "Step
    if g:run_time != 3
	return
    endif
    let g:run_time = 2
    call AvdCmd#CmdStep("")
    let s:mode_n = g:true
    call Svd#RunWait()
endfunc


function! Svd#Start(arg)
    "前回の完了メッセージを消す
    normal :<esc>

"    if &filetype !=? 'awk' && !exists('g:src_file')
"	echo 'This file is not awk script.'
"	return
"    endif

    "if &filetype ==? 'awk'
    if exists('b:svd')
	let g:src_file = expand("%:p")
	let g:src_file_tail = expand("%:t")
    elseif !exists('g:out_tmp') || expand('%:p') != g:out_tmp
	echo 'This file is not sed script.'
	return
    endif
    let g:src_win = bufwinnr(g:src_file)

    if g:run_time != 0
    " 前回がキチンと終わってなかったら
	if g:run_time != 3
	    let k = 'y'
	else
	    echo "Program already running. Do you restart anyway(y/n)? "
	    let k = nr2char(getchar())
	    normal ::<esc>
	endif
	if k == 'y'
	    exe "sign unplace " . g:CUR_ID . " file=" . g:src_file
	    if g:run_time == 4
		call Svd#Finish()
	    else
		call AvdCom#Close()
	    endif
	    if g:run_time != 3
		call Svd#Kill()
	    endif
	else
	    return
	endif
	"!! silent edit!	"「ファイルは最後に読み込んだ後に変更されました」の警告を避けるため。念のため。
    endif

    if a:arg == ''
	let in_file = 'nul'
    else
	let in_file = a:arg
    endif
    "let in_file = 'LTL30005.apl'

"""     if has('win32')
""" 	let gawk    = ' C:\MinGW\msys\1.0\bin\gawk -f '
""" 	if 1
""" 	    let dgawk   = ' D:\takubo\bin\dgawk -f '
""" 	else
""" 	    let dgawk   = ' C:\\gawk32\\dgawk -f '
""" 	endif
""" 	let avd_in  = ' "' . $vim . '/avd/avd_in.awk'  . '" '
""" 	let avd_out = ' "' . $vim . '/avd/avd_out.awk' . '" '
""" 	exec 'silent !start /min cmd /min /c ' . gawk . avd_in . ' | ' . dgawk . ' "' . g:src_file . '" ' . ' 2>&1 "' . in_file .  '" | ' . gawk . avd_out
"""     else
""" 	let gawk    = ' gawk -f '
""" 	let dgawk   = ' dgawk -f '
""" 	let avd_in  = ' "' . $vim . '/avd/avd_in.awk'  . '" '
""" 	let avd_out = ' "' . $vim . '/avd/avd_out.awk' . '" '
""" 	exec 'silent !( ' . gawk . avd_in . ' | ' . dgawk . ' "' . g:src_file . '" ' . ' 2>&1 "' . in_file .  '" | ' . gawk . avd_out . ' )'
"""     endif

    let g:run_time = 1

    let b:old_scrolloff = &scrolloff
    set scrolloff=3
    let b:old_list = &list
    set nolist

    if !exists('g:out_tmp')
	let g:out_tmp = tempname()
    endif

    call AvdCom#Open()

    if bufexists(g:out_tmp) == 0 || bufwinnr(g:out_tmp) == -1
	"ソースファイルウィンドウの下30%を出力表示領域として分割する
	"let src_cwd = getcwd()	"ソースのCWD
	exe "silent belowright " . float2nr((winheight(0) * 0.20)) . " split " . g:out_tmp
	set ft=
	"setlocal noautochdir
	"exe 'lcd ' . src_cwd	 | "ソースのCWDに移動
	silent %d _ "全画面消去
	silent write!
	"src_fileへ移動
	silent exe g:src_win . "wincmd w"
	"? silent redraw
    endif
    let g:out_tmp_win = bufwinnr(g:out_tmp)

    "ToDo
    exe "sign unplace " . g:CUR_ID . " file=" . g:src_file

"""     "文法(Syntax error) チェック
"""     if Svd#SyntaxErr()
""" 	call Svd#Finish()
""" 	let &scrolloff = b:old_scrolloff
""" 	let &list = b:old_list
""" 	let g:run_time = 0
""" 	return
"""     end

    "ここで、out.tmpをセット
"""     call Send('option outfile="' . substitute(g:out_tmp, '\\', '\\\\', 'g') . '"')
    "?? call Send('option outfile = "/dev/stderr"')

    "ここで、既定のブレークポイントをセット
    let g:set_bp_num = 0
    call AvdBp#StartBreak()

    "ランニング
    call AvdCmd#CmdRun()
    let g:run_time = 2
    let s:mode_n = g:false
    let g:now_fnc = 'main()'
    call Svd#RunWait()
endfunc

function! Svd#RunWait()
    "out_tmpへ移動
    silent exe g:out_tmp_win . "wincmd w"
    "? silent set readonly
    silent setlocal autoread

"""     exe 'setlocal statusline=[avd.out]\ Running...\ \ @' . g:now_fnc . '\ \ ->\ #0:' . g:now_fnc
    exe 'setlocal statusline=[svd\ info]'

    silent exe "sign unplace " . g:CUR_ID . " file=" . g:src_file
    let iretc = Svd#RunWaitSub()

    if iretc <= 0
	call Svd#Finish()
	if iretc < 0
	    call Svd#Kill()
	endif
	let g:run_time = 0
    endif
    if iretc == 1
	let g:run_time = 3
""" 	call Svd#AutoPrintOn()
    elseif iretc == 2
	let g:run_time = 4
""" 	call Svd#AutoPrintOn()
    else
	silent edit!
	call cursor('$', col('.'))
	"src_fileへ移動
	silent exe g:src_win . "wincmd w"
	"let &scrolloff = b:old_scrolloff
	let &list = b:old_list
""" 	call Svd#AutoPrintOff()
    endif
    silent redraw
endfunc

function! Svd#RunWaitSub()
    let s:mode_b = g:false
    let s:mode_f = g:false
    let s:no_inp = g:false
    let s:input  = g:false

    let key = 0
    while (1)
	"ESC で強制終了
	"iで一度だけ、標準入力から入力
	"Iで標準入力モド(空文字列が入力された時点で終了)
""" 	if nr2char(key) !=# 'I'
""" 	    let key = getchar(0)
""" 	endif
	if key == g:ESC_KEY_CODE
	    return -9
""" 	elseif (nr2char(key) ==# 'i' || nr2char(key) ==# 'I') && !s:no_inp
""" "	    let in = input('Input: ')
""" "	    if in == ''
""" "		let key = 0
""" "	    endif
""" "	    call Send(in)
""" 	    let s:input = g:true
""" 	endif
""" 	if nr2char(key) !=# 'I'
""" 	    let key = 0
	endif

	let rcv = Recv(0.2)

	if rcv > 0
	    "? if (s:mode_b || s:mode_n) && (g:Msg =~# "^\\d\\+")
	    if g:Msg =~# "^@stop by "
		silent edit! |  "out.tmpのバッファ
		call cursor('$', col('.'))
		"""""""""" let mats = matchlist(g:Msg, '^\(\d\+\) ')
		"""""""""" let g:now_line = mats[1]
		"""""""""" exe 'setlocal statusline=[avd.out]\ \ ' . g:now_line . '\ \ @' . g:now_fnc . '\ \ ->\ #0:' . g:now_fnc

		"src_fileへ移動
		silent exe g:src_win . "wincmd w"
		let line_tmp = matchstr(g:Msg, "line = \\d\\+")
		let line = substitute(line_tmp, "\\D", "", "g")

		if g:Msg =~# "^@stop by break"
		    silent exe "sign place " . g:CUR_ID . " line=" . line . " name=CurBpNrml file=" . g:src_file
		else
		    silent exe "sign place " . g:CUR_ID . " line=" . line . " name=Current file=" . g:src_file
		endif
		call cursor(line, col('.'))


call Svd#DispInfo()

		"call cursor(line, max([vertcol([line, indent(line)+1]), col('.')]))
		if g:Msg =~# "^@stop by break"
		    echo "Stopping at breakpoint."
		endif

		return 1
""" 	    else
""" 		let s:mode_b = g:false
	    endif

""" 	    if s:mode_f && g:Msg =~# "^Program exited abnormally"
""" 		"ランタイムエラー
""" 		echo g:Msg
""" 		"src_fileへ移動
""" 		silent exe g:src_win . "wincmd w"
""" 		call cursor(mat[2], col('.'))
""" 		exe "silent sign place " . g:CUR_ID . " line=" . mat[2] . " name=RuntimeErr file=" . g:src_file
""" 		silent redraw
""" 		return 2
""" 	    else
""" 		let s:mode_f = g:false
""" 	    endif

	    "? if g:Msg =~# "^Program exited normally"
	    if g:Msg =~# "^@program finished"
		"実行終了
""" 		setlocal statusline=[avd.out]
		echo g:Msg
call Svd#DispInfo()
		return 0
""" 	    elseif g:Msg =~# "^Breakpoint "
""" 		"途中停止
""" 		let s:mode_b = g:true
""" 		let matb = matchlist(g:Msg, '^Breakpoint \d\+, \(\w\+(.*)\)')
""" 		let g:now_fnc = matb[1]
""" 		let g:now_fnc = substitute(g:now_fnc, ' ', '\\ ', "g")
""" 	    elseif g:Msg =~# "^gawk: "
""" 		"ランタイムエラー
""" 		"ファタルの1行目を表示した後に読み込みを行うと、最初のメッセージが消えてしまうため。
""" 		silent edit! |  "out.tmpのバッファ
""" 		call cursor('$', col('.'))
""" 		silent redraw	 | "out.tmp 読み込み専用を抑止する
""" 		setlocal statusline=[avd.out]\ Runtime\ error  |  "redrawの後
""" 		let mat = matchlist(g:Msg, ':\(\(\d\+\): fatal: .\+\)')
""" 		"echo strpart(g:Msg, 6)  | "メッセージが2行にわたるときに画面が乱れる
""" 		echo g:src_file_tail . ': ' . mat[1]
""" 		let s:mode_f = g:true
""" 	    elseif g:Msg == "Stopping in Rule ..."
""" 		let s:no_inp = g:true
""" 	    elseif g:Msg =~# '^\h\w*(.*) at `'
""" 		"関数(フレーム)変更
""" 		let matf = matchlist(g:Msg, '^\(\w*(.*)\) at `')
""" 		let g:now_fnc = matf[1]
""" 		let g:now_fnc = substitute(g:now_fnc, ' ', '\\ ', "g")
""" 		exe 'setlocal statusline=[avd.out]\ Running...\ \ @' . g:now_fnc . '\ \ ->\ #0:' . g:now_fnc
	    endif
	elseif !s:mode_f
	    "ファタルの1行目を表示した後に読み込みを行うと、最初のメッセージが消えてしまうため。
	    "fatalが起きたのなら、どうせもう追加の出力はない
	    silent edit!
	    call cursor('$', col('.'))
	    silent redraw

""" 	    if s:input
""" 		let s:input = g:false
""" 		let in = input('Input: ')
""" 		if in == ''
""" 		    let key = 0
""" 		endif
""" 		call Send(in)
""" 	    endif
	endif
    endwhile
endfunc

function! Svd#Finish()
    call AvdCmd#CmdQuit()

    if !has('win32') && !has('win64')
	while(Recv(1) == 1)
	endwhile
    endif

    call AvdCom#Close()
endfunc

function! Svd#Kill()
    if has('win32')
	call system("taskkill /F /IM sed.exe /IM gsed.exe")
    else
	call system("kill /F /IM sed.exe /IM gsed.exe")
    endif
endfunc

function! Svd#DispInfo()
    "out_tmpへ移動
    silent exe g:out_tmp_win . "wincmd w"
    "silent %d _ "全画面消去

    call AvdCmd#CmdPrint("")
    "call AvdCmd#CmdPrint("PTRN")
    call Svd#DispInfoSub(1)
    "call AvdCmd#CmdPrint("HOLD")
    call Svd#DispInfoSub(2)
    "call AvdCmd#CmdPrint("FLAG")
    call Svd#DispInfoSub(3)

    "exe 'setlocal statusline=[svd\ info]'

    "src_fileへ移動
    silent exe g:src_win . "wincmd w"
endfunc
function! Svd#DispInfoSub(line)
    while (Recv(0.1) == 1)
	call setline(a:line, g:Msg)
	return
    endif
endfunc

""" function! Svd#SyntaxErr()
"""     let syn_err = 0
"""     while (1)
""" 	let rcv = Recv(1)
""" 	if rcv > 0 && g:Msg =~# '^gawk: '
""" 	    if syn_err == 0
""" 		"out_tmpへ移動
""" 		silent exe g:out_tmp_win . "wincmd w"
""" 		setlocal statusline=[avd.out]\ Syntax\ error
""" 		silent edit!
""" 		silent %d _ "全画面消去
""" 		silent write!
""" 	    endif
""" 	    let mat = matchlist(g:Msg, '\(:\(\d\+\): .\+\)')
""" 	    let syn_err += 1
""" 	    "call setline(syn_err, strpart(g:Msg, 6))
""" 	    call setline(syn_err, g:src_file_tail . mat[1])
""" 	endif
""" 	if rcv <= 0 || syn_err >= 2
""" 	    if syn_err
""" 		silent write!
""" 		set readonly
""" 		"src_fileへ移動
""" 		silent exe g:src_win . "wincmd w"
""" 		call cursor(mat[2], col('.'))
""" 		exe "sign place " . g:CUR_ID . " line=" . mat[2] . " name=SyntaxErr file=" . g:src_file
""" 		silent redraw
""" 	    endif
""" 	    return syn_err
""" 	endif
"""     endwhile
""" endfunc

function! Svd#RuntimeErrFinish()
    if g:run_time != 4
	return
    endif
    "メッセージラインにRuntime Erorrの情報がのこっているかもしれないので、それを消す
    normal ::<esc>

    call Svd#Finish()
    exe "sign unplace " . g:CUR_ID . " file=" . g:src_file

    if bufwinnr(g:out_tmp) != -1
	"out_tmpへ移動
	silent exe g:out_tmp_win . "wincmd w"
""" 	setlocal statusline=[avd.out]
	"src_fileへ移動
	exe g:src_win . "wincmd w"
    elseif bufexists(g:out_tmp) != 0
	silent exe "tabnew " g:out_tmp
""" 	setlocal statusline=[avd.out]
	silent exe "quit"
    endif

    let g:run_time = 0
endfunc


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <silent> <F5>		<esc>:call AvdBp#BreakPoint()<CR>

nnoremap <silent> <F8>		<esc>:call Svd#Continue()<CR>
nnoremap <silent> <F7>		<esc>:call Svd#Next()<CR>
nnoremap <silent> <F6>		<esc>:call Svd#Step()<CR>

command! -nargs=* -complete=file AvdRun :call Svd#Start(<q-args>)

nnoremap <silent> <C-g>r	<esc>:AvdRun<CR>
nnoremap          <C-g>R	<esc>:AvdRun 
nnoremap          <C-g>z	<esc>:AvdRun /dev/stdin<CR>

nnoremap          <C-g>p	<esc>:AvdPrint 
nnoremap <silent> <C-g>v	<esc>:AvdPrint <C-r><C-w><CR>
nnoremap <silent> <C-g>@	<esc>:AvdPrint @<C-r><C-w><CR>
nnoremap <silent> <C-g>a	<esc>:call Svd#AutoPrint()<CR>
nnoremap          <C-g>s	<esc>:AvdSet 
nnoremap          <C-g>S	<esc>:AvdSet <C-r><C-w> = 
nnoremap          <C-g>e	<esc>:AvdEval 

nnoremap <silent> <C-g>t	<esc>:AvdBt<CR>
nnoremap <silent> <C-g>j	<esc>:AvdDown<CR>
nnoremap <silent> <C-g>k	<esc>:AvdUp<CR>
nnoremap <silent> <C-g>F	<esc>:AvdFrame<CR>
nnoremap          <C-g>f	<esc>:AvdFrame 

nnoremap          <C-g>i	<esc>:AvdInfo 

nnoremap <silent> <C-g>q	<esc>:call Svd#RuntimeErrFinish()<CR>

nnoremap <silent> <bs>r		<esc>:AvdRun<CR>
nnoremap          <bs>R		<esc>:AvdRun 
nnoremap          <bs>z		<esc>:AvdRun /dev/stdin<CR>

nnoremap          <bs>p		<esc>:AvdPrint 
nnoremap <silent> <bs>v		<esc>:AvdPrint <C-r><C-w><CR>
nnoremap <silent> <bs>@		<esc>:AvdPrint @<C-r><C-w><CR>
nnoremap <silent> <bs>a		<esc>:call Svd#AutoPrint()<CR>
nnoremap          <bs>s		<esc>:AvdSet 
nnoremap          <bs>S		<esc>:AvdSet <C-r><C-w> = 
nnoremap          <bs>e		<esc>:AvdEval 

nnoremap <silent> <bs>t	<esc>:AvdBt<CR>
nnoremap <silent> <bs>j	<esc>:AvdDown<CR>
nnoremap <silent> <bs>k	<esc>:AvdUp<CR>
nnoremap <silent> <bs>F	<esc>:AvdFrame<CR>
nnoremap          <bs>f	<esc>:AvdFrame 

nnoremap          <bs>i	<esc>:AvdInfo 

nnoremap <silent> <bs>q	<esc>:call Svd#RuntimeErrFinish()<CR>

nnoremap <silent> <c-g>c	:exe 'sign unplace ' . g:CUR_ID <cr>
nnoremap <silent> <bs>c		:exe 'sign unplace ' . g:CUR_ID <cr>

so $HOME/gsed_dbg/svd/AvdBp.vim
so $HOME/gsed_dbg/svd/AvdCmd.vim
so $HOME/gsed_dbg/svd/AvdCom.vim
so $HOME/gsed_dbg/svd/AvdHi.vim

"set scrolloff=3

set timeoutlen=15000
if &filetype == 'sed'
    exe "sign place " . g:DUM_ID . " line=1 name=AvdDummy file=" . expand('%:p')
end

""" if g:run_time == 0
"""     call Svd#Kill()
""" endif

finish

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" 
""" 
""" func! Test()
""" 
""" exec "!start cmd /min /c C:\MinGW\msys\1.0\bin\gawk -f avd_in.awk | D:\takubo\bin\dgawk -f" expand("%:p") "| C:\MinGW\msys\1.0\bin\gawk -f avd_out.awk"
""" 
""" endfunc
""" 
""" 
""" enew
""" read! echo 54
""" let l = getline(".")
""" undo
""" echo "^".bufname("%")
""" "bdel
""" echo l
""" sleep 5
""" 
""" 
""" "function! Svd#Run()
""" "    "ランニング
""" "    call AvdCmd#CmdRun()
""" "    let iretc = Svd#RunWait()
""" "    echo iretc
""" "    return iretc
""" "    "return Svd#RunWait()
""" "endfunc
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" "未確定
""" "確定済
""" "
""" "未確定無効
""" "未確定有効
""" "確定無効
""" "確定有効
""" "停止有効
""" "停止後無効
""" "
""" 
""" 
""" 
""" "条件付き		この4通りを1文字で
""" "条件なし
""" "通過付き
""" "通過なし
""" "
""" "有効
""" "無効
""" "
""" "停止
""" "
""" "
""" "無効
""" "有効
""" "停止有効
""" "停止後無効
""" "
""" " | 
""" " -
""" " +
""" " `
""" " '
""" " "
""" 
""" 
""" 
""" "ブレーク置く
""" "ブレーク消す
""" "ブレーク無効化、ブレーク有効化
""" "ブレーク無視設定
""" "ブレーク無視変更
""" "ブレーク無視消去
""" "ブレーク条件設定
""" "ブレーク条件変更
""" "ブレーク条件消去
""" "
""" "次のブレークへジャンプ
""" "前のブレークへジャンプ
""" "最初のブレークへジャンプ
""" "最後のブレークへジャンプ
""" "ブレーク一覧
""" "
""" "ステップオーバー
""" "ステップイン
""" "ステップアウト
""" "コンティニュー
""" "ラン
""" "ストップ
""" "強制ストップ
""" "
""" "変数確認
""" "式実行
""" "
""" 
""" 
""" 
""" 
""" 
""" 
""" "
""" "
""" "
""" "名前付きブレーク
""" "名前付きブレークへジャンプ
""" "
""" 
""" 
""" 
""" 
""" "func! R()
""" "    "perl VIM::DoCommand("let l:r = 23")
""" "    echo l:r
""" "    sleep 3
""" "endfunc
""" "call R()
""" 
""" 
""" function! s:CmdSetBreakNew()
"""     let line = getline(".")
""" "   if has('perl')
""" "	perl << EOF
""" "	    $cmd = sprintf "echo break %d | dgawk -f %f", $row, $file
""" "	    $ret = `$cmd`
""" "	    VIM::DoCommand("let ret = " . $ret)
""" "	EOF
""" "   else
""" 	if line =~ '^\(\s\|{\|}\)*\(#.*\)\?$'
""" 	    echo "Can't set break point at this line."
""" 	endif
""" "   endif
"""     let b:break_num += 1
""" endfunction
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" 
""" func! Muri()
"""     let row = line(".")
"""     let file = expand("%:p")
"""     let cmd = printf('echo break %d | dgawk -f %s', row, file)
"""     "let ls = s:GetVimCmdOutput('echo system("' . cmd .'")')
"""     let ls = s:GetVimCmdOutput('sign place file=' . expand("%:p"))
"""     echo ls
"""     sleep 3
""" endfunc
""" 
""" 
""" function! Svd#Echo(msg)
"""     echo a:msg
""" endfunc
""" 
""" function! Svd#SyntaxErr_0()
"""     return 0
"""     let syn_err = 0
"""     while (1)
""" 	let rcv = Recv(1)
""" 	"let g:Msg = substitute(g:Msg, '\n', '\n', 'g')
""" 	if rcv > 0 && g:Msg =~# '^gawk: '
""" 	    if syn_err == 0
""" 		silent %d _ "全画面消去
""" 	    endif
""" 	    let mat = matchlist(g:Msg, ':\(\d\+\):')
""" 	    "if len(mat) >= 1
""" 		let line = mat[1]
""" 	    "endif
""" 	    let syn_err += 1
""" 	    call setline(syn_err, g:Msg)
""" 	endif
""" 	if rcv <= 0 || syn_err >= 2
""" 	    if syn_err
""" 		silent write!
""" 		set readonly
""" 		"src_fileへ移動
""" 		exe g:src_win . "wincmd w"
""" 		call cursor(mat[1], col('.'))
""" 		exe "sign place " . g:CUR_ID . " line=" . mat[1] . " name=SyntaxErr file=" . g:src_file
""" 		redraw
""" 	    endif
""" 	    return syn_err
""" 	endif
"""     endwhile
""" endfunc
""" 
""" 
""" let ls = s:GetVimCmdOutput("sign place file=".expand("%:p"))
""" echo ls
""" sleep 3
""" 
""" 
""" function! Svd#SyntaxErr_0(syn_err)
"""     let line = split(a:syn_err, '\n')
""" 
"""     "out_tmpへ移動
"""     silent exe g:out_tmp_win . "wincmd w"
"""     silent %d _ "全画面消去
"""     call setline(1, line[0])
"""     call setline(2, line[1])
"""     silent write!
"""     set readonly
""" 
"""     "src_fileへ移動
"""     exe g:src_win . "wincmd w"
"""     let mat = matchlist(line[0], ':\(\d\+\):')
"""     exe "sign place " . g:CUR_ID . " line=" . mat[1] . " name=SyntaxErr file=" . g:src_file
"""     call cursor(mat[1], col('.'))
"""     silent redraw
""" 
"""     return
""" endfunc
""" 
""" 
""" 
""" 
""" 
""" let id = 1
""" let line = line(".")
""" "
""" "
""" "
""" "
"""     "out_tmpへ移動
"""     "exe g:out_tmp_win . "wincmd w"
"""     "set nonumber
"""     "silent %d _ "全画面消去
"""     "if 0
""" 	"normal G
""" 	"call setline(line(".")+1, repeat("-", winwidth(0)))
""" 	"silent write! %
"""     "endif
"""     "silent edit!	"「ファイルは最後に読み込んだ後に変更されました」の警告を避けるため。念のため。
"""     "silent setlocal autoread
"""     "silent redraw
""" 
"""     "while (1)
"""     "    let rcv = Recv()
"""     "    if rcv > 0
""" "   "        if g:Msg =~# "^Breakpoint"
""" "   "    	let g:set_bp_num += 1
""" "   "        elseif g:Msg =~# "^Can't set breakpoint at"
""" "   "    	echo g:Msg
""" "   "        endif
"""     "    else
"""     "        return
"""     "    endif
"""     "endwhile
