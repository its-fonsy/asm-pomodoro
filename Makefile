MCU	:= atmega328p
F_CPU	:= 16000000
BAUD	:= 115200
PORT	:= /dev/ttyACM0

AVRA	:= avra
AVRDUDE	:= avrdude

AVRDUDE_FLAGS	:= -c arduino -p $(MCU) -P $(PORT) -b $(BAUD)
AVRA_FLAGS	:=

SRC	:= main.s
HEX	:= main.hex

$(HEX): $(SRC)
	$(AVRA) $(AVRA_FLAGS) -o $@ -fI $<

flash: $(HEX)
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<

clean:
	rm -f *.eep.hex *.obj *.cof *.hex

.PHONY: all clean

