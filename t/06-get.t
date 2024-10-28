use Test2::V0;
use WebService::Solr::Tiny;

my $solr = WebService::Solr::Tiny->new( agent => mock {} => add =>
        [ get => sub { $::req = pop; { content => '{}', success => 1 } } ] );

subtest 'Fetching documents but id' => sub {
    $solr->get( [1] );
    is $::req, 'http://localhost:8983/solr/get?id=1';

    $solr->get( [ 1 .. 3 ] );
    is $::req, 'http://localhost:8983/solr/get?id=1&id=2&id=3';

    $solr->get( ['UTF-8 FTW ☃'] );
    is $::req, 'http://localhost:8983/solr/get?id=UTF-8+FTW+%E2%98%83';

    $solr->get(
        [ 1 .. 30 ],
        debugQuery => 'true',
        fl         => 'id,name,price',
        fq         => [ 'popularity:[10 TO *]', 'section:0' ],
        omitHeader => 'true',
        rows       => 20,
        sort       => 'inStock desc, price asc',
        start      => 10,
    );

    is [ sort split /[?&]/, $::req ] => [
        qw[
            debugQuery=true
            fl=id%2Cname%2Cprice
            fq=popularity%3A%5B10+TO+*%5D
            fq=section%3A0
            http://localhost:8983/solr/get
        ],
        ( sort map {"id=$_"} ( 1 .. 30 ) ),
        qw[
            omitHeader=true
            rows=20
            sort=inStock+desc%2C+price+asc
            start=10
        ]
    ];

    $solr->get( ['A'] );
    is $::req, 'http://localhost:8983/solr/get?id=A';
    is $solr->{url}, 'http://localhost:8983/solr/select',
        'original endpoint is not changed';
};

subtest 'Execptions' => sub {
    like dies { $solr->get }, qr/Too few arguments/;

    like dies { $solr->get(undef) }, qr/Expected an array reference/;

    like dies { $solr->get(1) }, qr/Expected an array reference/;

    like dies { $solr->get( [] ) }, qr/Expected an array reference/;
};

done_testing;
