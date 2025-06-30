package EPrints::DataObj::Page;

use EPrints;
use EPrints::DataObj;
use EPrints::DataObj::RichDataObj;
use EPrints::MetaField::Page;
use Text::Unidecode;

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
    { name => "title", type => "text", required => 1, input_cols => 80, sql_index => 1, render_single_value => "EPrints::DataObj::Page::page_render_text" },
    { name => "language", type => "namedset", required => 1, input_rows => 1, set_name => "languages"},
    { name => "path", type => "text", required => 0, input_cols => 80, sql_index => 1, render_single_value => "EPrints::DataObj::Page::page_render_path" },
    { name => "payload",
      type => "richtext",
      required => 0,
      render_single_value => sub { $class->render_single_value(@_) },
      #render_input => sub { $class->render_input_field_actual(@_) }, # Not this class.
      render_input => "EPrints::MetaField::Page::render_input_field_actual",
    },
  );
}

sub create_page
{
  my( $class, $repository, $data ) = @_;

  my $page = $class->create_from_data( $repository, $data );

  return $page;
}

sub delete_page
{
  my( $self, $repository ) = @_;

  $self->delete;
}

sub render_single_value
{
  my( $class_name, $repository, $value, $page_string ) = @_;

  if( !defined $page_string ) { return $repository->make_doc_fragment; }    # Why set an xhtml object as a default/fallback value for a string?
                                                                            # Shouldn't $dom fall back to this,
                                                                            # if XML::LibXML->load_html throws an exception (to be caught by an eval?).
  my $dom = XML::LibXML->load_html(
    string => $class_name->put_here($repository, $page_string),
    recover => 2,
  );

  my @nodelist = $dom->getElementsByTagName("body");
  my $body = $nodelist[0];

  return $body;
}

=pod Description

=over

=item $class_name->get_substitutions($repository)

Requires C<$repository>.
Returns an array of substitutions in array context,
or an arrayref of substitutions otherwise.
Substitutions would ideally be an object attribute,
rather than being defined in this getter,
and are intended for use by the
L<< /"$class_name->put_here($repository, $text, 'PLACEHOLDER-TEXT' => 'replacement text')" >>
subroutine.

=cut


sub get_substitutions {
    my  $class_name         =   shift;  # Only a string - not a blessed object
                                        # - so no $repository available from it.
    my  $repository         =   shift;  # Subsequently, $repository needs to be passed in.

    return  $repository->config('get_easy_page_substitutions')->($class_name, $repository); # substitutions set at archive level config - see cfg.d/z_pages.pl
}


=pod Description

=item $class_name->put_here($repository, $text, 'PLACEHOLDER-TEXT' => 'replacement text')

Takes a $repository or $session
because these cannot be retrieved from a non-blessed class name string,
and then takes a $text template with C<< PUT-PLACEHOLDER-TEXT-HERE >> placemarkers,
followed by C<< 'PLACEHOLDER-TEXT' => 'replacement text' >> key value pairs.

Finds placeholders and replaces them with values.

Returns a copy of the $text template, with the values put in place.

=back

=cut

sub put_here {

    #Initial values:
    my  $class_name         =   shift;
    my  $repository         =   shift;
    my  $text               =   shift;
    my  @values_in_order    =   @_;
        @values_in_order    =   $class_name->get_substitutions($repository) unless @values_in_order;
        @values_in_order    =   () unless @values_in_order;
    my  %values             =   @values_in_order;

    #For each value in order of array...
    foreach my $current_value (@values_in_order) {

        $repository->log(
            '[EPrints::DataObj::Page::put_here] - '.
            'Current value undefined warning: '.
            "$text. taking values: ".
            EPrints->dump(@values_in_order)
        ) unless defined($current_value);

        #If current value is a hash key...
        if (exists $values{$current_value}) {

            my  $placeholder=   $current_value;

            my  $find       =   qr/PUT-$placeholder-HERE/;

            my  $replace    =   $values{$placeholder};

            #Find and Replace within Text:
            $text           =~  s/$find/$replace/g;

        }

    };

    #Return the final result:
    return $text;

}

sub tidy_path
{
  my( $path ) = @_;

  my ( $tidy ) = ( $path =~ /(^.{1,100})/ );

  # converts non-ASCII characters into their nearest equivalent, e.g. stripping accents
  $tidy = unidecode( $tidy );

  $tidy =~ s/[^ a-zA-Z0-9-]+//g;
  $tidy =~ s/ /-/g;

  # unidecode can leave us with some extra dashes - tidy them up
  $tidy =~ s/--/-/g;
  $tidy =~ s/-$//g;

  $tidy = lc( $tidy );

  return $tidy;
}

sub page_render_path
{
  my( $repository, $field, $value, $page ) = @_;

  my $link = $repository->make_element( "a", href => "/page/" . $value );
  $link->appendChild(
    $repository->make_text(
        EPrints::DataObj::Page->put_here(
            $repository,
            $page->get_value( "title" ),
        )
    )
  );

  return $link;
}

sub page_render_text
{

  my( $repository, $field, $value, $page ) = @_;

  return $repository->make_text(
    EPrints::DataObj::Page->put_here(
        $repository,
        $page->get_value( "title" ),
    )
  );

}

1;
