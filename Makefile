CC = gcc
ASM = nasm
LD = ld

# Custom

deploy-image: recompile clean-object-files

run: all target/os-image
	qemu-system-i386 -machine q35 -fda target/os-image

debug: all target/os-image
	qemu-system-i386 -D log.txt -machine q35 -fda target/os-image -s -S

recompile: prep all

all: target/os-image

prep: clean boot/ kernel/ drivers/
	mkdir target

clean:
	rm -rf target/

clean-object-files:
	rm target/*.o
	rm target/*.bin

# Boot

target/kernel_entry.o: boot/kernel_entry.asm
	$(ASM) $< -f elf32 -o $@

target/bootstrap.bin: boot/bootstrap.asm
	$(ASM) $< -f bin -o $@

boot_targets: target/kernel_entry.o

# Drivers

target/screen.o: drivers/screen.c
	$(CC) -fno-pie -m32 -ffreestanding -c $< -o $@

target/idt.o: drivers/idt.c
	$(CC) -fno-pie -m32 -ffreestanding -c $< -o $@

target/keyboard.o: drivers/keyboard.c
	$(CC) -fno-pie -m32 -ffreestanding -c $< -o $@

target/io_functions.o: drivers/io_functions.asm
	$(ASM) $< -f elf32 -o $@

driver_targets: target/screen.o target/idt.o target/keyboard.o target/io_functions.o

# Kernel

target/util.o: kernel/util.c
	$(CC) -fno-pie -m32 -ffreestanding -c $< -o $@

target/shell.o: kernel/shell.c
	$(CC) -fno-pie -m32 -ffreestanding -c $< -o $@

target/kernel.o: kernel/kernel.c
	$(CC) -fno-pie -m32 -ffreestanding -c $< -o $@

target/mem.o: kernel/memory/paging.c
	$(CC) -fno-pie -m32 -ffreestanding -c $< -o $@

kernel_targets: target/util.o target/shell.o target/mem.o target/kernel.o

# Finalize

target/kernel.bin: target/kernel_entry.o target/screen.o target/idt.o target/keyboard.o target/util.o target/shell.o target/mem.o target/kernel.o target/io_functions.o
	$(LD) -m elf_i386 -o $@ -Ttext 0x1000 $^ --oformat binary

target/os-image: target/bootstrap.bin target/kernel.bin
	cat $^ > $@
