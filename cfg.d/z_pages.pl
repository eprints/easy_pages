use EPrints::DataObj::Page;
use EPrints::Const qw( OK DONE DECLINED NOT_FOUND );

# set dependencies
$c->{deps}->{"ingredients/pages"} = ["ingredients/richtext"];

$c->{datasets}->{page} = {
    class   => "EPrints::DataObj::Page",
    sqlname => "page",
};

push @{ $c->{user_roles}->{user} }, qw{
  +page/view:owner
  +page/edit:owner
  +page/destroy:owner
  +page/history:owner
};

push @{ $c->{user_roles}->{admin} }, qw{
  +page/create
  +page/view:editor
  +page/edit:editor
  +page/destroy:editor
  +page/history
};

$c->{plugins}{"Screen::Page::View"}{params}{disable}        = 0;
$c->{plugins}{"Screen::Page::Edit"}{params}{disable}        = 0;
$c->{plugins}{"Screen::Page::New"}{params}{disable}         = 0;
$c->{plugins}{"Screen::Admin::PageCreate"}{params}{disable} = 0;

# make all pages public
push @{ $c->{public_roles} }, "+page/view";

# Explicitly specify xapian indexing method
$c->{xapian}->{indexing_methods} = {} unless defined $c->{xapian}->{indexing_methods};
$c->{xapian}->{indexing_methods}->{'EPrints::MetaField::Page'} = 'text';

$c->{set_page_automatic_fields} = sub {
    my ($page) = @_;

    if ( !$page->is_set("path") ) {
        $page->set_value( "path",
            EPrints::DataObj::Page::tidy_path( $page->get_value("title") ) );
    }
    else {
        my $path      = $page->get_value("path");
        my $tidy_path = EPrints::DataObj::Page::tidy_path($path);
        $page->set_value( "path", $tidy_path ) if $path ne $tidy_path;
    }
};

