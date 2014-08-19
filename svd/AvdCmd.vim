function! AvdCmd#Send(cmd)
    call Send(a:cmd)
endfunc


""" ***** Control Of Breakpoints

" break [[filename:]N|function] - set breakpoint at the specified location.
function! AvdCmd#CmdBreak(arg, id)
    "call AvdCmd#Send('break ' . a:arg)
    call AvdCmd#Send('b ' . a:arg)
    while (1)
	let rcv = Recv(1)
	if rcv > 0
	    "if g:Msg =~# "^Breakpoint "
	    if g:Msg =~# "^break set"
		let g:set_bp_num += 1
		if a:arg != matchstr(g:Msg, '\d\+$')
		    call AvdCmd#CmdDelete(g:set_bp_num)
		    let b:BP[a:id]['hi'] = 'BpInvNrml'
		    let b:BP[a:id]['can'] = g:false
		    exe "sign place " . a:id . " line=" . b:BP[a:id]['line'] . " name=BpInvNrml file=" . g:src_file
		    return
		else
		    let b:BP[a:id]['num'] = g:set_bp_num
		endif
		if b:BP[a:id]['hi'] == 'BpInvNrml'
		    let b:BP[a:id]['hi'] = 'BpNrml'
		    exe "sign place " . a:id . " line=" . b:BP[a:id]['line'] . " name=BpNrml file=" . g:src_file
		endif
""" 	    elseif g:Msg =~# "^Can't set breakpoint at"
""" 		let b:BP[a:id]['hi'] = 'BpInvNrml'
""" 		let b:BP[a:id]['can'] = g:false
""" 		exe "sign place " . a:id . " line=" . b:BP[a:id]['line'] . " name=BpInvNrml file=" . g:src_file
""" 	    elseif g:Msg =~# "^Note: breakpoint "
""" 		let g:set_bp_num += 1
""" 		call AvdCmd#CmdDelete(g:set_bp_num)
""" 		let b:BP[a:id]['hi'] = 'BpInvNrml'
""" 		let b:BP[a:id]['can'] = g:false
""" 		exe "sign place " . a:id . " line=" . b:BP[a:id]['line'] . " name=BpInvNrml file=" . g:src_file
""" 	    endif
""" 	    if g:Msg !~# "^Can't find rule!!!"
""" 		return
	    endif
	else
	    return
	endif
    endwhile
    "cal getchar()
endfunc

" delete [breakpoints] [range] - delete specified breakpoints.
function! AvdCmd#CmdDelete(arg)
    "call AvdCmd#Send('delete ' . a:arg)
    call AvdCmd#Send('d ' . a:arg)
    call AvdCmd#Res('@break delete')
endfunc


""" ***** Execution Control

" continue [COUNT] - continue program being debugged.
function! AvdCmd#CmdContinue(count)
    "call AvdCmd#Send('continue ' . a:count)
    call AvdCmd#Send('c ' . a:count)
endfunc

" finish - execute until selected stack frame returns.
function! AvdCmd#CmdFinish()
    call AvdCmd#Send('finish')
endfunc

" next [COUNT] - step program, proceeding through subroutine calls.
function! AvdCmd#CmdNext(count)
    "call AvdCmd#Send('next ' . a:count)
    call AvdCmd#Send('n ' . a:count)
endfunc

" nexti [COUNT] - step one instruction, but proceed through subroutine calls.
function! AvdCmd#CmdNexti(count)
    call AvdCmd#Send('nexti ' . a:count)
endfunc

" run - start or restart executing program.
function! AvdCmd#CmdRun()
    "call AvdCmd#Send('run')
    call AvdCmd#Send('r')
    call AvdCmd#Res('@run')
endfunc

" step [COUNT] - step program until it reaches a different source line.
function! AvdCmd#CmdStep(count)
    "call AvdCmd#Send('step ' . a:count)
    call AvdCmd#Send('s ' . a:count)
endfunc

" stepi [COUNT] - step one instruction exactly.
function! AvdCmd#CmdStepi(count)
    call AvdCmd#Send('stepi ' . a:count)
endfunc

"?until
"?command


""" ***** Viewing And Changing Data

" print var [var] - print value of a variable or array.
"function! AvdCmd#CmdPrint(...)
"    if g:run_time != 3 && g:run_time != 4
"	return
"    endif
"    call AvdCmd#Send('print ' . join(a:000))
"    "call AvdCmd#Res('\w\+ = ')
"    call AvdCmd#Res('\w\+\(\[".\+"\]\)\? = ')
"endfunc
function! AvdCmd#CmdPrint(arg)
    if g:run_time != 3 && g:run_time != 4
