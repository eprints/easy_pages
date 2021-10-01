package EPrints::DataObj::Page;

use EPrints;
use EPrints::DataObj;
use EPrints::DataObj::RichDataObj;

@ISA = ( 'EPrints::DataObj::RichDataObj' );

use strict;

sub get_dataset_id { "page" }

sub indexable { return 1; }

sub get_system_field_info
{
  my( $class ) = @_;

  return
  (
    { name => "pageid", type => "counter", sql_counter => "page", sql_index => 1 },
    { name => "rev_number", type => "int", required => 1, can_clone => 0, default_value => 1 },
    { name => "title", type => "text", required => 1, input_cols => 80, sql_index => 1 },
    { name => "path", type => "text", required => 0, input_cols => 80, sql_index => 1, render_single_value => "EPrints::DataObj::Page::page_render_path" },
    { name => "payload",
      type => "richtext",
      required => 0,
      render_single_value => "EPrints::DataObj::Page::render_single_value",
    },
  );
}

sub create_page
{
  my( $class, $session, $data ) = @_;

  my $page = $class->create_from_data( $session, $data );

  return $page;
}

sub delete_page
{
  my( $self, $session ) = @_;

  $self->delete;
}

sub render_single_value
{
  my( $self, $session, $value, $obj ) = @_;

  if( !defined $value ) { return $session->make_doc_fragment; }
  my $dom = XML::LibXML->load_html( string => $value, recover => 2 );

  my @nodelist = $dom->getElementsByTagName("body");
  my $body = $nodelist[0];

  return $body;
}

sub tidy_path
{
  my( $path ) = @_;

  my ( $tidy ) = ( $path =~ /(^.{1,100})/ );
  $tidy =~ s/[^ a-zA-Z0-9-]+//g;
  $tidy =~ s/ /-/g;
  $tidy = lc( $tidy );

  return $tidy;
}

sub page_render_path
{
  my( $session, $field, $value, $page ) = @_;

  my $link = $session->make_element( "a", href => "/page/" . $value );
  $link->appendChild( $session->make_text( $page->get_value( "title" ) ) );

  return $link;
}

1;
