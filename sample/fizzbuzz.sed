#!/usr/bin/sed -f

/^$/ {
	s/.*/no input./
	b illegal_input
}

/[^0-9 \t]/ {
	s/.*/non digit character exist./
	b illegal_input
}

/[0-9][ \t][0-9]/ {
	s/.*/too many input data./
	b illegal_input
}

s/[ \t]//g
# ^n{n} F{f} B{b} #n{n}$
s/$/ F B #/

:loop

# quit
/^0\+ / {
	d
	q
}

# decrement
s/ /n /
:borrow
s/9n/8/
s/8n/7/
s/7n/6/
s/6n/5/
s/5n/4/
s/4n/3/
s/3n/2/
s/2n/1/
s/1n/0/
t cancel_d
:cancel_d
s/0n/n9/
tborrow
s/n//

s/F/Ff/
s/B/Bb/

# increment
s/$/n/
:carry
s/#n/#1/
s/0n/1/
s/1n/2/
s/2n/3/
s/3n/4/
s/4n/5/
s/5n/6/
s/6n/7/
s/7n/8/
s/8n/9/
t cancel_i
:cancel_i
s/9n/n0/
tcarry
s/n//

/Ffff Bbbbbb/ {
	ifizzbuzz
	s/fff//
	s/bbbbb//
	b end
}

/Ffff/ {
	ifizz
	s/fff//
	b end
}

/Bbbbbb/ {
	ibuzz
	s/bbbbb//
	b end
}

h
s/.*#//
p
g

:end
b loop

:illegal_input
s/^/fizzbuzz.sed error: /
p
q
