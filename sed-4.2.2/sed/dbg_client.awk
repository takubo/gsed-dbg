BEGIN {
  MSGLEN = 64
  RS = "\0"
  ORS = ""
  srv =  "/inet/tcp/0/localhost/1234"

  send_cmd("b 12")

  send_cmd("r")

  send_cmd("n")
  sleep(1)
  send_cmd("n")
  sleep(1)
  send_cmd("n")
  sleep(1)
  send_cmd("n")


  while ((a = srv |& getline) > 0)
    print "recv : ^" $0 "$"

  print a
  exit

  srv |& getline
  print "recv : ^" $0 "$"
  srv |& getline
  print "recv : ^" $0 "$"
}

function send_cmd(cmd,    msg) {
  msg = make_msg(cmd)
  print msg |& srv
  fflush(srv)
  print "[dbgsed_client send]:{" msg "}\n"

  a = srv |& getline
  # print "## " a "\n"
  print "[dbgsed_client recv]:{" $0 "}\n"
}

function make_msg(cmd,    len, pad) {
  len = length(cmd)
  pad = rep(" ", MSGLEN - len)
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
