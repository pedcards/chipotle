msg := test(0)

MsgBox % (msg) ? "good" : "1"

ExitApp

test(val) {
	if (val=1) {
		return Error
	} else {
		return val
	}
}
