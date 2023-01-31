use Mojo::Base -strict;

use Test::More;

# RANDOM_SERVICE_TEST_DB=postgres://bender:rocks@127.0.0.1:5432/random_test
plan skip_all => 'set RANDOM_SERVICE_TEST_DB to enable this test' if !$ENV{RANDOM_SERVICE_TEST_DB};

use FindBin;
use lib "$FindBin::Bin/lib";

use Mock::Linux::Random::Service;

my $s = Mock::Linux::Random::Service->new;
my $t = $s->setup;

subtest 'Bad request' => sub {
  $t->post_ok('/random/job/enqueue')->status_is(400, 'Bad request: missing bytes parameter')->json_is(
    '' => {"bytes" => undef, "error" => "requested param bytes is invalid"},
    'Bad request: error JSON object'
  );

  $t->post_ok('/random/job/enqueue?bytes=five')->status_is(400, 'Bad request: invalid bytes parameter (non-numeric)')
    ->json_is(
    '' => {"bytes" => "five", "error" => "requested param bytes is invalid"},
    'Bad request: error JSON object'
    );

  $t->post_ok('/random/job/enqueue?bytes=-5')->status_is(400, 'Bad request: invalid bytes parameter (negative number)')
    ->json_is('' => {"bytes" => "-5", "error" => "requested param bytes is invalid"}, 'Bad request: error JSON object');

  $t->post_ok('/random/job/enqueue?bytes=Inf')->status_is(400, 'Bad request: invalid bytes parameter (infinity)')
    ->json_is(
    '' => {"bytes" => "Inf", "error" => "requested param bytes is invalid"},
    'Bad request: error JSON object'
    );

  $t->post_ok('/random/job/enqueue?bytes=-Inf')
    ->status_is(400, 'Bad request: invalid bytes parameter (negative infinity)')->json_is(
    '' => {"bytes" => "-Inf", "error" => "requested param bytes is invalid"},
    'Bad request: error JSON object'
    );

  $t->post_ok('/random/job/enqueue?bytes=127')->status_is(400, 'Bad request: invalid bytes parameter (too small)')
    ->json_is(
    '' => {"bytes" => "127", "error" => "requested param bytes is invalid"},
    'Bad request: error JSON object'
    );

  $t->post_ok('/random/job/enqueue?bytes=10485761')->status_is(400, 'Bad request: invalid bytes parameter (too big)')
    ->json_is(
    '' => {"bytes" => "10485761", "error" => "requested param bytes is invalid"},
    'Bad request: error JSON object'
    );
};

subtest 'Valid Request' => sub {
  $t->post_ok('/random/job/enqueue?bytes=128')->status_is(201, 'Valid request: valid bytes parameter (minimum size)')
    ->json_is('' => {"id" => 1}, 'Valid request: JSON object');

  $t->post_ok('/random/job/enqueue?bytes=10485760')
    ->status_is(201, 'Valid request: valid bytes parameter (maximum size)')
    ->json_is('' => {"id" => 2}, 'Valid request: JSON object');

  $t->post_ok('/random/job/enqueue?bytes=4096')->status_is(201, 'Valid request: valid bytes parameter (typical size)')
    ->json_is('' => {"id" => 3}, 'Valid request: JSON object');
};

$s->teardown;

done_testing();
