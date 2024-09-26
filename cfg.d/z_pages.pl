use EPrints::DataObj::Page;

# set dependencies
$c->{deps}->{"ingredients/pages"} = [ "ingredients/richtext" ];

$c->{datasets}->{page} = {
  class => "EPrints::DataObj::Page",
  sqlname => "page",
};

push @{$c->{user_roles}->{user}}, qw{
  +page/view:owner
  +page/edit:owner
  +page/destroy:owner
  +page/history:owner
};

push @{$c->{user_roles}->{admin}}, qw{
  +page/create
  +page/view:editor
  +page/edit:editor
  +page/destroy:editor
  +page/history
};

$c->{plugins}{"Screen::Page::View"}{params}{disable} = 0;
$c->{plugins}{"Screen::Page::Edit"}{params}{disable} = 0;
$c->{plugins}{"Screen::Page::New"}{params}{disable} = 0;
$c->{plugins}{"Screen::Admin::PageCreate"}{params}{disable} = 0;

# Explicitly specify xapian indexing method
$c->{xapian}->{indexing_methods} = {} unless defined $c->{xapian}->{indexing_methods};
$c->{xapian}->{indexing_methods}->{'EPrints::MetaField::Page'} = 'text';

# Make all pages public
push @{$c->{public_roles}}, "+page/view";

# Redirect /page/nice-name to /id/page/x?nice-name
$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub
{
  my( %o ) = @_;

  if( $o{uri} =~ m|^$o{urlpath}/page/([^*]+)| || 
      $o{uri} =~ m|^$o{urlpath}/(information\|policies\|contact).html| ||
      $o{uri} =~ m|^$o{urlpath}/(help)/?$|i )
  {
    my $path = EPrints::DataObj::Page::tidy_path( $1 ); 
    my $session = new EPrints::Session;
    my $ds = $session->dataset( "page" );
    my $searchexp = new EPrints::Search( session=>$session, dataset=>$ds );
    $searchexp->add_field( $ds->get_field( "path" ), $path, "EQ" );
    my $results = $searchexp->perform_search;

    if ( $results->count() == 1 )
    {
      $id = $results->item(0)->get_id;
      ${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, $o{urlpath}."/id/page/$id?$path" );
      return EP_TRIGGER_DONE;
    }
    elsif( $results->count() > 1 )
    {
      ${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, $o{urlpath}."/cgi/pages.search?path=$path" );
      return EP_TRIGGER_DONE;
    }
  }

  # redirect to our own View screen
  if( $o{args} =~ m|^\?screen=Workflow%3A%3AView&dataset=page&dataobj=| )
  {
    $o{args} =~ s/screen=Workflow/screen=Page/;
    ${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, $o{urlpath}.$o{args} );
    return EP_TRIGGER_DONE;  
  }

}, id => 'easy_pages_nice_url_redirect' );

######################################################################
#
# =pod Description for $c->{get_easy_page_substitutions}
#
# =over
#
# =item $repository->config('get_easy_page_substitutions')->($class_name, $repository)
#
# Requires C<$repository>.
# Returns an array of substitutions in array context,
# or an arrayref of substitutions otherwise.
# Substitutions would ideally be an object attribute,
# rather than being defined in this getter,
# and are intended for use by EPrints::DataObj::Page's
# put_here method/subroutine.
#
# =cut
#
######################################################################

$c->{get_easy_page_substitutions} = sub
{
    my  $class_name         =   shift;  # Only a string - not a blessed object
                                        # - so no $repository available from it.
    my  $repository         =   shift;  # Subsequently, $repository needs to be passed in.

    my  @static_folder         =   (
        path                =>  "static",
        scheme              =>  "https",
        host                =>  1,
    );

    my  $static_folder      =   $repository->get_url(@static_folder)
                                ->abs(
                                    $repository->config('base_url')
                                );
                                # Upgrade cgi folder to relevant scheme
                                # as per settings in @cgi_folder array.

# The commented out approach of path => 'cgi'
# only works when https_cgiroot or http_cgiroot are defined in config,
# and has been commented out and  only perl_url is defined in config,
# with a comment saying the base url configs such as perl_url should be depreciated.
#    my  @cgi_folder         =   (
#        path                =>  "cgi",
#        scheme              =>  "https",
#        host                =>  1,
#    );

    my  $cgi_folder         =   $repository->get_url(@static_folder)
                                ->abs(
                                    $repository->config('base_url')
                                )->as_string.
                                '/cgi';
                                # Literally appending the string '/cgi'
                                # to the end of the static url.

    # The Substitutions we are getting...
    my  @values_in_order    =   (
        'ADMIN-EMAIL'       =>  $repository->config('adminemail'),
        'ARCHIVE-NAME'      =>  $repository->html_phrase('archive_name')->toString,
        'ARCHIVE-URL'       =>  $static_folder->as_string,  # Assuming static folder is root!
                                                            # Is it always?
                                                            # Am I better off getting secure host from config?
        'CGI-URL'           =>  $cgi_folder,
    );

    return                      wantarray?  @values_in_order:
                                \@values_in_order;
};

$c->{set_page_automatic_fields} = sub
{
  my( $page ) = @_;

  if( !$page->is_set( "path" ) )
  {
    $page->set_value(
        "path",
        EPrints::DataObj::Page::tidy_path(
            EPrints::DataObj::Page->put_here(
                $page->repository,
                $page->get_value( "title" ),
            )
        )
    );
  }
  else
  {
    my $path = $page->get_value( "path" );
    my $tidy_path = EPrints::DataObj::Page::tidy_path( $path );
    $page->set_value( "path", $tidy_path ) if $path ne $tidy_path;
  }

};
