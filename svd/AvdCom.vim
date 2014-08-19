"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! AvdCom#Open()
python << EOF
import vim;
import socket;
import select;

cli = socket.socket()
cli.connect(('localhost', 33333))

sav = ''
EOF
endfunc

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! AvdCom#Close()
python << EOF
cli.close()
EOF
endfunc

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Send(arg)
    let cmd = a:arg . repeat(" ", g:MSGLEN - len(a:arg))
python << EOF
r, w, e = select.select([], [cli], [], 1)
if len(w) :
    msg = vim.eval('cmd')
    #msg.rstrip()
    #cli.sendall(msg + "\n")
    cli.sendall(msg)
    vim.command('let snd = 1');
else :
    vim.command('let snd = 0');
EOF
    return snd
endfunc

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Recv(timeout)
python << EOF
timeout = float(vim.eval('a:timeout'))
r, w, e = select.select([cli], [], [], timeout)
buf = ''
if len(r) :
    buf = cli.recv(1024)
    #    if len(buf) == 0 :
    #	vim.command('let rcv = -1')
    #	vim.command('let msg = ""')
    #	# ToDo
    sav += buf
if len(sav) > 0 :
    tmp = sav.split("\0", 1)
    msg = tmp[0]
    sav = tmp[1]
else :
    msg = ''
    sav = ''

    #vim.command('echo "^^^^" . "' + msg + '"')

if len(msg) == 0 and len(sav) == 0 :
    vim.command('let rcv = 0')
    vim.command('let msg = ""')
else :
    msg = msg.replace('"', '\\"')
    vim.command('let rcv = 1')
    vim.command('let msg = "' + msg + '"')
EOF
    let g:Msg = msg
    "echo msg
    "echo "#########"
    "red
    "sleep 13
    return rcv
endfunc
