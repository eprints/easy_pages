$c->add_dataset_trigger( 'page', EP_TRIGGER_DEFAULTS, sub {
	my( %params ) = @_;
	my $repo = $params{repository};

	# Default language is the current language
	$params{data}->{language} = $repo->get_langid();
});

