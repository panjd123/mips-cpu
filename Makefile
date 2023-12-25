all:
	$(MAKE) -C 10inst/src
	$(MAKE) -C 50inst/src
	$(MAKE) -C single_cycle/src

submit:
	zip -r 10inst.zip 10inst
	zip -r 50inst.zip 50inst
	zip -r single_cycle.zip single_cycle

clean:
	$(MAKE) -C 10inst/src clean
	$(MAKE) -C 50inst/src clean
	$(MAKE) -C single_cycle/src clean