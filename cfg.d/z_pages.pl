use EPrints::DataObj::Page;
use EPrints::Const qw( OK DONE DECLINED NOT_FOUND );

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

# Redirect hardcoded html links and old CRUD links to easy pages
$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub
{
  my( %o ) = @_;
  if( $o{uri} =~ m|^$o{urlpath}/(information\|policies\|contact).html| )
  {
    my $path = EPrints::DataObj::Page::tidy_path( $1 ); 
    my $session = new EPrints::Session;
    my $ds = $session->dataset( "page" );
    my $searchexp = new EPrints::Search( session=>$session, dataset=>$ds );
    $searchexp->add_field( $ds->get_field( "path" ), $path, "EQ" );
    my $results = $searchexp->perform_search;

    if ( $results->count() >= 1 )
    {
      $id = $results->item(0)->get_id;

      ${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, $o{urlpath}."/page/$path" );
      return EP_TRIGGER_DONE;
    }
  }

  if( $o{uri} =~ m|^$o{urlpath}/id/page/([^*]+)| )
  {
    my $id = EPrints::DataObj::Page::tidy_path( $1 ); 
    my $session = new EPrints::Session;
    my $ds = $session->dataset( "page" );
    my $searchexp = new EPrints::Search( session=>$session, dataset=>$ds );
    $searchexp->add_field( $ds->get_field( "pageid" ), $id, "EQ" );
    my $results = $searchexp->perform_search;

    if ( $results->count() >= 1 )
    {
      my $path = $results->item(0)->get_value("path");
      ${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, $o{urlpath}."/page/$path" );
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

sub best_language {
  # logic mirroring language selection in get_session_language:
  # make array of langauges is preferred order (best first)
  # then find the first one that matches
    my ( $languages, $results ) = @_;
    foreach my $pref_lang (@$languages) {
        for ( my $i = 0 ; $i < $results->count ; $i++ ) {

            my $language = $results->item($i)->get_value("language");
            
            if ( $language eq $pref_lang ) {
                return $results->item($i)->get_id;
            }

        }
    }
  # can't find a good match, but any of these results are better than nothing
  return $results->item(0)->get_id;
}

# instead of /id/page/[id]?path, hide this away and just have /page/path
# and choose the best available page for the current langauge.
$c->{custom_handlers}->{easy_pages}->{regex} = '^URLPATH/page/([^*]+)';
$c->{custom_handlers}->{easy_pages}->{function} = sub
{
	my ( $r ) = @_;
  
  my $session = new EPrints::Session;
	exit( 0 ) unless( defined $session );
 

  my $current_url = $session->current_url;

  if ($current_url =~ m|/page/([^*]+)|){
    
    my $path = EPrints::DataObj::Page::tidy_path( $1 ); 
    # my $session = new EPrints::Session;
    my $ds = $session->dataset( "page" );
    my $searchexp = new EPrints::Search( session=>$session, dataset=>$ds );
    $searchexp->add_field( $ds->get_field( "path" ), $path, "EQ" );
    my $results = $searchexp->perform_search;

    if ( $results->count() >= 1 )
    {
      my $id = $results->item(0)->get_id;
      if ($results->count == 1){
        # only one page for this path, so we'll have to present that one
        $id = $results->item(0)->get_id;
      }else{
        # multiple results for this path - assume this is because they're multiple languages

        my $eprints = EPrints->new;
        my $repository = $eprints->current_repository();
        exit( 0 ) unless( defined $repository );

        my @prefs;
        my $current_language = $repository->get_session_language( $repository->{request} );
        my $default_langauge = $repository->get_conf( "defaultlanguage" );
        
        push @prefs, $current_language;
        push @prefs, $default_langauge if $default_langauge ne $current_language;

        $id = &best_language(\@prefs, $results);
        
        }


      my $repository = $EPrints::HANDLE->current_repository();
      my $crud = EPrints::Apache::CRUD->new(
				repository => $repository,
				request => $r,
				datasetid => "page",
				dataobjid => $id,
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
    return NOT_FOUND;
  }
};