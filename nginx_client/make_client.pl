#!/usr/bin/perl
use Data::Printer;
use JSON;
#/usr/share/nginx/html

foreach ( 1 .. 100 ) {
    my $container_id = &trim(`docker run -d nginx`);
    my $info = decode_json `docker inspect $container_id`;
    my $ipaddr = $info->[0]->{NetworkSettings}->{IPAddress};
    print "server  $ipaddr; \n";
    `docker exec $container_id bash -c 'echo "$ipaddr" > /usr/share/nginx/html/index.html'`;
}

sub trim {
    my @result = @_;
    foreach (@result) {
        s/^\s+//;    # 앞쪽공백 지우기
        s/\s+$//;    # 뒤쪽 공백 지우기
    }
    return wantarray ? @result : $result[0];
}
