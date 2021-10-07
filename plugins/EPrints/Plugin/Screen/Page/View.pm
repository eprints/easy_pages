package EPrints::Plugin::Screen::Page::View;

use EPrints::Plugin::Screen::Workflow::View;
@ISA = qw( EPrints::Plugin::Screen::Workflow::View );

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	$self->{icon} = "action_view.png";
	$self->{appears} = [ { place => "dummy", position => 1 } ];
	$self->{actions} = [qw/ /];

	return $self;
}


sub render_title
{
	my( $self ) = @_;
	my $dataobj = $self->{processor}->{dataobj};
        return $dataobj->render_citation( "summary_title" );
}

sub render
{
        my( $self ) = @_;

	my $dataobj = $self->{processor}->{dataobj};
        my $frag = $self->{session}->make_doc_fragment;

        $frag->appendChild( $dataobj->render_citation( "view" ) );
        $frag->appendChild( $self->render_common_action_buttons );

	return $frag;
}

1;
