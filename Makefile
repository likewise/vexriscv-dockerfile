.ONESHELL:

.PHONY: build
build:
	docker build --build-arg=TERM="linux" --network=host -t vexriscv .


# -e DISPLAY= and -v /tmp/.X11-unix:<...> allows graphical applications inside container to display on host
# --network="host" allows localhost inside container to reach host ports
# --device=/dev/ttyUSB0 assumes BusBlaster v2.5 on host is on /dev/ttyUSB0 (dmesg)
# -v $$PWD/project:<...> means we mount the host project directory for persistent read/write
run:
	docker run -ti --rm \
	--name vexriscv \
	-e DISPLAY=$(DISPLAY) -v /tmp/.X11-unix:/tmp/.X11-unix \
	--network="host" \
	--device=/dev/bus \
	-v $$PWD/project:/home/vexriscv/project -w /home/vexriscv/project \
	vexriscv:latest
#	--device=/dev/ttyUSB0 \


monitor:
	docker exec -ti \
	vexriscv sudo /opt/openocd-riscv/bin/openocd -f interface/ftdi/dp_busblaster.cfg -c "set MURAX_CPU0_YAML vexriscv/cpu0.yaml" -f target/murax.cfg
