package App::try_tiny2syntax_keyword_try;
use strict;
use warnings;
use PPI;

our $VERSION = "0.01";

sub new { bless {}, shift }

sub run {
    my ($self, @files) = @_;

    for my $file (@files) {
        my $doc = PPI::Document->new($file);
        if ($self->apply($doc)) {
            open my $fh, '>', $file or die $!;
            print {$fh} $doc->serialize;
            close $fh;
        }
    }

    return 0;
}

sub apply {
    my ($self, $doc) = @_;

    $self->_apply_try_include($doc);
    $self->_apply_try_block($doc);
}

sub _apply_try_include {
    my ($self, $doc) = @_;

    my $includes = $doc->find(sub {
        my $t = $_[1];
        $t->isa('PPI::Statement::Include') && $t->module eq 'Try::Tiny'
    }) or return;

    for my $include (@$includes) {
        my $d = PPI::Document->new(\'use Syntax::Keyword::Try;');
        my $new_include = $d->child(0);
        $d->remove_child($new_include);
        $include->insert_after($new_include);
        $include->remove;
    }
}

sub _apply_try_block {
    my ($self, $doc) = @_;

    my $tries = $doc->find(sub {
        my $t = $_[1];
        $t->isa('PPI::Token::Word') && $t->content eq 'try'
    }) or return;

    for my $try (@$tries) {
        my @tokens = $try->parent->schildren;

        # Use eval instead of independent try block since Syntax::Keyword::Try doesn't allow
        #     my $x = try { ... };
        # ==> my $x = eval { ... };
        my $independent_try = !(grep { $_->isa('PPI::Token::Word') && $_->content =~ /^(?:catch|finally)$/ } @tokens);
        if ($independent_try) {
            $try->set_content('eval');
        } else {
            # Remove Try::Tiny's semicolon
            #     try { ... } catch { ... };
            # ==> try { ... } catch { ... }
            my $semicolon = $try->parent->last_token;
            $semicolon->remove;
        }

        # Replace $_ to $@
        # Note: Hard to understand $_ can be replaced or not
        my @blocks;
        for my $token (@tokens) {
            if ($token->isa('PPI::Token::Word') && $token->content =~ /^(?:catch|finally)$/) {
                my $block = $token->snext_sibling;
                if ($block->isa('PPI::Structure::Block')) {
                    $self->_replace_var($block);
                }
            }
        }
    }
}

sub _replace_var {
    my ($self, $elem) = @_;
    for my $child ($elem->schildren) {
        if ($child->isa('PPI::Node')) {
            $self->_replace_var($child);
        } elsif ($child->isa('PPI::Token::Magic') && $child->content eq '$_') {
            $child->set_content('$@');
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

App::try_tiny2syntax_keyword_try - Switch Try::Tiny to Syntax::Keyword::Try

=head1 SYNOPSIS

    % try_tiny2syntax_keyword_try lib/**/*.pm

=head1 DESCRIPTION

App::try_tiny2syntax_keyword_try is ...

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut

