Msm
===

This is 'My ASM' project. A playground for parsing a small language and hopefully generating
assembly. The goal is to parse the (simple!) language to an AST and then:
- evaluate it
- compile it via translation to C
- 'compile' it via translation directly to assembler

Update, for ease of checking, I seem to be implemeting a (very limited subset of) scheme
(so I can run example code through mzscheme as well, to compare outputs). I currently have 3
backends, an evaluator, a C generator and an ASM generator.


INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Msm

LICENSE AND COPYRIGHT

Copyright (C) 2012 John Berthels

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

