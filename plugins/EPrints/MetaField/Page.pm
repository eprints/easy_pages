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

    #$frag->appendChild( $repository->make_element( "script", src => "//code.jquery.com/jquery-1.12.4.js" ) );
    $frag->appendChild( $repository->make_element( "script", src=> "/javascript/tinymce.min.js" ) );
    $frag->appendChild(
        $repository->make_javascript(
            'jQuery( document ).ready('.
                'function($){ '.
                    'initTinyMCE_for_easy_pages('.

                        # Name/id of html element
                        # to become the TinyMCE input window
                        # - i.e. '#c3_payload'
                        # - requires hash prefix as added below:
                        '"#' . $basename .'",'.

                        # Javascript object with attributes based on %replacements or empty:
                        '{'.
                            (
                                %replacements?          join (
                                                            ',',
                                                            map { "'$ARG': '$replacements{$ARG}'" }
                                                            (keys %replacements)
                                                        ):
                                q{}
                            ).
                        '},'.
                        # Javascript object with attributes based on %preview_substitutions or empty:
                        '{'.
                            (
                                %preview_substitutions? join (
                                                            ',',
                                                            map { "'$ARG': '$preview_substitutions{$ARG}'" }
                                                            (keys %preview_substitutions)
                                                        ):
                                q{}
                            ).
                        '}'.
                    ');'.
                '}'.
            ');',
        )
    );

    return $frag;
}

######################################################################
1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2024 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

This software may be used with permission and must not be redistributed.
http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=head1 LICENSE

=for LICENSE BEGIN

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END

