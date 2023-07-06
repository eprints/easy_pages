The 'easy_pages' ingredient is designed to extend EPrints 3.4 by adding a new 'page' dataset.\
The page dataobjects can be used to create HTML pages, as an alternative to creating XHTML and xpage files directly.\
Page content is entered via the rich text editor, TinyMCE, as supplied by the richtext ingredient.

Pages can be managed via Manage records -> Page.  This is limited to Admin users only.\
All created pages are public.  A list of pages can be accessed via /pages.html

In order to recreate the standard pages in easy pages, run the following bin script.\
`easy_pages/bin/create_standard_pages`\

If pages are created with the path set as `information`, `contact` or `policies` then the standard xpage versions of these pages will redirect to the easy page version automatically.

Authors:
- Justin Bradley, EPrints Services
- Edward Oakley, EPrints Services

EPrints 3.4 is supplied by EPrints Services.\
The files contained within this directory are all Copyright 2023 University of Southampton.
