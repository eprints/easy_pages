
$c->{set_page_defaults} = sub {
    my ( $page, $repository, $parent ) = @_;

    #default langauge is the current langauge
    $page->{language} = $repository->get_langid();
};
