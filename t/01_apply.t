use Test::More;
use Test::Base::Less ();
use PPI;

use App::try_tiny2syntax_keyword_try;

my $app = App::try_tiny2syntax_keyword_try->new;

for my $block (Test::Base::Less::blocks) {
    my $doc = PPI::Document->new(\$block->input);
    $app->apply($doc);
    is $doc->serialize, $block->expected;
}

done_testing;
__DATA__

===
--- input
use Try::Tiny;
--- expected
use Syntax::Keyword::Try;
===
--- input
use Try::Tiny qw(try catch finally);
--- expected
use Syntax::Keyword::Try;
===
--- input
try {
} catch {
} finally {
};
--- expected
try {
} catch {
} finally {
}
===
--- input
try { die };
--- expected
eval { die };
===
--- input
my $x = try { die };
--- expected
my $x = eval { die };
===
--- input
try {
} catch {
    $_;
};
--- expected
try {
} catch {
    $@;
}
===
--- input
try {
} catch {
    my $e = $_;
};
--- expected
try {
} catch {
    my $e = $@;
}
===
--- input
try {
} catch {
    critf($_);
};
--- expected
try {
} catch {
    critf($@);
}
===
--- input
try {
} catch {
};
try {
} catch {
};
--- expected
try {
} catch {
}
try {
} catch {
}
===
--- input
try {} catch {}; 1;
--- expected
try {} catch {} 1;
===
--- input
try {
} catch {
    if ($_) {
        $_;
    }
};
--- expected
try {
} catch {
    if ($@) {
        $@;
    }
}
===
--- input
try {
} catch {
    for () {
        $_;
    }
};
--- expected
try {
} catch {
    for () {
        $@;
    }
}
