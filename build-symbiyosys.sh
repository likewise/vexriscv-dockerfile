#!/bin/bash
set -e
set -e -o pipefail

SYMBIYOSYS_DESTDIR=$HOME/opt/formal
#SYMBIYOSYS_DESTDIR=/tmp/formal

mkdir -p ${SYMBIYOSYS_DESTDIR}/bin

function super_prove () {
	#hg clone -r d7b71160dddb https://bitbucket.org/sterin/super_prove_build || true
	cd super-prove-build
	mkdir -p build

	#cd abc-zz
	#wget -nc "https://bitbucket.org/sterin/super_prove_build/issues/attachments/4/sterin/super_prove_build/1565269491.41/4/fix_super_prove_build.txt"
	#patch -p1 -N -i fix_super_prove_build.txt || true
	#cd .. # abc-zz

	cd build
	cmake -DCMAKE_BUILD_TYPE=Release -G Ninja ..

	ninja
	ninja package

	# install
	tar xzf super_prove*.tar.gz -C ${SYMBIYOSYS_DESTDIR}
	cd .. # build

	# install wrapper
	#wget -nc -O ${SYMBIYOSYS_DESTDIR}/bin/suprove https://bitbucket.org/sterin/super_prove_build/issues/attachments/4/sterin/super_prove_build/1565269491.6/4/suprove
	#chmod +x ${SYMBIYOSYS_DESTDIR}/bin/suprove
	#sed -i 's@/usr/local@${SYMBIYOSYS_DESTDIR}@' ${SYMBIYOSYS_DESTDIR}/bin/suprove

	cd .. # super-prove-build

cat <<EOF > /${SYMBIYOSYS_DESTDIR}/bin/suprove
#!/bin/bash
tool=super_prove; if [ "$1" != "${1#+}" ]; then tool="${1#+}"; shift; fi
exec ${SYMBIYOSYS_DESTDIR}/super_prove/bin/${tool}.sh "$@"
EOF


}

function extavy () {
	cd extavy
	cd avy
	patch -p1 -i ../../avy.patch
        cd ..
	mkdir -p build
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release ..
	make -j$(nproc)
	mkdir -p ${SYMBIYOSYS_DESTDIR}/bin
	cp avy/src/{avy,avybmc} ${SYMBIYOSYS_DESTDIR}/bin
	cd .. # build
	cd .. # extavy

}

#rm -rf ${SYMBIYOSYS_DESTDIR}
#mkdir -p ${SYMBIYOSYS_DESTDIR}

#sudo apt-get install build-essential clang bison flex libreadline-dev \
#                     gawk tcl-dev libffi-dev git mercurial graphviz   \
#                     xdot pkg-config python python3 libftdi-dev gperf \
#                     libboost-program-options-dev autoconf libgmp-dev \
#                     cmake 
#
#sudo apt-get install python-dev python3-dev

#git submodule update --init --remote --recursive

#super_prove

#extavy

cd yosys
make -j$(nproc)
make install DESTDIR="" PREFIX=${SYMBIYOSYS_DESTDIR}
cd .. #yosys

cd SymbiYosys
make -j$(nproc) install DESTDIR="" PREFIX=${SYMBIYOSYS_DESTDIR}
cd ..

cd yices2
autoconf
./configure --prefix=${SYMBIYOSYS_DESTDIR}
make -j$(nproc)
make install
cd .. #yices2

cd z3
python scripts/mk_make.py
cd build
make -j$(nproc)
make install DESTDIR="" PREFIX=${SYMBIYOSYS_DESTDIR}
cd .. #build
cd .. #z3

cd boolector
./contrib/setup-btor2tools.sh
./contrib/setup-lingeling.sh
./configure.sh
make -C build -j$(nproc)
cp -av build/bin/{boolector,btor*} ${SYMBIYOSYS_DESTDIR}/bin/
cp -av deps/btor2tools/bin/btorsim ${SYMBIYOSYS_DESTDIR}/bin/
cd .. #boolector