"?	return
    endif
    "call AvdCmd#Send('print ' . a:arg)
    call AvdCmd#Send('p ' . a:arg)
endfunc

" printf format, [arg], ... - formatted output.
function! AvdCmd#CmdPrintf(...)
    if g:run_time != 3 && g:run_time != 4
	return
    endif
    call AvdCmd#Send('printf ' . join(a:000))
    call AvdCmd#Res('')
endfunc

" set var = value - assign value to a scalar variable.
function! AvdCmd#CmdSet(expr)
    if g:run_time != 3 && g:run_time != 4
	return
    endif
    call AvdCmd#Send('set ' . a:expr)
    call AvdCmd#Res('')
endfunc

" eval stmt|[p1, p2, ...] - evaluate awk statement(s).
function! AvdCmd#CmdEval(expr)
    if g:run_time != 3 && g:run_time != 4
	return
    endif
    let expr = substitute(a:expr, '"', '\\"', "g")
    call AvdCmd#Send('eval "' . expr . '"')
    call AvdCmd#Res('')
    "out_tmpへ移動
    silent exe g:out_tmp_win . "wincmd w"
    silent edit!
    "src_fileへ移動
    silent exe g:src_win . "wincmd w"
endfunc


""" ***** Stack

" backtrace [N] - print trace of all or N innermost (outermost if N < 0) frames.
function! AvdCmd#CmdBacktrace(arg)
    call AvdCmd#StackSub('backtrace ', a:arg)
endfunc

" down [N] - move N frames down the stack.
function! AvdCmd#CmdDown(count)
    call AvdCmd#StackSub('down ', a:count)
endfunc

" up [N] - move N frames up the stack.
function! AvdCmd#CmdUp(count)
    call AvdCmd#StackSub('up ', a:count)
endfunc

" frame [N] - select and print stack frame number N.
function! AvdCmd#CmdFrame(arg)
    if a:arg == '' || a:arg =~ '\d\+'
	call AvdCmd#StackSub('frame', a:arg)
    endif
endfunc

function! AvdCmd#StackSub(cmd, count)
    if g:run_time != 3 && g:run_time != 4
	return
    endif
    if a:count == ''
	call AvdCmd#Send(a:cmd)
    elseif a:count =~ '-\?\d\+'
	call AvdCmd#Send(a:cmd . ' ' . a:count)
    endif
    if a:cmd == 'up ' || a:cmd == 'down '
	while (1)
	    let rcv = Recv(1)
	    if rcv > 0
		if g:Msg =~ '^#\d\+'
		    let mat = matchlist(g:Msg, '^\(#\d\+\)\s\+\%(in\)\? \(\w\+(.*)\)')
		    let mat[2] = substitute(mat[2], ' ', '\\ ', "g")
		    if bufwinnr(g:out_tmp) != -1
			"out_tmpへ移動
			silent exe g:out_tmp_win . "wincmd w"
			exe 'setlocal statusline=[avd.out]\ \ ' . g:now_line . '\ \ @' . g:now_fnc . '\ \ ->\ ' . mat[1] . ':' . mat[2]
			"src_fileへ移動
			silent exe g:src_win . "wincmd w"
		    else
			if bufexists(g:out_tmp) != 0
			    silent exe "tabnew " g:out_tmp
			    exe 'setlocal statusline=[avd.out]\ \ ' . g:now_line . '\ \ @' . g:now_fnc . '\ \ ->\ ' . mat[1] . ':' . mat[2]
			    silent exe "quit"
			endif
			echo g:Msg
		    endif
		    silent redraw
		endif
	    else
		return
	    endif
    endwhile
    else
	call AvdCmd#Res('')
    endif
endfunc


""" ***** Info

" info topic - source|sources|variables|functions|break|frame|args|locals|display|watch.
function! AvdCmd#CmdInfo(arg)
    if g:run_time != 3 && g:run_time != 4
	return
    endif
    call AvdCmd#Send('info ' . a:arg)
    call AvdCmd#Res('')
endfunc
function! AvdCmd#InfoCompl(A, L, P)
    return "args\nbreak\ndisplay\nframe\nfunctions\nlocals\nsource\nsources\nvariables\nwatch"
endfunc


