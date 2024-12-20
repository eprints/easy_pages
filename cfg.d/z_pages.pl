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

# make all pages public
push @{$c->{public_roles}}, "+page/view";

# Redirect /page/nice-name to /id/page/x?nice-name
$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub
{
  my( %o ) = @_;

  if( $o{uri} =~ m|^$o{urlpath}/page/([^*]+)| || 
      $o{uri} =~ m|^$o{urlpath}/(information\|policies\|contact).html| )
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

      my $args  = $o{args};
         $args .= ( $args ) ? "&" : "?";
         $args .= $path;

      ${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, $o{urlpath}."/id/page/$id$args" );
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

$c->{set_page_automatic_fields} = sub
{
  my( $page ) = @_;

  if( !$page->is_set( "path" ) )
  {
    $page->set_value( "path", EPrints::DataObj::Page::tidy_path( $page->get_value( "title" ) ) );
  }
  else
  {
    my $path = $page->get_value( "path" );
    my $tidy_path = EPrints::DataObj::Page::tidy_path( $path );
    $page->set_value( "path", $tidy_path ) if $path ne $tidy_path;
  }

};
