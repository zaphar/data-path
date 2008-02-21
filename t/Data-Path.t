use Test::More tests => 18;
use Test::MockObject;

BEGIN {
    use lib qw(lib);
    use_ok('Data::Path')
};


my $hash=
    { scalar => 'scalar_value'
    , array  =>
        [ qw( array_value0 array_value1 array_value2 array_value3)
        ]
    , hash   =>
        {  hash1 => 'hash_value1'
        ,  hash2 => 'hash_value2'
        }
    , complex =>
        { level2 =>
            [ { level3_0 =>
                [ 'level4_0'
                , { level4_1 => { level5 => 'huhu' }
                  }
				, 'level4_2'
                ]
              }
            ]
        }
    , method => sub {return 'sub val';}

    };

my $a=Data::Path->new($hash);

ok ( $a );

my $v='';

$v=$a->get('/scalar');
ok ( $v eq 'scalar_value' , " value=$v");

$v=$a->get('/array[0]');
ok ( $v eq 'array_value0' , " value=$v");

$v=$a->get('/hash/hash1');
ok ( $v eq 'hash_value1'  , " value=$v");

$v=$a->get('/complex/level2[0]/level3_0[0]');
ok ( $v eq 'level4_0'     , " value=$v");

$v=$a->get('/complex/level2[0]/level3_0[2]');
ok ( $v eq 'level4_2'     , " value=$v");

$v=$a->get('/complex/level2[0]/level3_0[1]/level4_1/level5');
ok ( $v eq 'huhu' ," value=$v");

eval {
	$a->get('/complex/level2[99]/level3_0[1]/level4_1/level5');
};
ok ( $@ =~/does not exists/  ," check error_msg = $@");

eval {
	$a->get('/complex/level2[0]/level3_1[1]/level4_1/level5');
};
ok ( $@ =~/does not exists/  ," check error_msg = $@");

$v=$a->get('/complex/level2[0]/level3_0[1]/level4_1/level5_not_exists') || 'UNDEF';
ok ( $v eq 'UNDEF' ," value=$v");

$v=$a->get('/complex/level2[0]/level3_0[99]') || 'UNDEF';
ok ( $v eq 'UNDEF' ," value=$v");

$v=$a->get('/complex/level2[0]/level3_0[2]') || 'UNDEF';
ok ( $v eq 'level4_2' ," value=$v");


my $b=Data::Path->new($hash,
	{ 'key_does_not_exist'=>sub{ die 'callback_error_key' } 
	, 'index_does_not_exist'=>sub{ die 'callback_error_index' } 
	} );
eval {
	$b->get('/complex/home/');
};
ok ( $@ =~/callback_error_key/  ," check error_msg = $@");

eval {
	$b->get('/complex/level2[99]/level3_0');
};
ok ( $@ =~/callback_error_index/  ," check error_msg = $@");
my $obj = Test::MockObject->new({});

$obj->mock('method2' => sub {'method2 val'});
my $b2 = Data::Path->new($obj);
is($b->get('/method()'), $hash->{method}->(), "subroutine returned"); 
is($b2->get('/method2()', $obj), $obj->method2(), "method returned"); 

my $deep_method = { foo => $obj};

$b = Data::Path->new($deep_method);
is($b->get('/foo/method2()'), $obj->method2(), "deep method returned");

