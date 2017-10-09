;
; main.asm
;
; Created: 16.09.2017 00:46:03
; Author : Tobias Faller
;

; +----------------------------------------------------------------------------+
; | Interrupt vector                                                           |
; +----------------------------------------------------------------------------+

.cseg
.org 0x00 ; RESET
	rjmp main

.org 0x02 ; NMI - Non-Maskable Interrupt from CRC
	rjmp int_catch
.org 0x04 ; VLM - Voltage Level Monitor
	rjmp int_catch

.org 0x06 ; PORTA - Port A
	rjmp int_catch
.org 0x08 ; PORTA - Port B
	rjmp int_catch
.org 0x0A ; PORTA - Port C
	rjmp int_catch

.org 0x0C ; RTC - Real Time Counter
	rjmp int_catch
.org 0x0E ; PIT - Periodic Interrupt Timer (in RTC peripheral)
	rjmp int_catch

.org 0x10 ; TCA0 - Timer Type A - Overflow / Low Underflow
	rjmp int_catch
.org 0x12 ; TCA0 - Timer Type A - Compare Channel 0 / High underflow
	rjmp int_catch
.org 0x14 ; TCA0 - Timer Type A - Compare Channel 1 / Compare Channel 0
	rjmp int_catch
.org 0x16 ; TCA0 - Timer Type A - Compare Channel 2 / Compare Channel 1
	rjmp int_catch
.org 0x18 ; TCA0 - Timer Type A - Empty / Compare Channel 2
	rjmp int_catch

.org 0x1A ; TCB0 - Timer Type B
	rjmp int_catch

.org 0x1C ; TCD0 - Timer Type D - Overflow
	rjmp int_catch
.org 0x1E ; TCD0 - Timer Type D - Trigger
	rjmp int_catch

.org 0x20 ; AC0 – Analog Comparator
	rjmp int_catch

.org 0x22 ; ADC0 – Analog-to-Digital Converter - Result Ready
	rjmp int_catch
.org 0x24 ; ADC0 – Analog-to-Digital Converter - Window Comparator
	rjmp int_catch

.org 0x26 ; TWI0 - Two Wire Interface / I2C - Slave
	rjmp int_catch
.org 0x28 ; TWI0 - Two Wire Interface / I2C - Master
	rjmp int_catch

.org 0x2A ; SPI0 - Serial Peripheral Interface
	rjmp int_catch

.org 0x2C ; USART0 - Universal Asynchronous Rx-Tx - Receive Complete
	rjmp int_catch
.org 0x2E ; USART0 - Universal Asynchronous Rx-Tx - Transmit Buffer Empty
	rjmp int_catch
.org 0x30 ; USART0 - Universal Asynchronous Rx-Tx - Transmit Complete
	rjmp int_catch

.org 0x32 ; NVM - Non Volatile Memory
	rjmp int_catch

; +----------------------------------------------------------------------------+
; | Register                                                                   |
; +----------------------------------------------------------------------------+

; Define exclusive registers with ".def reg_example = rX" with X of 0 .. 31
; The registers r0-r15 are limited to a subset of instructions

.def reg_io_unlock = r15 ; Quick IO config unlock register
.def reg_tmp0 = r16 ; General purpose temprary register

; +----------------------------------------------------------------------------+
; | Macros                                                                     |
; +----------------------------------------------------------------------------+

; Immediate write IO configuration with unlocking the protected io memory
;
; Example:
;    sconf WDT_CTRLA, 0x00 ; Write 0x00 to WDT_CTRLA IO config register
;
.macro sconf
	ldi reg_tmp0, @1
	sts CPU_CCP, reg_io_unlock
	sts @0, reg_tmp0
.endmacro

; Store value to RAM emulated by writing to temporary register reg_tmp0
; followed by a store operation.
;
; Example:
;     sti CPU_SPL, low(RAMEND)
;     sti CPU_SPH, high(RAMEND)
;
;.macro sti
;	ldi reg_tmp0, @1
;	sts @0, reg_tmp0
;.endmacro

; +----------------------------------------------------------------------------+
; | Port Definitions                                                           |
; +----------------------------------------------------------------------------+

.equ PORT_A = 0x02
.equ PORT_B = 0x06
.equ PORT_C = 0x0A

; +----------------------------------------------------------------------------+
; | Definitions                                                                |
; +----------------------------------------------------------------------------+

; Define constant expressions with either "#define NAME VALUE"
; (preprocessor macro) or constant value expressions with ".equ NAME = VALUE"

; +----------------------------------------------------------------------------+
; | Data                                                                       |
; +----------------------------------------------------------------------------+

.dseg ; Data segment (RAM)

; Define data in RAM with "name: .byte X" with X as bytesize

; +----------------------------------------------------------------------------+
; | Entry point                                                                |
; +----------------------------------------------------------------------------+

.cseg ; Code segment (FLASH)

main:
	; Initialize stack (Automatically done by ATtiny817)
	; sti CPU_SPL, low(RAMEND)
	; sti CPU_SPH, high(RAMEND)

	; Initialize protected IO memory quick unlock
	ldi reg_tmp0, CPU_CCP_IOREG_gc ; IO memory unlock code
	mov reg_io_unlock, reg_tmp0 ; Move to unused register reg_io_unlock

	; Initialize components
	rcall init_watchdog
	rcall init_clock
	rcall init_io

	rcall init_data

	rjmp loop

; +----------------------------------------------------------------------------+
; | Init Watchdog                                                              |
; +----------------------------------------------------------------------------+
init_watchdog:
	sconf WDT_CTRLA, (WDT_PERIOD_OFF_gc | WDT_WINDOW_OFF_gc) ; Disable watchdog
	sconf WDT_STATUS, WDT_LOCK_bm ; Lock Watchdog
	ret ; Return

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

; +----------------------------------------------------------------------------+
; | Init IO                                                                    |
; +----------------------------------------------------------------------------+
init_io:
	; Pin A1
	; Clear bit 1 to config as input
	sconf PORTA_DIRCLR, 0x01
	; INVEN = 0x0 (Off), PULLUPEN = 0x0 (Off), ISC = 0x0 (INTDISABLE)
	sconf PORTA_PIN1CTRL, 0x00

	; PIN A2
	; Set bit 2 to config as output
	sconf PORTA_DIRSET, 0x02
	; INVEN = 0x0 (Off), PULLUPEN = 0x0 (Off), ISC = 0x0 (INTDISABLE)
	sconf PORTA_PIN2CTRL, 0x00

	ret ; Return

; +----------------------------------------------------------------------------+
; | Init default configuration                                                 |
; +----------------------------------------------------------------------------+
init_data:
	ret ; Return

; +----------------------------------------------------------------------------+
; | Main Loop                                                                  |
; +----------------------------------------------------------------------------+
loop:
	; Mirror pin A1 to A2
	in reg_tmp0, PORT_A
	andi reg_tmp0, 0x01
	lsl reg_tmp0
	out PORT_A, reg_tmp0
	rjmp loop ; Jump to loop start

; +----------------------------------------------------------------------------+
; | Interrupts                                                                 |
; +----------------------------------------------------------------------------+

int_catch: ; Catch unused interrupts
	rjmp int_catch