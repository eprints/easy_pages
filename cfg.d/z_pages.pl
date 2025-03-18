use EPrints::DataObj::Page;
use EPrints::Const qw( OK DONE DECLINED );

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

# Redirect (information\|policies\|contact).html to /page/(information\|policies\|contact)
$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub
{
  my( %o ) = @_;

  if( #$o{uri} =~ m|^$o{urlpath}/page/([^*]+)| || 
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

      # ${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, $o{urlpath}."/id/page/$id$args" );
      ${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, $o{urlpath}."/page/$path" );
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

}, id => 'easy_pages_hardcoded_pages_redirect' );

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


$c->{custom_handlers}->{easy_pages}->{regex} = '^URLPATH/page/([^*]+)';
$c->{custom_handlers}->{easy_pages}->{function} = sub
{
	my ( $r ) = @_;
  
  my $session = new EPrints::Session;
	exit( 0 ) unless( defined $session );
  my $current_url = $session->current_url;
  print STDERR "current_url: $current_url\n";
  if ($current_url =~ m|/page/([^*]+)|){
    print STDERR "current_url matched: 1:$1 2:$2\n";
    my $path = EPrints::DataObj::Page::tidy_path( $1 ); 
    # my $session = new EPrints::Session;
    my $ds = $session->dataset( "page" );
    my $searchexp = new EPrints::Search( session=>$session, dataset=>$ds );
    $searchexp->add_field( $ds->get_field( "path" ), $path, "EQ" );
    my $results = $searchexp->perform_search;

    if ( $results->count() >= 1 )
    {
      my $repository = $EPrints::HANDLE->current_repository();
      my $id = $results->item(0)->get_id;
      my $crud = EPrints::Apache::CRUD->new(
				repository => $repository,
				request => $r,
				datasetid => "page",
				dataobjid => $id,
				# fieldid => $fieldid,
			);
    
    

      return $r->status if !defined $crud;

      $r->handler( 'perl-script' );

      $r->set_handlers( PerlMapToStorageHandler => sub { OK } );

      $r->push_handlers(PerlAccessHandler => [
          sub { $crud->authen },
          sub { $crud->authz },
        ] );

      $r->set_handlers( PerlResponseHandler => [
          sub { $crud->handler },
        ] );

      return OK;
    }


  }


# my $path = EPrints::DataObj::Page::tidy_path( $1 ); 
#     my $session = new EPrints::Session;
#     my $ds = $session->dataset( "page" );
#     my $searchexp = new EPrints::Search( session=>$session, dataset=>$ds );
#     $searchexp->add_field( $ds->get_field( "path" ), $path, "EQ" );
#     my $results = $searchexp->perform_search;

#     if ( $results->count() == 1 )
#     {




	# my $session = new EPrints::Session;
	# exit( 0 ) unless( defined $session );

	# my $cu = $session->current_url;
	# $cu =~ s|^/||;
	# my ( $id ) = split( "/", $cu ); 
	# return EPrints::Const::NOT_FOUND unless $id;

	# my $ds = $session->dataset( "eprint" );
	# my $eprint = $ds->dataobj( $id );
	# return EPrints::Const::NOT_FOUND unless $eprint;

	# return EPrints::Apache::Rewrite::redir( $r, $session->get_conf( "rel_path" ) .  "/" . $eprint->path );
};