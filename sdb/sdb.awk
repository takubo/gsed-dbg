BEGIN {
	SEND_MSGLEN = 64
	ORS = ""
	srv =  "/inet/tcp/0/localhost/33333"

	send_cmd("h")
	print "connenction established.\n"
	print "start debug!\n"
	print "sdb> "
	fflush()
}

$0 || $0 = prev {
	# gsub(/[ \t]+/, " ")
	sub(/[ \t]+/, " ")

	sub(/^break/, "b")
	sub(/^continue/, "c")
	sub(/^delete/, "d")
	sub(/^hello/, "h")
	sub(/^next/, "n")
	sub(/^print/, "p")
	sub(/^quit/, "q")
	sub(/^run/, "r")
	sub(/^step/, "s")

	send_cmd($0)
  	# print $0 "\n"
}

$1 == "q" {
	close(srv)
	exit 0
}

{
	print "sdb> "
	fflush()
	prev = $0
}

function get_recv_num(cmd) {
	sleep(1)

	switch (substr(cmd, 1, 1)) {
	case "p":
		switch (substr(cmd, 3, 4)) {
		case "PTRN":
		case "HOLD":
		case "FLAG":
			return 1
			break
		}
		return 3
		break
	case "b":
	case "d":
	case "h":
	case "q":
		return 1
		break
	case "c":
	case "n":
	case "r":
	case "s":
		return 2
		break
	default:
		return 1
		break
	}
}

function send_cmd(cmd,    recv_num, msg, rs) {
	rs = RS
	RS = "\0"

	recv_num = get_recv_num(cmd)

	msg = make_msg(cmd)
	print msg |& srv
	fflush(srv)

	if (dbg) print "[sdb.awk] : send : {" msg "}\n"

	while (recv_num--) {
		a = srv |& getline recv
		if (dbg) print "[sdb.awk] : recv : {" recv "}\n"

		print substr(recv, 2), "\n"
		fflush()
	}

	RS = rs
}

function make_msg(cmd,    len, pad) {
	len = length(cmd)
	pad = rep(" ", SEND_MSGLEN - len)
	return cmd pad
}

function rep(str, num,     res) {
	while (num--)
		res = res str
	return res
}

function sleep(time) {
	"sleep " time | getline dummy
	close("sleep " time)
}
