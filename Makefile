all:
	pp -o combinator.bin src/combinator.pl
	pp -o hybrid_6.bin src/hybrid_6.pl
	pp -o hybrid_7.bin src/hybrid_7.pl	

install:
	mkdir -p $(DESTDIR)/opt/hashstack/programs/utils/
	install -m 0755 combinator.bin $(DESTDIR)/opt/hashstack/programs/utils/
	install -m 0755 hybrid_6.bin $(DESTDIR)/opt/hashstack/programs/utils/
	install -m 0755 hybrid_7.bin $(DESTDIR)/opt/hashstack/programs/utils/

clean:
	rm -f combinator.bin hybrid_6.bin hybrid_7.bin