sub id_of_best_language {

    # logic mirroring language selection in get_session_language:
    # make array of languages is preferred order (best first)
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

# Redirect hardcoded html links and old CRUD links to easy pages
$c->add_trigger(
    EP_TRIGGER_URL_REWRITE,
    sub {
        my (%o) = @_;
        if ( $o{uri} =~ m|^$o{urlpath}/(information\|policies\|contact).html| || $o{uri} =~ m|^$o{urlpath}/(help)/?$|i )
        {
            my $path    = EPrints::DataObj::Page::tidy_path($1);
            my $session = new EPrints::Session;
            my $ds      = $session->dataset("page");
            my $searchexp =
              new EPrints::Search( session => $session, dataset => $ds );
            $searchexp->add_field( $ds->get_field("path"), $path, "EQ" );
            my $results = $searchexp->perform_search;

            if ( $results->count() >= 1 ) {
                $id = $results->item(0)->get_id;

                ${ $o{return_code} } =
                  EPrints::Apache::Rewrite::redir( $o{request},
                    $o{urlpath} . "/page/$path" );
                return EP_TRIGGER_DONE;
            }
        }

        if ( $o{uri} =~ m|^$o{urlpath}/id/page/([^*]+)| ) {
            my $id      = EPrints::DataObj::Page::tidy_path($1);
            my $session = new EPrints::Session;
            my $ds      = $session->dataset("page");
            my $searchexp =
              new EPrints::Search( session => $session, dataset => $ds );
            $searchexp->add_field( $ds->get_field("pageid"), $id, "EQ" );
            my $results = $searchexp->perform_search;

            if ( $results->count() >= 1 ) {
                my $path = $results->item(0)->get_value("path");
                ${ $o{return_code} } =
                  EPrints::Apache::Rewrite::redir( $o{request},
                    $o{urlpath} . "/page/$path" );
                return EP_TRIGGER_DONE;
            }
        }

        # redirect to our own View screen
        if ( $o{args} =~ m|^\?screen=Workflow%3A%3AView&dataset=page&dataobj=| )
        {
            $o{args} =~ s/screen=Workflow/screen=Page/;
            ${ $o{return_code} } = EPrints::Apache::Rewrite::redir( $o{request},
                $o{urlpath} . $o{args} );
            return EP_TRIGGER_DONE;
        }

    },
    id => 'easy_pages_nice_url_redirect'
);

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

# instead of /id/page/[id]?path, hide this away and just have /page/path
# and choose the best available page for the current language.
$c->{custom_handlers}->{easy_pages}->{regex}    = '^URLPATH/page/([^*]+)';
$c->{custom_handlers}->{easy_pages}->{function} = sub {
    my ($r) = @_;

    my $session = new EPrints::Session;
    exit(0) unless ( defined $session );

    my $current_url = $session->current_url;

    if ( $current_url =~ m|/page/([^*]+)| ) {

        my $path = EPrints::DataObj::Page::tidy_path($1);

        # my $session = new EPrints::Session;
        my $ds = $session->dataset("page");
        my $searchexp =
          new EPrints::Search( session => $session, dataset => $ds );
        $searchexp->add_field( $ds->get_field("path"), $path, "EQ" );
        my $results = $searchexp->perform_search;

        if ( $results->count() >= 1 ) {
            my $id = $results->item(0)->get_id;
            if ( $results->count == 1 ) {

                # only one page for this path, so we'll have to present that one
                $id = $results->item(0)->get_id;
            }
            else {

                # multiple results for this path - assume this is because they're multiple languages
                my $eprints    = EPrints->new;
                my $repository = $eprints->current_repository();
                exit(0) unless ( defined $repository );

                my @prefs;
                my $current_language =
                  $repository->get_session_language( $repository->{request} );

                # fetch the default language so we can prioritise that if the current language doesn't have a page, but there are multiple other languages to choose from.
                my $default_language = $repository->get_conf("defaultlanguage");

                push @prefs, $current_language;
                push @prefs, $default_language
                  if $default_language ne $current_language;

                $id = &id_of_best_language( \@prefs, $results );

            }

            my $repository = $EPrints::HANDLE->current_repository();
            my $crud       = EPrints::Apache::CRUD->new(
                repository => $repository,
                request    => $r,
                datasetid  => "page",
                dataobjid  => $id,
            );

            return $r->status if !defined $crud;

            $r->handler('perl-script');

            $r->set_handlers( PerlMapToStorageHandler => sub { OK } );

            $r->push_handlers( PerlAccessHandler =>
                  [ sub { $crud->authen }, sub { $crud->authz }, ] );

            $r->set_handlers(
                PerlResponseHandler => [ sub { $crud->handler }, ] );

            return OK;
        }
        return NOT_FOUND;
    }
};

# Trigger to generate a warning if path and language aren't a unique combination
$c->add_trigger(
    EPrints::Const::EP_TRIGGER_VALIDATE_FIELD,
    sub {
        my (%args) = @_;
        my ( $repo, $field, $page, $value, $problems ) =
          @args{qw( repository field dataobj value problems )};

        return
             unless defined $page
          && $page->isa("EPrints::DataObj::Page")
          && $field->name eq "path";

        my $path = $page->get_value("path");
        my $language = $page->get_value("language");

        #this is a page and field is the path
        my $dataset = $repo->dataset("page");

        my $existing_this_lang_this_path = 0;

        $dataset->search->map(
            sub {
                my ( undef, undef, $search_page ) = @_;
                my $search_path = $search_page->get_value("path");
                my $search_language = $search_page->get_value("language");

                if ( defined $search_path && $search_path eq $path && $search_language eq $language) {

                    $existing_this_lang_this_path++;
                }

            }
        );

        if($existing_this_lang_this_path > 1){
            #greater than one because this page will already be in the search results
            #there already exists another page for this language on this path, so this page will never be seen
            push @$problems, $repo->html_phrase( "Plugin/Screen/Admin/PageCreate:path_already_exists",
                    path => $repo->make_text($path),
                    language => $repo->make_text($language));
        }
    },
    priority => 1000
);