""" ***** Miscellaneous

" dump [filename] - dump instructions to file or stdout.
function! AvdCmd#CmdDump(filename)
    if g:run_time != 3 && g:run_time != 4
	return
    endif
    "call AvdCmd#Send('dump ' . a:filename)
    "call AvdCmd#Send('dump ' . g:src_file)
    call AvdCmd#Send('dump')
    call AvdCmd#Res('')
endfunc

" quit - exit debugger.
function! AvdCmd#CmdQuit()
    " call AvdCmd#Send('quit')
    call AvdCmd#Send('q')
    if !has('win32') && !has('win64')
	call AvdCmd#Res('@quit')
    endif
endfunc

" trace on|off - print instruction before executing.
function! AvdCmd#CmdTrace(on_off)
    if a:on_off !=# "on" && a:on_off !=# "off"
	echo "Illegal yadayada."
	return
    endif
    call AvdCmd#Send('trace ' . a:on_off)
endfunc

function! AvdCmd#Res(match)
    while (1)
	let rcv = Recv(1)
	if rcv > 0
	    if a:match == "" || g:Msg =~ a:match
		return
	    endif
	else
	    return
	endif
    endwhile
endfunc


"r  S-F8
"c  F8
"n  F11
"ni S-F11
"s  F12
"si S-F12
"until S-F8
"finish C-F8
"command! -nargs=* AvdB		:call AvdCmd#CmdBreak(<q-args>)
"? ToDo
"command! -nargs=* AvdD		:call AvdCmd#CmdDelete(<q-args>)

command! -count=1 AvdC		:call AvdCmd#CmdContinue(<count>)
command!          AvdFinish	:call AvdCmd#CmdFinish()
command! -count=1 AvdN		:call AvdCmd#CmdNext(<count>)
command! -count=1 AvdNi		:call AvdCmd#CmdNexti(<count>)
command!          AvdR 		:call AvdCmd#CmdRun()
command! -count=1 AvdS 		:call AvdCmd#CmdStep(<count>)
command! -count=1 AvdSi 	:call AvdCmd#CmdStepi(<count>)

command! -nargs=+ AvdP  	:call AvdCmd#CmdPrint(<f-args>)
command! -nargs=+ AvdPrint	:call AvdCmd#CmdPrint(<f-args>)
command! -nargs=+ AvdPrintf	:call AvdCmd#CmdPrintf(<f-args>)
command! -nargs=1 AvdSet	:call AvdCmd#CmdSet(<q-args>)
command! -nargs=1 AvdEval	:call AvdCmd#CmdEval(<q-args>)

command! -count=0 AvdBt		:call AvdCmd#CmdBacktrace(<count>)
command! -count=1 AvdDown	:call AvdCmd#CmdDown(<count>)
command! -count=1 AvdUp		:call AvdCmd#CmdUp(<count>)
command! -nargs=? AvdFrame	:call AvdCmd#CmdFrame(<q-args>)

command! -nargs=1 -complete=custom,AvdCmd#InfoCompl AvdInfo	:call AvdCmd#CmdInfo(<q-args>)

command! -nargs=0 AvdQ		:call AvdCmd#CmdQuit()
command! -nargs=0 AvdQuit	:call AvdCmd#CmdQuit()

"complete filename
command! -nargs=? AvdDump	:call AvdCmd#CmdDump(<f-args>)
command! -nargs=1 AvdTrace 	:call AvdCmd#CmdTrace(<q-args>)




" clear:
" 	clear [[filename:]N|function] - delete breakpoints previously set.
" commands:
" 	commands [num] - starts a list of commands to be executed at a breakpoint(watchpoint) hit.
" condition:
" 	condition num [expr] - set or clear breakpoint or watchpoint condition.
" disable:
" 	disable [breakpoints] [range] - disable specified breakpoints.
" display:
" 	display [var] - print value of variable each time the program stops.
" enable:
" 	enable [once|del] [breakpoints] [range] - enable specified breakpoints.
" end:
" 	end - end a list of commands or awk statements.
" help:
" 	help [command] - print list of commands or explanation of command.
" ignore:
" 	ignore N COUNT - set ignore-count of breakpoint number N to COUNT.
" list:
" 	list [-|+|[filename:]lineno|function|range] - list specified line(s).
" option:
" 	option [name[=value]] - set or display debugger option(s).
" return:
" 	return [value] - make selected stack frame return to its caller.
" silent:
" 	silent - suspends usual message when stopped at a breakpoint/watchpoint.
" source:
" 	source file - execute commands from file.
" tbreak:
" 	tbreak [[filename:]N|function] - set a temporary breakpoint.
" undisplay:
" 	undisplay [N] - remove variable(s) from automatic display list.
" until:
" 	until [[filename:]N|function] - execute until program reaches a different line or line N within current frame.
" unwatch:
" 	unwatch [N] - remove variable(s) from watch list.
" watch:
" 	watch var - set a watchpoint for a variable.
