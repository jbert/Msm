package Msm::Runner;
use Modern::Perl;
use Moose;
use Msm::Toc;

has 'engine_type', is => 'rw';

sub run_ast {
    my ($self, $ast) = @_;

    my $engine_pkg = "Msm::".$self->engine_type;
    my $engine = $engine_pkg->new;
    return $engine->run_ast($ast);
}


1;
