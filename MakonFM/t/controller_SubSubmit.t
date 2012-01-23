use strict;
use warnings;
use Test::More;


use Catalyst::Test 'MakonFM';
use MakonFM::Controller::SubSubmit;

ok( request('/subsubmit')->is_success, 'Request should succeed' );
done_testing();
