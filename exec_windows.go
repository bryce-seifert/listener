//go:build windows

package main

import (
	"os/exec"
	"syscall"
)

// hideCmdWindow suppresses the console window for cmd.exe
func hideCmdWindow(cmd *exec.Cmd) {
	if cmd == nil {
		return
	}
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
}
