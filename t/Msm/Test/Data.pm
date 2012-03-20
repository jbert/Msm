package Msm::Test::Data;

my @progs = (
        '(+ 2 3)',
        '(+ (+ 1 2) (- 2 3))',
        '(- 6 1 1 1 1 1 1 1 1 1 1 1 1)',
        '(- 6 1 0 1 0 1 0 1 0 1 0 1 0)',

        '(* 2 3)',
    );

sub progs {
    if ($ENV{MSM_TEST_ONE_ONLY}) {
        return @{[$progs[0]]};
    }
    return @progs;
}

1;
