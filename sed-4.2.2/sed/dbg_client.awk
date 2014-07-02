BEGIN {
	SEND_MSGLEN = 64
	RS = "\0"
	ORS = ""
	srv =  "/inet/tcp/0/localhost/33333"

	send_cmd("b 2")
	sleep(1)

	send_cmd("r", 2)
	sleep(1)

	send_cmd("p PTRN")
	send_cmd("p HOLD")
	send_cmd("p FLAG")
	sleep(1)

	send_cmd("n", 2)
	sleep(1)

	send_cmd("n", 2)
	sleep(1)

	send_cmd("n", 2)
	sleep(1)

	send_cmd("p PTRN")
	send_cmd("p HOLD")
	send_cmd("p FLAG")
	sleep(1)

	send_cmd("d 2")
	send_cmd("q", 1)


	while ((a = srv |& getline) > 0)
		print "recv : ^" $0 "$"

	# print a
	exit

	srv |& getline
	print "recv : ^" $0 "$"
	srv |& getline
	print "recv : ^" $0 "$"
}

function send_cmd(cmd, recv_num,    msg) {
	msg = make_msg(cmd)
	print msg |& srv
	fflush(srv)
	print "[sdb.awk] : send : {" msg "}\n"

	recv_num = recv_num == "" ? 1 : recv_num
	while (recv_num--) {
		a = srv |& getline
		# print "## " a "\n"
		print "[sdb.awk] : recv : {" $0 "}\n"
	}
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
