######################################################################
#
# EPrints::MetaField::Page;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Page> - Input Field Rendering for Easy Pages.

=head1 DESCRIPTION

Input Field Rendering for Easy Pages. Modified from Rich Text ingredient original.

=cut

package EPrints::MetaField::Page;

use strict;
use warnings;
use English qw( -no_match_vars );

BEGIN
{
    our( @ISA );

    @ISA = qw( EPrints::MetaField::Longtext );
}

use EPrints::MetaField::Longtext;

sub render_input_field_actual
{
    my( $self, $repository, $value, $dataset, $staff, $hidden_fields, $obj, $basename ) = @_;

    my  $frag                       =   $self->SUPER::render_input_field_actual( @_[1..$#_] );

    my  %replacements               =   (
        # Provide any hash data desired for use with TinyMCE textpattern plugin.
        'INSTANT-ADMIN-EMAIL-LINK'  =>  $repository->html_phrase('EPrints/MetaField/Page:render_input_field_actual:replacements:instant_admin_email_link')->toString,
        'INSTANT-ARCHIVE-LINK'      =>  $repository->html_phrase('EPrints/MetaField/Page:render_input_field_actual:replacements:instant_archive_link')->toString,
    );
    
    my  %preview_substitutions      =   EPrints::DataObj::Page->get_substitutions($repository);
    #$repository->log(
    #    '[EPrints::MetaField::Page::render_input_field_actual] - '.
    #    'Substitutions are...'.
    #    "\n".
    #    EPrints->dump(%substitutions)
    #);
    #warn 'Subs:'.EPrints->dump(join "",%substitutions);
    #EPrints->abort('Premature end.');

    $frag->appendChild( $repository->make_element( "script", src=> "/javascript/tinymce.min.js" ) );
    $frag->appendChild(
        $repository->make_javascript("
document.addEventListener('DOMContentLoaded', () => {
    initTinyMCE_for_easy_pages(
        '#$basename',
        {" .
            # Javascript object with attributes based on %replacements or empty
            ( %replacements ? join ( ',', map { "'$ARG': '$replacements{$ARG}'" } (keys %replacements) ) : q{} ) .
        "},
        {" .
            # Javascript object with attributes based on %preview_substitutions or empty
            ( %preview_substitutions ? join( ',', map { "'$ARG': '$preview_substitutions{$ARG}'" } (keys %preview_substitutions) ) : q{} ) .
        "}
    );
});"
        )
    );

    return $frag;
}

######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README https://github.com/eprints/easy_pages for further information.

Easy Pages ingredient is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
