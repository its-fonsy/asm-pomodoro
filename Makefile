MCU	:= atmega328p
F_CPU	:= 16000000
BAUD	:= 115200
PORT	:= /dev/ttyACM0

INC_DIR	:= inc

AVRA	:= avra
AVRDUDE	:= avrdude

AVRDUDE_FLAGS	:= -c arduino -p $(MCU) -P $(PORT) -b $(BAUD)
AVRA_FLAGS	:= -I $(INC_DIR)

INCS	:= $(wildcard inc/*.s)
SRC	:= main.s
TARGET	:= main.hex

$(TARGET): $(SRC) $(INCS)
	$(AVRA) $(AVRA_FLAGS) -o $@ -fI $<

flash: $(TARGET)
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<

clean:
	rm -f *.eep.hex *.obj *.cof *.hex

.PHONY: clean flash

