=head1 NAME

EPrints::Plugin::Screen::Admin::PageCreate

=cut

package EPrints::Plugin::Screen::Admin::PageCreate;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ create_page /]; 

	$self->{appears} = [
		{ 
			place => "admin_actions_config",
			action => "create_page",
			position => 1400,
		},
	];

	return $self;
}

sub about_to_render
{
	my( $self ) = @_;
	$self->{processor}->{screenid} = "Admin";
}

sub allow_create_page
{
	my( $self ) = @_;

	return $self->allow( "page/create" );
}

sub action_create_page
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $dataset = $session->dataset( 'page' );
	my $data = {};

	$self->{processor}->{dataset} = $dataset;
	$self->{processor}->{dataobj} = $dataset->create_dataobj( $data );
	$self->{processor}->{screenid} = "Workflow::Edit";
}

1;
