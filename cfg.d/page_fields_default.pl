
$c->{set_page_defaults} = sub {
    my ( $page, $repository, $parent ) = @_;

    #default language is the current language
    $page->{language} = $repository->get_langid();
};
