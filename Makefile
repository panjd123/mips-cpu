all:
	$(MAKE) -C inst10/src
	$(MAKE) -C inst50/src
	$(MAKE) -C single_cycle/src

submit:
	zip -r inst10.zip inst10
	zip -r inst50.zip inst50
	zip -r single_cycle.zip single_cycle

clean:
	$(MAKE) -C inst10/src clean
	$(MAKE) -C inst50/src clean
	$(MAKE) -C single_cycle/src clean