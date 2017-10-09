Summary
=======

This template is meant as a basic starting point for ATtiny817
([ATtiny817-Xmini](http://www.atmel.com/tools/attiny817-xmini.aspx))
projects written in assembler for low power applications.

Features:
- Interrupt-Vector
```asm
.cseg
.org 0x00 ; RESET
	rjmp main

.org 0x02 ; NMI - Non-Maskable Interrupt from CRC
	rjmp int_catch
.org 0x04 ; VLM - Voltage Level Monitor
	rjmp int_catch
...
```
- Automatic unlocking of protected io-registers
```asm
sconf CLKCTRL_MCLKCTRLA, CLKCTRL_CLKSEL_OSCULP32K_gc
```
- Configuration of 32.768kHz oscillator
```asm
; +----------------------------------------------------------------------------+
; | Init Clock                                                                 |
; +----------------------------------------------------------------------------+
init_clock:
	; Enable ultra low power oscillator
	sconf CLKCTRL_MCLKCTRLA, CLKCTRL_CLKSEL_OSCULP32K_gc

_init_clock_wait_for_32kosc: ; Wait for clock to be stable
	lds reg_tmp0, CLKCTRL_MCLKSTATUS
	sbrs reg_tmp0, CLKCTRL_OSC32KS_bp
	rjmp _init_clock_wait_for_32kosc
	
	sconf CLKCTRL_MCLKCTRLB, 0x00 ; Disable divider
	sconf CLKCTRL_MCLKLOCK, CLKCTRL_LOCKEN_bm ; Lock clock config. register
	ret ; Return
```