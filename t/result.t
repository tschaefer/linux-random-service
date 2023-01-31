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
  $t->get_ok('/random/job/result')->status_is(404, 'Bad request: missing job id path')->json_is(
    '' => {"error" => "no such endpoint", "method" => "GET", "url" => "\/random\/job\/result"},
    'Bad request: error JSON object'
  );

  $t->get_ok('/random/job/result/job')->status_is(400, 'Bad request: invalid job id path (non-numeric)')
    ->json_is('' => {"error" => "job id is invalid", "id" => "job"}, 'Bad request: error JSON object');

  $t->get_ok('/random/job/result/0')->status_is(400, 'Bad request: invalid job id path (null)')
    ->json_is('' => {"error" => "job id is invalid", "id" => "0"}, 'Bad request: error JSON object');

  $t->get_ok('/random/job/result/1')->status_is(404, 'Bad request: non-existent job id')
    ->json_is('' => {"error" => "job not found", "id" => 1}, 'Bad request: error JSON object');
};

subtest 'Valid request' => sub {
  $t->post_ok('/random/job/enqueue?bytes=128')->status_is(201, 'Enqueue job');
  $t->app->minion->perform_jobs;
  $t->get_ok('/random/job/result/1')->status_is(200, 'Valid request: job result')->json_like(
    '/result' => qr/----BEGIN RANDOM DATA-----[0-9a-zA-Z\/\+=\s\S]+-----END RANDOM DATA-----/,
    'Valid request: job result JSON object'
  );
};

$s->teardown;

done_testing();
