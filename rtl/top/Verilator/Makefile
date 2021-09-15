PROJ = Rasterizer

all: simulation 

clean:
	rm -rf obj_dir

simulation:
	verilator -DUNITTEST -CFLAGS -std=c++11 --cc -exe top.v --top-module top ../../../unittest/cpp/sim_rasterizer.cpp -I../../RasteriCEr
	-make -C obj_dir -f Vtop.mk
	./obj_dir/Vtop

.SECONDARY:
.PHONY: all clean
