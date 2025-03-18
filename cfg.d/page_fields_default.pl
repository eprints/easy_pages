
$c->{set_page_defaults} = sub 
{
	my( $page, $repository, $parent ) = @_;

	$page->{language} = $repository->get_langid();
};

