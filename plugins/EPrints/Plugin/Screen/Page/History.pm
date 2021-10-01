package EPrints::Plugin::Screen::Page::History;

our @ISA = ( 'EPrints::Plugin::Screen::HistorySingleItem' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);
        $self->{title_phrase} = __PACKAGE__ . ":title";

        $self->{datasetid} = "page";
	# print STDERR "EPrints::Plugin::Screen::Page::History:new\n";

        return $self;
}

1;
