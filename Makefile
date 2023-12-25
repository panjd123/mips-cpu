all:
	$(MAKE) -C inst10/src
	$(MAKE) -C inst50/src
	$(MAKE) -C single_cycle/src


clean:
	$(MAKE) -C inst10/src clean
	$(MAKE) -C inst50/src clean
	$(MAKE) -C single_cycle/src clean