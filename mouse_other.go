//go:build !darwin

package main

import "github.com/go-vgo/robotgo"

func getMousePos() (int, int) {
	return robotgo.GetMousePos()
}

func moveMouse(x, y int) {
	robotgo.MoveMouse(x, y)
}

func clickMouse(button string, double bool) {
	robotgo.Click(button, double)
}
