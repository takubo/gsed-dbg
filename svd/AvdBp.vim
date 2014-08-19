"シーケンシャル番号　=  ID
"ファイル名
"行番号
"ハイライトタイプ
"ブレークポイント番号
"設定できたかフラグ
"カーレントか否か
"??Enable Disable
"??Ignore回数
"??条件文

"call add(b:BP, {'id':b:bp_num, 'file':expand("%:p"), 'line':line("."), 'hi':"", 'num':0, 'can':g:false, 'cur':g:false, 'enable':g:true, 'ignore':0, 'cond':""})
"
"call add(b:BP, {'line':line("."), 'enable':g:true, 'ignore':0, 'cond':"", 'hi':"", 'num':0, 'can':g:false, 'cur':g:false})
"

"行をキーにしてリファレンス


"initialize
if ! exists('b:bp_num')
    "CUR_ID は停止位置用なので、bp_numの初期値をCUR_IDにしておけば、
    "BreakPointは次の数から始まる。
    let b:bp_num = g:CUR_ID
endif
if !exists('b:BP')
    "unlet b:BP
    let b:BP = []
    "g:DUM_IDの分
    call add(b:BP, {'line':line("."), 'enable':g:true, 'ignore':0, 'cond':"", 'hi':"BpNrml", 'num':0, 'can':g:true})
    "g:CUR_IDの分
    call add(b:BP, {'line':line("."), 'enable':g:true, 'ignore':0, 'cond':"", 'hi':"BpNrml", 'num':0, 'can':g:true})
    "リストのIndexが0始まりなので、調整
    call add(b:BP, {'line':line("."), 'enable':g:true, 'ignore':0, 'cond':"", 'hi':"BpNrml", 'num':0, 'can':g:true})
endif


function! AvdBp#BreakPoint()
    if &filetype != 'sed'
	return
    endif
    let line = line(".")
    let file = expand("%:p")
    let places = s:GetVimCmdOutput("sign place file=" . file)
    let place = split(places, '\n')
    let already = g:false
    let current = g:false
    if len(place) > 2
    "最上1行はタイトル列
	"lenでplaceの要素数
	for ii in range(2, len(place) - 1)
	    let tmp = split(place[ii], '\s\+\|=')
	    let sign = {tmp[0] : tmp[1], tmp[2] : tmp[3], tmp[4] : tmp[5]}
	    if line == tmp[1] && tmp[5] =~# '^Bp'
		let already = g:true
		let id = tmp[3]
	    endif
	    if line == tmp[1] && tmp[5] =~# '^Cur'
	        let current = g:true
	    endif
	endfor
    endif
    if !already
	call AvdBp#s:SetBreak(file, line, current)
    else
	call AvdBp#s:DelBreak(file, line, id, current)
    end
endfunction

function! AvdBp#s:SetBreak(file, line, current)
    let b:bp_num += 1
    let id = b:bp_num
    call add(b:BP, {'line':line("."), 'enable':g:true, 'ignore':0, 'cond':"", 'hi':"BpNrml", 'num':0, 'can':g:true})
    exe "sign place " . id . " line=" . a:line . " name=BpNrml file=" . a:file
    if a:current
	exe "sign place " . g:CUR_ID . " line=" . a:line . " name=CurBpNrml file=" . a:file
    endif
    if g:run_time
	call AvdCmd#CmdBreak(a:line, id)
    endif
endfunction

function! AvdBp#s:DelBreak(file, line, id, current)
    exe 'sign unplace '. a:id . ' file=' . a:file
    if a:current
	exe "sign place " . g:CUR_ID . " line=" . a:line . " name=Current file=" . a:file
    endif
    if g:run_time && b:BP[a:id]['num'] != 0
	call AvdCmd#CmdDelete(b:BP[a:id]['num'])
    endif
endfunction

function! AvdBp#StartBreak()
    let file = g:src_file     |  "expand("%:p")
    let places = s:GetVimCmdOutput("sign place file=" . file)
    let place = split(places, '\n')
    if len(place) > 2
    "最上1行はタイトル列
	"lenでplaceの要素数
	let max_ii = len(place) - 1
	for ii in range(2, max_ii)
	    let tmp = split(place[ii], '\s\+\|=')
	    "let sign = {tmp[0] : tmp[1], tmp[2] : tmp[3], tmp[4] : tmp[5]}
	    if tmp[5] == 'BpNrml' || tmp[5] == 'BpInvNrml'
		call AvdCmd#CmdBreak(tmp[1], tmp[3])
	    endif
	endfor
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"  GetVimCmdOutput:
" Stole from Hari Krishna Dara's genutils.vim (http://vim.sourceforge.net/scripts/script.php?script_id=197)
"  to ease the scripts dependency issue
fun! s:GetVimCmdOutput(cmd)
"  call Dfunc("GetVimCmdOutput(cmd.".a:cmd.">)")

  " Save the original locale setting for the messages
  let old_lang = v:lang

  " Set the language to English
  exec ":lan mes en_US"

  let v:errmsg = ''
  let output   = ''
  let _z       = @z

  try
    redir @z
    silent exe a:cmd
  catch /.*/
    let v:errmsg = substitute(v:exception, '^[^:]\+:', '', '')
  finally
    redir END
    if v:errmsg == ''
      let output = @z
    endif
    let @z = _z
  endtry

  " Restore the original locale
  exec ":lan mes " . old_lang

"  call Dret("GetVimCmdOutput <".output.">")
  return output
endfun


