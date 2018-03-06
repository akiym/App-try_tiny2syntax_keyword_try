requires 'PPI';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Base::Less';
};
