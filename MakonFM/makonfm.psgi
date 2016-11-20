use strict;
use warnings;

use MakonFM;

my $app = MakonFM->apply_default_middlewares(MakonFM->psgi_app);
$app;

