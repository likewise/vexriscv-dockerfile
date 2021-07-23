FROM ubuntu:18.04

#ARG TERM=linux

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#RUN DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true dpkg-reconfigure dash

# Set BASH as the default shell
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN dpkg-reconfigure dash

ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get upgrade -y && apt-get update && apt-get install -y \
  apt-utils sudo nano

# make a vexriscv user
RUN adduser --disabled-password --gecos '' vexriscv
# give sudo rights
RUN mkdir -p /etc/sudoers.d
RUN echo >/etc/sudoers.d/vexriscv 'vexriscv ALL = (ALL) NOPASSWD: SETENV: ALL'

RUN apt-get update && apt-get upgrade -y && apt-get update && apt-get install -y \
  software-properties-common

RUN apt-get update && apt-get upgrade -y && apt-get update && apt-get install -y \
  scala build-essential git make autoconf g++ flex bison

RUN git clone http://git.veripool.org/git/verilator && cd verilator && git checkout v4.040 && \
  autoconf && ./configure && make install

RUN apt-get install -y curl

RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
RUN apt-get update
RUN apt-get install sbt

RUN curl -sL "https://nav.dl.sourceforge.net/project/openocd/openocd/0.11.0/openocd-0.11.0.tar.bz2" | tar xj
RUN cd openocd-0.11.0 && ./configure && make install -j8

# required by the VexRiscv full (debug module)
RUN apt-get install -y libz-dev gdb

# required to build the RISC-V cross compiler toolchain
RUN apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev -y

RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain
RUN cd riscv-gnu-toolchain && git submodule update --init

RUN apt-get install -y locales autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

RUN pwd
RUN ARCH=rv32im && mkdir riscv-gnu-toolchain/$ARCH && cd riscv-gnu-toolchain/$ARCH && ../configure --prefix=/opt/$ARCH --with-arch=$ARCH --with-abi=ilp32; make -j16; cd ../..
RUN pwd
RUN ARCH=rv32i  && mkdir riscv-gnu-toolchain/$ARCH && cd riscv-gnu-toolchain/$ARCH && ../configure  --prefix=/opt/$ARCH --with-arch=$ARCH --with-abi=ilp32; make -j16 && cd ../..
RUN pwd

# build openocd spiral
RUN apt-get install -y pkg-config libtool libyaml-dev libftdi-dev libusb-1.0.0

RUN git clone https://github.com/SpinalHDL/openocd_riscv && cd openocd_riscv && \
./bootstrap && ./configure --prefix=/opt/openocd-riscv && make -j16 install && cd ..

# killall netstat lsusb. default-jdk to build simulation support for verilator (jni.h was missing)
RUN apt-get install -y psmisc net-tools usbutils default-jdk-headless

# remaining build steps are run as this user; this is also the default user when the image is run.
USER vexriscv
WORKDIR /home/vexriscv

#RUN git clone git@github.com:SpinalHDL/VexRiscv.git vexriscv
#RUN git clone https://github.com/SpinalHDL/VexRiscv.git vexriscv && \
#  cd vexriscv && sbt --help
#RUN sbt "runMain vexriscv.demo.GenSmallest"

