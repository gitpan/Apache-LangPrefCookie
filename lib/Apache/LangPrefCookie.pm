# $Id: LangPrefCookie.pm,v 1.11 2005/12/22 16:03:43 c10232 Exp $
package Apache::LangPrefCookie;

use strict;
use warnings;

use Apache::Constants qw(OK DECLINED);
use Apache::Request;
use Apache::Cookie;

our $VERSION = '0.05';

sub handler {
    my $r = Apache::Request->new(shift);
    my %cookies = Apache::Cookie->new($r)->parse;
    my $cookie_name = $r->dir_config('LangPrefCookieName') || 'prefer-language';
    my @ua_lang_prefs;

    # $r->log->debug("Looking for cookie: \"$cookie_name\"");

    # if we have no cookie, this is none of our business
    return DECLINED unless exists $cookies{$cookie_name}
      and my $cookie_pref_lang = $cookies{$cookie_name}->value();

    # dont parse an empty header just to get "Use of uninitialized value in" warnings
    if (defined $r->header_in("Accept-Language") and length $r->header_in("Accept-Language")) {
        @ua_lang_prefs = parse_accept_language_header($r->header_in("Accept-Language"));
    }
    else {
        # RFC 2616 states:
        # "If no Accept-Language header is present in the request, the server
        #  SHOULD assume that all languages are equally acceptable."
        # Since we still are going to build one, respect the original demand
        # by inserting '*'.
        @ua_lang_prefs = q/*/;
    }

    # Now: unless the cookie wants a language that would be the
    # best matching anyway, rebuild the list of language-ranges
    unless ($cookie_pref_lang eq $ua_lang_prefs[0]) {
        my ($qvalue, $language_ranges) = (1, '');
        map {
            if (m/^(?:\w{1,8}(?:-\w{1,8})*$|\*)/) {
                $language_ranges .= "$_;q=$qvalue, ";
                $qvalue *= .9;
            }
        } ($cookie_pref_lang, @ua_lang_prefs);
        $language_ranges =~ s/,\s*$//;
        return DECLINED unless length $language_ranges;
        $r->header_in("Accept-Language", $language_ranges);
        $r->log->debug("Cookie \"$cookie_name\" requested \"$cookie_pref_lang\", set \"Accept-Language: $language_ranges\"");
    }
    return OK;
}

# taken and modified from Philippe M. Chiasson's Apache::Language
# returns a sorted (from most to least acceptable) list of languages
sub parse_accept_language_header {
    my $language_ranges = shift;
    my $value = 1;
    my %pairs;
    foreach (split(/,/, $language_ranges)) {
        s/\s//g;            #strip spaces
        next unless length;
        if (m/;q=([\d\.]+)/) {
            #is it in the "en;q=0.4" form ?
            $pairs{lc $`}=$1 if $1 > 0;
        }
        else {
            #give the first one a q of 1
            $pairs{lc $_} = $value;
            #and the others .001 less every time
            $value -= 0.001;
        }
    }
    return sort {$pairs{$b} <=> $pairs{$a}} keys %pairs;
}

1;
__END__

=head1 NAME

Apache::LangPrefCookie - Override the request's Accept-Language HTTP-Header
with a preference provided by a Cookie.

=head1 SYNOPSIS

  PerlInitHandler  Apache::LangPrefCookie

  # optionally set a custom cookie-name, default is "prefer-language"
  PerlSetVar LangPrefCookieName "mypref"

  <Location /foo>
     # This also work inside container directives. But you might not get
     # what you want if you set it *both* in- and outside containers.
     PerlInitHandler  Apache::LangPrefCookie
     PerlSetVar LangPrefCookieName "foo-pref"
  <Location>


=head1 DESCRIPTION

This Module looks for a cookie providing a language-code as its
value. This preference is then squished into httpd's idea of the
C<Accept-Language> header as if the Client had asked for it as #1
choice. The original preferences are still present, albeit with lowered
q-values.  F<Apache::LangPrefCookie> leaves the task to
set/modify/delete such a cookie to I<you>, it just consumes it
:-). However, the cookie's name is configurable, as described in the
Example below.

Its then up to httpd's mod_negotiation to choose the best deliverable
representation.

=head2 WHY?

We are cheating on RFC-2626 with this. I have somewhat ambivalent
feelings towards that, so bear with me for some words of justification:

In theory a user-agent should help its users to set a reasonable choice
of language(s). In practice, the dialog is hidden in the 3rd level of
some menu, maybe even misguiding the user in his selections. (See
L<http://ppewww.ph.gla.ac.uk/~flavell/www/lang-neg.html>, especially the
section I<Language subset selections> for examples.) But this is
probably the wrong place to rant over this.

I dislike solutions involving virtual paths, as they lengthen some and
generally increase the number of URIs for a given resource.  (See
L<http://www.w3.org/TR/2004/WD-webarch-20040705/#avoid-uri-aliases>).

There might be demand to switch for a given site once (not for every single
document as with explicit links to the other language variants of the
page in question, which still works despite our cookie, by the way),
without touching the browsers configuration. There also are scenarios
where one wants to let users express a different preference just for
certain realms within one site.

This approach would work with all Accept* headers. I decided against
implementing a general solution for all of them, because (1) I want to
keep this as focused and simple as possible and (2) I just don't see a
real need for it.

The bottom-line: This Module might be useful to scratch a specific itch,
if, and only if there is one ;-)

=head1 EXAMPLE COOKIE

C<prefer-language=x-klingon;expires=Saturday 31-Dec-05 24:00:00 GMT;path=/>

Optionally, the default cookie name C<prefer-language> can be overridden
by setting the C<LangPrefCookieName> variable:

C<PerlSetVar LangPrefCookieName "mypref">

C<mypref=x-klingon;expires=Saturday 31-Dec-05 24:00:00 GMT;path=/>

=head1 BUGS

=over

=item *

I haven't even looked into mod_perl2 yet, so this module might not work
with it.

=item *

This should be a native C module for httpd.

=item *

Apart from these: This is first public release, so I'm not aware
of any other bugs at this time.

=back

=head1 SEE ALSO

L<mod_perl(3)>

L<http://httpd.apache.org/docs/1.3/content-negotiation.html>

L<http://httpd.apache.org/docs/1.3/mod/mod_negotiation.html>

L<http://ppewww.ph.gla.ac.uk/~flavell/www/lang-neg.html>

L<http://www.w3.org/TR/2004/WD-webarch-20040705/#avoid-uri-aliases>

=head1 AUTHOR

Hansjoerg Pehofer, E<lt>hansjoerg.pehofer@uibk.ac.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Hansjoerg Pehofer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
