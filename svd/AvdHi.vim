hi SignColumn					guibg=darkgrey
hi SignColumnNC					guibg=darkgrey
hi AvdDummyHi					guibg=darkgrey

hi BpEnable	gui=bold	guifg=#ff2000	guibg=darkgrey
hi BpInvalid	gui=bold	guifg=#ff2000	guibg=darkgrey
hi BpEnableCur	gui=bold	guifg=#ff2000	guibg=yellow

hi CurrentHi1	gui=bold	guifg=#ff2000	guibg=yellow
hi CurrentHi2	gui=none	guifg=black	guibg=yellow

hi SyntaxErrHi1					guibg=#b06060
hi SyntaxErrHi2					guibg=#b06060

hi RuntimeErrHi1				guibg=#6a2222
hi RuntimeErrHi2				guibg=#6a2222

sign define AvdDummy	texthl=AvdDummyHi	text=　

sign define BpNrml	texthl=BpEnable		text=@
sign define BpInvNrml	texthl=BpInvalid	text=%

sign define RuntimeErr	texthl=RuntimeErrHi1	linehl=RuntimeErrHi2	text=x
sign define SyntaxErr	texthl=SyntaxErrHi1	linehl=SyntaxErrHi2	text=x

if 1
  sign define Current	texthl=CurrentHi1	linehl=CurrentHi2	text=　
  sign define CurBpNrml	texthl=CurrentHi1	linehl=CurrentHi2	text=@
else
  sign define Current	texthl=CurrentHi1	text=　
  sign define CurBpNrml	texthl=CurrentHi1	text=@
endif
