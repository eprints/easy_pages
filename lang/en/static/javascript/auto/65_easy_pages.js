
// Called by EPrints::MetaField::Page::render_input_field_actual
var initTinyMCE_for_easy_pages = function(id,replacements, preview_substitutions){

        tinymce.init({

            // Setup:
            setup: function (ed) {
                ed.on(

                    // On Initialisation:
                    'init', function (e) {

                        // Switch to default font on load:
                        ed.execCommand("fontName", false, "HelveticaNeueLTPro-Roman");
                        this.getDoc().body.style.fontFamily = 'HelveticaNeueLTPro-Roman';

                    }
                );
            },

            // General:
            selector: id,
            resize: 'both',
            height: 500,
            width: 700,
            //cache_suffix: '?'+ new Date().getTime(), // Doesn't appear to work with 4.6.1 so commented out in favour of manually adding to the end of content_css further below.
            relative_urls : true,
            //document_base_url : 'http://example.eprints.org/', - as a value unique to each repository, this should be passed in or commented out/left at default.

            // Functionality:
            plugins: [
                'advlist autolink lists link image charmap print anchor',
                'searchreplace visualblocks code fullscreen', // unique preview variation.
                'insertdatetime media table contextmenu paste code textpattern', // textpattern 4.9.1 not in richtext ingredient
                                                                                 // and so added with/alongside easy_pages implementation
            ],

            // Custom values for preview_with
            preview_substitutions: preview_substitutions,
            preview_data_uri_embedded_fonts: '/style/easy_pages_preview_data_uri_embedded_fonts.css?'+ new Date().getTime(),
            //preview_substitutions, //shorthand for - preview_substitutions: preview_substitutions, 

            // Styling:
            content_css:    [
                                '/style/auto.css?'+ new Date().getTime(),
				'/style/easy_pages_imports.css?'+ new Date().getTime(),
                            ],
            //font_css: ['/style/easy-pages-fonts.css'], // Can put @font-face statements here instead of relying on those in main.min.css if desired.

            // Get rid of blue outlines around text you are entering.
            inline_boundaries: false,
            content_style:  ".mce-container {"+
                               "border: 0px !important;"+
                            "}"+
                            "* [contentEditable='true']:focus"+
                            "{ outline-style: none ; }",


            // Fonts available to use/select from UI:
            font_formats:   "Regular HelveticaNeue LT Pro='HelveticaNeueLTPro-Roman',helvetica;"+
                            "Italic HelveticaNeue LT Pro='HelveticaNeueLTPro-It';"+
                            "Bold HelveticaNeue LT Pro='HelveticaNeueLTPro-Bd';"+
                            "Bold Italic HelveticaNeue LT Pro='HelveticaNeueLTPro-BdIt';"+
                            "Generic Sans-Serif Family Font=sans-serif;",

            // UI:
            menubar: 'edit insert view format table tools',
            toolbar: 'undo redo | insert | styleselect | bold italic | fontselect fontsizeselect | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image | code',
            link_list: [
                {title: 'PUT-ARCHIVE-NAME-HERE', value: 'PUT-ARCHIVE-URL-HERE'},
                {title: 'PUT-ADMIN-EMAIL-HERE', value: 'PUT-ADMIN-EMAIL-HERE'},
            ],

            // Find and replace patterns
            textpattern_patterns: [

                // Use find and replace values declared here:
                //{start: 'INSTANTLY-INSERT-SOMETHING-HERE', replacement: 'something'},

                // Use values sent from Perl
                //  - i.e. where
                //  my %replacements = ( 'INSTANTLY-INSERT-THE-VALUE-FOR-THIS-KEY' => 'something' );
                //{start: 'INSTANTLY-INSERT-THE-VALUE-FOR-THIS-KEY', replacement: replacements['INSTANTLY-INSERT-THE-VALUE-FOR-THIS-KEY']},
                {start: 'INSTANT-ADMIN-EMAIL-LINK', replacement: replacements['INSTANT-ADMIN-EMAIL-LINK']},
                {start: 'INSTANT-ARCHIVE-LINK', replacement: replacements['INSTANT-ARCHIVE-LINK']},
            ]

        });
};
